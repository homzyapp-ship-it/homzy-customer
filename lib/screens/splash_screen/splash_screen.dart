import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/bloc/device_sync_bloc/device_sync_bloc.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/screens/home_page/bloc/brands/brands_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import 'package:hyper_local/utils/widgets/custom_scaffold/custom_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../bloc/user_details_bloc/user_details_bloc.dart';
import '../../bloc/user_details_bloc/user_details_state.dart';
import '../../config/global.dart';
import '../../config/helper.dart';
import '../../config/settings_data_instance.dart';
import '../../config/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/location/location_service.dart';
import '../../model/user_location/user_location_model.dart';
import '../../utils/app_update/bloc/app_update_bloc.dart';
import '../../utils/app_update/bloc/app_update_event.dart';
import '../../utils/app_update/bloc/app_update_state.dart';
import '../../utils/app_update/model/update_config.dart';
import '../../utils/app_update/widgets/app_update_dialog.dart';
import '../home_page/bloc/banner/banner_bloc.dart';
import '../home_page/bloc/banner/banner_event.dart';
import '../home_page/bloc/category/category_bloc.dart';
import '../home_page/bloc/category/category_event.dart';
import '../home_page/bloc/sub_category/sub_category_bloc.dart';
import '../home_page/bloc/sub_category/sub_category_event.dart';
import '../../deep_link.dart';
import '../../config/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with WidgetsBindingObserver {
  bool _hasInitialized = false;
  bool _hasNavigated = false;
  bool _lastKnownConnectivity = false;
  bool _settingsRequested = false;
  int _settingsRetryCount = 0;
  bool _updateGateResolved = false;
  bool _updateDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Kick off version check — navigation is blocked until this resolves
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppUpdateBloc>().add(CheckAppUpdate());
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Update gate ───────────────────────────────────────────────────────────

  void _resolveGate() {
    if (_updateGateResolved) return;
    _updateGateResolved = true;
    _startSettingsIfReady();
  }

  /// Called when a soft-update dialog is dismissed via "Do it later".
  void _onSoftUpdateLater() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop();
    _updateDialogShowing = false;
    _resolveGate();
  }

  // ── AppUpdate dialog ──────────────────────────────────────────────────────
  void _showUpdateDialog(UpdateConfig config, {required bool isForced}) {
    if (_updateDialogShowing || !mounted) return;
    _updateDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppUpdateDialog(
        config: config,
        isForced: isForced,
        onLater: _onSoftUpdateLater,
      ),
    );
  }

  // ── Settings & navigation gate ────────────────────────────────────────────
  void _requestSettingsFetch() {
    if (!mounted || _settingsRequested) return;
    _settingsRequested = true;
    context.read<SettingsBloc>().add(FetchSettingsData(context: context));
  }

  /// Retries the settings fetch after a failure so the app never gets
  /// stranded on the splash screen because of a transient API error.
  Future<void> _retrySettingsFetch() async {
    if (!mounted) return;
    if (_settingsRetryCount >= 3) {
      log('Settings fetch failed after $_settingsRetryCount retries');
      return;
    }
    _settingsRetryCount++;
    _settingsRequested = false; // allow re-dispatch
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    log('Retrying settings fetch (attempt $_settingsRetryCount)');
    _requestSettingsFetch();
  }

  void _startSettingsIfReady() {
    if (!_updateGateResolved || !_lastKnownConnectivity) return;
    _requestSettingsFetch();
  }

  // ── Location helpers ──────────────────────────────────────────────────────

  Future<bool?> _showLocationAccessDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(dialogContext)!.locationAccessNeeded),
        content: Text(
          AppLocalizations.of(dialogContext)!.locationAccessDescription,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(dialogContext)!.later),
          ),
          TextButton(
            onPressed: () async {
              await Geolocator.openLocationSettings();
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            child: Text(AppLocalizations.of(dialogContext)!.openSettings),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            },
            child: Text(AppLocalizations.of(dialogContext)!.appPermissions),
          ),
        ],
      ),
    );
  }

  Future<void> _checkAndSetLocation() async {
    if (AppHelpers.isDemo) {
      // --- DEMO MODE PIPELINE ---
      // 1. Hive (stored location)
      if (LocationService.hasStoredLocation()) {
        log("[Demo Mode] Location initialized from Hive storage");
        return;
      }

      // 2. Demo Mode (hardcoded lat/long)
      final lat = AppHelpers.defaultLat;
      final lng = AppHelpers.defaultLng;
      if (lat.isNotEmpty && lng.isNotEmpty) {
        log("[Demo Mode] Location initialized from Demo hardcoded coordinates: $lat, $lng");
        await LocationService.storeLocationFromCoordinates(
          latitude: lat,
          longitude: lng,
        );
        return;
      }

      // 3. Default (backend web settings)
      String? backendLat, backendLng;
      final webSettings = SettingsData.instance.web;
      if (webSettings != null) {
        backendLat = webSettings.defaultLatitude;
        backendLng = webSettings.defaultLongitude;
      }
      if (backendLat != null && backendLng != null && backendLat.isNotEmpty && backendLng.isNotEmpty) {
        log("[Demo Mode] Location initialized from Backend Web Settings: $backendLat, $backendLng");
        await LocationService.storeLocationFromCoordinates(
          latitude: backendLat,
          longitude: backendLng,
        );
        return;
      }

      // 4. Current Location (GPS)
      log("[Demo Mode] Attempting device Current Location (GPS) at last");
      final userLoc = await _tryFetchDeviceLocation();
      if (userLoc != null) return;
    } else {
      // --- NORMAL MODE PIPELINE ---
      // 1. Current Location (GPS first)
      log("[Normal Mode] Attempting device Current Location (GPS) first");
      final userLoc = await _tryFetchDeviceLocation();
      if (userLoc != null) return;

      // 2. Hive (stored location)
      if (LocationService.hasStoredLocation()) {
        log("[Normal Mode] Location initialized from Hive storage");
        return;
      }

      // 3. Default (backend web settings)
      String? backendLat, backendLng;
      final webSettings = SettingsData.instance.web;
      if (webSettings != null) {
        backendLat = webSettings.defaultLatitude;
        backendLng = webSettings.defaultLongitude;
      }
      if (backendLat != null && backendLng != null && backendLat.isNotEmpty && backendLng.isNotEmpty) {
        log("[Normal Mode] Location initialized from Backend Web Settings: $backendLat, $backendLng");
        await LocationService.storeLocationFromCoordinates(
          latitude: backendLat,
          longitude: backendLng,
        );
        return;
      }
    }
  }

  Future<UserLocation?> _tryFetchDeviceLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      
      // 1. If already granted, fetch the location
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        return await LocationService.requestAndStoreLocationWithRetry();
      }
      
      // 2. If it hasn't been requested yet (denied), trigger the native OS dialog first
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
          return await LocationService.requestAndStoreLocationWithRetry();
        }
      }

      // 3. If they denied the native dialog or it is deniedForever, show the custom settings dialog
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        final bool? granted = await _showLocationAccessDialog();
        if (granted == true) {
          return await LocationService.requestAndStoreLocationWithRetry();
        }
      }
    } catch (e) {
      log("Error fetching device GPS location: $e");
    }
    return null;
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  Future<void> navigate() async {
    if (!mounted) return;
    _dispatchInitialDataFetches();
    _syncDeviceIfLoggedIn();
    if (_hasNavigated) return;
    _hasNavigated = true;
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || !_lastKnownConnectivity) {
      _hasNavigated = false;
      return;
    }

    if (Global.isFirstTime) {
      GoRouter.of(context).go(AppRoutes.introSlider);
      return;
    }

    if (AppLinksDeepLink.instance.hasPendingLink) {
      log('Deep link pending, skipping splash screen navigation');
      return;
    }

    GoRouter.of(context).go(AppRoutes.home);
  }

  void _handleConnectivityChanged(bool isConnected) {
    _lastKnownConnectivity = isConnected;

    if (!isConnected) {
      _hasNavigated = false;
      return;
    }

    if (!_hasInitialized) {
      _hasInitialized = true;
      if (_updateGateResolved) navigate();
      return;
    }

    if (!_hasNavigated && _updateGateResolved) navigate();
  }

  void _dispatchInitialDataFetches() {
    if (!mounted) return;
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    context.read<BannerBloc>().add(FetchBanner(categorySlug: ""));
    context.read<BrandsBloc>().add(const FetchBrands(categorySlug: ""));
    context.read<SubCategoryBloc>().add(FetchSubCategory(slug: "", isForAllCategory: true));
    context.read<UserProfileBloc>().add(FetchUserProfile());
  }

  void _syncDeviceIfLoggedIn() {
    if (!mounted) return;
    if (Global.userData != null && Global.userData!.token.isNotEmpty) {
      context.read<DeviceSyncBloc>().add(SyncDevice(
            deviceType: Platform.isAndroid ? 'android' : 'ios',
            previousToken: Global.userData?.fcm ?? '',
            roleType: 'customer',
          ));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<AppUpdateBloc, AppUpdateState>(
      listener: (context, state) {
        if (state is AppUpdateConfigLoaded) {
          if (!state.isUpdateAvailable) {
            _resolveGate();
          } else {
            final isForced = state.isForced;
            _showUpdateDialog(state.config, isForced: isForced);
          }
        }
        if (state is AppUpdateFailed) {
          _resolveGate();
        }
      },
      child: BlocListener<SettingsBloc, SettingsState>(
        listener: (context, state) async {
          if (state is MaintenanceModeEnabled) {
            GoRouter.of(context).go(
              AppRoutes.maintenancePage,
              extra: {'message': state.maintenanceModeMessage},
            );
            return;
          }
          if (state is SettingsFailure) {
            _retrySettingsFetch();
          }
          if (state is SettingsLoaded) {
            if (!mounted) return;
            if (SettingsData.instance.system!.webMaintenanceMode!) {
              GoRouter.of(context).go(AppRoutes.maintenancePage);
              return;
            }
            await _checkAndSetLocation();
            if (!mounted) return;
            await NotificationService().initFirebaseMessaging();
            if (!mounted) return;
            if (_lastKnownConnectivity) _handleConnectivityChanged(true);
          }
        },
        child: BlocListener<UserDataBloc, UserDataState>(
          listener: (context, state) {},
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return CustomScaffold(
      showViewCart: false,
      notifyConnectivityStatusOnInit: true,
      onConnectivityChanged: (isConnected, _) {
        if (!mounted) return;
        _lastKnownConnectivity = isConnected;
        if (!_updateGateResolved) {
          if (isConnected) _startSettingsIfReady();
          return;
        }
        if (context.read<SettingsBloc>().state is SettingsLoaded) {
          _handleConnectivityChanged(isConnected);
        } else if (isConnected) {
          _startSettingsIfReady();
        }
      },
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              image: DecorationImage(
                image: AssetImage('assets/images/doodle.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: CustomImageContainer(
                  imagePath: getAppLogoUrl(context),
                  height: 180,
                  width: 250,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
