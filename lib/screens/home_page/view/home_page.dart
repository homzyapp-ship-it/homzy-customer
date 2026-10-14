import 'dart:developer';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:hyper_local/screens/auth/bloc/apply_referral/apply_referral_bloc.dart';
import 'package:hyper_local/screens/auth/view/referral_prompt_sheet.dart';
import 'package:hyper_local/services/referral_attribution_service.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:hyper_local/bloc/settings_bloc/settings_bloc.dart';
import 'package:hyper_local/bloc/user_cart_bloc/user_cart_bloc.dart';
import 'package:hyper_local/config/settings_data_instance.dart';
import 'package:hyper_local/config/theme.dart';
import 'package:hyper_local/screens/address_list_page/bloc/get_address_list_bloc/get_address_list_bloc.dart';
import 'package:hyper_local/screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_bloc.dart';
import 'package:hyper_local/screens/home_page/bloc/category/category_event.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_bloc.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_event.dart';
import 'package:hyper_local/screens/home_page/home_layout/bloc/home_layout_state.dart';
import 'package:hyper_local/screens/near_by_stores/bloc/near_by_store/near_by_store_bloc.dart';
import 'package:hyper_local/screens/user_profile/bloc/user_profile_bloc/user_profile_bloc.dart';
import 'package:hyper_local/utils/widgets/custom_image_container.dart';
import '../../../bloc/user_cart_bloc/user_cart_event.dart';
import '../../../config/global.dart';
import '../../../config/helper.dart';
import '../../../config/notification_service.dart';
import '../../../deep_link.dart';
import '../../../utils/widgets/custom_circular_progress_indicator.dart';
import '../../../utils/widgets/custom_scaffold/custom_scaffold.dart';

import '../model/category_model.dart';
import '../widgets/animated_text_field.dart';
import '../bloc/category/category_state.dart';
import '../widgets/home_helpers.dart';
import '../widgets/referral_banner.dart';
import '../../../utils/widgets/empty_states_page.dart';
import '../../notification_page/bloc/notification_bloc.dart';
import '../widgets/home_tab_item.dart';
import '../widgets/sections/home_app_bar_section.dart';
import '../widgets/sections/home_top_address_section.dart';
import '../widgets/home_tab_content.dart';
import '../widgets/home_notification_action.dart';
import '../../../utils/widgets/custom_refresh_indicator.dart';
import 'package:hyper_local/l10n/app_localizations.dart';
import '../bloc/feature_section_product/feature_section_product_bloc.dart';
import '../bloc/feature_section_product/feature_section_product_event.dart';
import '../bloc/feature_section_product/feature_section_product_state.dart';
import '../widgets/product_feature_section_widget.dart';
import '../widgets/sections/home_tab_content_section.dart';
import '../widgets/banner_slider.dart';
import '../widgets/home_featured_placeholder.dart';
import '../bloc/sub_category/sub_category_bloc.dart';
import '../bloc/sub_category/sub_category_event.dart';
import '../bloc/brands/brands_bloc.dart';
import '../bloc/banner/banner_bloc.dart';
import '../bloc/banner/banner_event.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final AppLinksDeepLink _appLinksDeepLink = AppLinksDeepLink.instance;
  late TabController _tabController;
  final Map<int, bool> _isLoadingMoreForTab = {};
  final ScrollController nestedScrollController = ScrollController();
  final GlobalKey<NestedScrollViewState> _nestedScrollViewKey = GlobalKey<NestedScrollViewState>();
  late String backgroundImagePath = '';
  String? backgroundColor;
  bool _isImageEmpty = false;
  Color? textColor;
  List<CategoryData> _categories = [];
  bool _isTabControllerInitialized = false;
  bool _isFlexibleSpaceHidden = false;
  bool _isRecreatingTabController = false;
  Color? _originalTextColor;
  Color? _collapsedTextColor;
  String? _lastLocationIdentifier;
  int localCategoryLength = 0;
  String _tabBarViewKey = 'initial';
  int _previousCategoryLength = 0;
  bool _isRedirecting = false;
  double _appBarOpacity = 1.0;
  bool isRetry = false;
  List<String>? searchHintList = [];
  bool _showReferralBanner = false;
  bool _showScrollToTop = false;
  bool _isScrollingToTop = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // _showReferralBanner = true; // SHIVAM

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        NotificationService.handleNotificationNavigation(message.data);
      }
    });
    _appLinksDeepLink.initDeepLinks(context);

    final cachedSettings = SettingsData.instance.homeGeneralSettings;
    if (cachedSettings != null && isValidHomeGeneralSettings(cachedSettings)) {
      final bgType = cachedSettings.backgroundType.toLowerCase();
      if (bgType == 'animation') {
        backgroundImagePath = cachedSettings.backgroundAnimation ?? '';
      } else if (bgType == 'image') {
        backgroundImagePath = cachedSettings.backgroundImage.isNotEmpty ? cachedSettings.backgroundImage : '';
      } else {
        backgroundImagePath = '';
      }
      backgroundColor = cachedSettings.backgroundColor.isNotEmpty ? cachedSettings.backgroundColor : null;
    }
    _isImageEmpty = backgroundImagePath.isEmpty;
    _tabController = TabController(length: 1, vsync: this);
    _tabController.addListener(_onTabChanged);
    _isTabControllerInitialized = true;
    nestedScrollController.addListener(_scrollListener);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (AppLinksDeepLink.instance.hasPendingLink) {
          log('HomePage: Deep link pending, skipping initial API calls');
          return;
        }
        _applyHomeGeneralSettingsToAppBar();
        context.read<UserProfileBloc>().add(FetchUserProfile());

        // Check if profile is already loaded (from splash screen) to show banner immediately
        final userProfileState = context.read<UserProfileBloc>().state;
        if (userProfileState is UserProfileLoaded) {
          _maybeShowReferralPrompt(userProfileState);
        }

        final box = Hive.box<dynamic>('userLocationBox');
        final storedLocation = box.get('user_location');
        if (storedLocation != null) {
          // Location exists, refresh will handle in build
        } else {
          context.read<CategoryBloc>().add(FetchCategory(context: context));
          apiCalls('');
        }
      }
    });
    searchHintList = removeUnderscoresFromStringList(SettingsData.instance.homeGeneralSettings?.searchLabels ?? []);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initialiseColors();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _tabController.index == 0) {
        _applyHomeGeneralSettingsToAppBar();
      }
      if (!_isImageEmpty && backgroundImagePath.isNotEmpty && !backgroundImagePath.toLowerCase().contains('.json')) {
        precacheImage(NetworkImage(backgroundImagePath), context);
      }
    });
  }

  void initialiseColors() {
    _originalTextColor =
        Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor;
    _collapsedTextColor =
        Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor;
    textColor = _originalTextColor;
  }

  void updateAppBarBackground({String? image, String? bgColor, Color? fontColor, List<String>? searchHintTextList}) {
    setState(() {
      backgroundImagePath = image ?? '';
      backgroundColor = bgColor;
      _isImageEmpty = backgroundImagePath.isEmpty;
      _originalTextColor = fontColor ??
          (Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor);
      // Use `this.` to assign to the instance field — the parameter
      // shadows the field and `searchHintTextList = searchHintTextList`
      // would otherwise be a no-op.
      searchHintList = searchHintTextList;
      if (_isFlexibleSpaceHidden) {
        textColor = _collapsedTextColor;
      } else {
        textColor = _originalTextColor;
      }
    });
  }

  void _onTabChanged() {
    if (!_canUseTabController || _isRedirecting) return;

    final int index = _tabController.index;
    final int totalTabs = _categories.length + 1;

    if (index >= totalTabs) {
      _ensureValidTabIndex();
      return;
    }

    if (!Global.wantNewUI) {
      context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());
    }

    if (index == 0) {
      apiCalls('');
      _applyHomeGeneralSettingsToAppBar();
    } else if (index > 0 && index - 1 < _categories.length) {
      final category = _categories[index - 1];
      apiCalls(category.slug ?? '');
      _applyCategoryAppBar(category);
    }
    scrollToTop();
  }

  void _ensureValidTabIndex() {
    log('Ensure Valid Tab Index ${(!mounted || !_canUseTabController || _isRedirecting)}');
    if (!mounted || !_canUseTabController || _isRedirecting) return;

    final int totalTabs = _categories.length + 1;
    final int currentIndex = _tabController.index;
    if (currentIndex >= totalTabs || currentIndex < 0) {
      _isRedirecting = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_canUseTabController) {
          _isRedirecting = false;
          return;
        }

        // 1. First, switch to "All" tab
        _tabController.animateTo(0);

        // 2. Apply "All" tab settings IMMEDIATELY
        _applyHomeGeneralSettingsToAppBar();

        if (!Global.wantNewUI) {
          // Clear feature section products to prevent showing old data
          context.read<FeatureSectionProductBloc>().add(ClearFeatureSectionProducts());
        }

        // 3. Make API calls with empty slug (for "All" tab)
        apiCalls('');

        // 5. Force TabBarView rebuild to reset scroll
        setState(() {
          _tabBarViewKey = 'reset_${DateTime.now().millisecondsSinceEpoch}';
        });

        // 6. Scroll NestedScrollView to top
        if (nestedScrollController.hasClients) {
          nestedScrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }

        // Reset flag after a short delay
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _isRedirecting = false;
          }
        });
      });
    }
  }

  bool get _canUseTabController => _isTabControllerInitialized && !_isRecreatingTabController && mounted;

  void _initializeTabController(int categoriesLength) {
    if (_tabController.length != categoriesLength + 1 && !_isRecreatingTabController) {
      _isRecreatingTabController = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          _isRecreatingTabController = false;
          return;
        }

        try {
          // Existing: Remove listener and dispose
          _tabController.removeListener(_onTabChanged);
          _tabController.dispose();

          _tabController = TabController(
            length: categoriesLength + 1,
            vsync: this,
          );

          _tabController.addListener(_onTabChanged);
          _isTabControllerInitialized = true;
          _isRecreatingTabController = false;

          if (mounted) {
            setState(() {});
          }
        } catch (e) {
          _isRecreatingTabController = false;
          log('Error recreating TabController: $e');
        }
      });
    }
  }

  void apiCalls(String slug) async {
    final updatedSlug = (_canUseTabController && _tabController.index != 0) ? slug : '';

    if (Global.wantNewUI) {
      // Consolidated Home API call via HomeLayoutBloc
      context.read<HomeLayoutBloc>().add(FetchHomeLayout(categorySlug: updatedSlug));
    } else {
      final isForAllCategory = (_canUseTabController && _tabController.index != 0) ? false : true;
      context.read<FeatureSectionProductBloc>().add(FetchFeatureSectionProducts(slug: updatedSlug));
      context.read<SubCategoryBloc>().add(FetchSubCategory(slug: updatedSlug, isForAllCategory: isForAllCategory));
      context.read<BrandsBloc>().add(FetchBrands(categorySlug: updatedSlug));
      context.read<BannerBloc>().add(FetchBanner(categorySlug: updatedSlug));
    }

    // Other support calls
    context.read<GetUserCartBloc>().add(FetchUserCart());
    context.read<GetAddressListBloc>().add(FetchUserAddressList());
    context.read<NotificationBloc>().add(FetchNotifications());

    await Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        context.read<SettingsBloc>().add(FetchSettingsData(context: context));
      }
    });
  }

  void _refreshDataForCurrentTab() {
    if (_tabController.index == 0) {
      apiCalls('');
    } else if (_categories.isNotEmpty && (_tabController.index - 1) < _categories.length) {
      final selectedCategory = _categories[_tabController.index - 1];
      apiCalls(selectedCategory.slug ?? '');
    } else {
      apiCalls('');
    }
  }

  Future<void> _maybeShowReferralPrompt(UserProfileLoaded state) async {
    try {
      if (SettingsData.instance.system?.referEarnStatus != true) return;

      final referralAttribution = GetIt.instance<ReferralAttributionService>();

      // Check if the user just registered
      final isNewUser = await referralAttribution.getJustRegistered();
      if (!isNewUser) return;

      // Check if referral prompt was already shown
      final alreadyShown = await referralAttribution.getPromptShown();
      if (alreadyShown) return;

      // Check if friends code is already applied
      final friendsCode = state.userData.data?.friendsCode;
      final referralCodeApplied = friendsCode != null && friendsCode.isNotEmpty;
      if (referralCodeApplied) {
        // Clear the just registered flag since they already have a code applied
        await referralAttribution.setJustRegistered(false);
        return;
      }

      // Set shown flag and clear just registered flag so it is shown only once
      await referralAttribution.setPromptShown(true);
      await referralAttribution.setJustRegistered(false);

      if (!mounted) return;

      // Wait a brief delay for Home Screen to be fully loaded
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        setState(() {
          _showReferralBanner = true;
        });
      });
    } catch (e) {}
  }

  void _onYesReferral() {
    setState(() {
      _showReferralBanner = false;
    });
    showModalBottomSheet(
      context: context,
      isDismissible: true,
      enableDrag: true,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20.r),
        ),
      ),
      builder: (sheetContext) {
        return BlocProvider(
          create: (_) => ApplyReferralBloc(),
          child: const ReferralPromptSheet(),
        );
      },
    );
  }

  void _onNoReferral() {
    setState(() {
      _showReferralBanner = false;
    });
  }

  void _refreshApiOnLocationChange() {
    context.read<CategoryBloc>().add(FetchCategory(context: context));
    if (!AppHelpers.systemVendorTypeIsSingle) {
      context.read<NearByStoreBloc>().add(const FetchNearByStores(perPage: 15, searchQuery: ''));
    }
  }

  void _scrollListener() {
    double expandedHeight = 100.0.h;
    const double toolbarHeight = kToolbarHeight;
    final double flexibleSpaceHeight = expandedHeight - toolbarHeight;
    final double currentOffset = nestedScrollController.offset;
    final bool isHidden = currentOffset >= (flexibleSpaceHeight - 10);
    _appBarOpacity = (1 - (currentOffset / expandedHeight)).clamp(0.0, 1.0);

    if (_isFlexibleSpaceHidden != isHidden) {
      setState(() {
        _isFlexibleSpaceHidden = isHidden;
        if (_isFlexibleSpaceHidden) {
          textColor = _collapsedTextColor ??
              (Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor);
        } else {
          textColor = _originalTextColor ??
              (Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor);
        }
      });
    }
  }

  @override
  void dispose() {
    nestedScrollController.removeListener(_scrollListener);
    nestedScrollController.dispose();
    if (_isTabControllerInitialized) {
      _tabController.removeListener(_onTabChanged);
      _tabController.dispose();
    }
    super.dispose();
  }

  Widget _buildFlexibleSpaceBackground() {
    Widget child;
    if (!_isImageEmpty && backgroundImagePath.isNotEmpty) {
      child = CustomImageContainer(
        key: ValueKey('image_$backgroundImagePath'),
        imagePath: backgroundImagePath,
        width: double.infinity,
        height: double.infinity,
        fit: BoxFit.fill,
        placeholder: _buildGradientBackground(),
      );
    } else {
      child = _buildGradientBackground();
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: child,
    );
  }

  Widget _buildGradientBackground() {
    Color primaryColor = AppTheme.primaryColor;
    if (backgroundColor != null) {
      Color? categoryColor = hexStringToColor(backgroundColor);
      if (categoryColor != null) {
        primaryColor = categoryColor;
      }
    }
    return Container(
      key: ValueKey('gradient_${backgroundColor ?? "default"}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor,
            primaryColor.withValues(alpha: 0.8),
          ],
        ),
      ),
    );
  }

  void _applyHomeGeneralSettingsToAppBar() {
    final settings = SettingsData.instance.homeGeneralSettings;
    final bgType = (settings?.backgroundType ?? 'color').toLowerCase();
    // Always recompute home search labels from the latest settings so the
    // hint refreshes when switching back from a category tab to "All".
    final List<String> homeSearchLabels = removeUnderscoresFromStringList(
      settings?.searchLabels ?? [],
    );

    if (settings == null || !isValidHomeGeneralSettings(settings)) {
      _collapsedTextColor =
          Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor;
      updateAppBarBackground(
        image: '',
        bgColor: null,
        fontColor: Theme.of(context).brightness == Brightness.light ? AppTheme.lightFontColor : AppTheme.darkFontColor,
        searchHintTextList: homeSearchLabels,
      );
      return;
    }

    final String image = bgType == 'animation'
        ? (settings.backgroundAnimation ?? '')
        : (settings.backgroundImage.isNotEmpty ? settings.backgroundImage : '');
    final String? bgColor = settings.backgroundColor.isNotEmpty ? settings.backgroundColor : null;
    final Color? fontColor = settings.fontColor.isNotEmpty ? hexStringToColor(settings.fontColor) : null;

    updateAppBarBackground(
      image: bgType == 'animation' || bgType == 'image' ? image : null,
      bgColor: bgColor,
      fontColor: fontColor,
      searchHintTextList: homeSearchLabels,
    );
  }

  void _handleLocationChange(String? locationIdentifier) {
    if (_lastLocationIdentifier == locationIdentifier) return;
    _lastLocationIdentifier = locationIdentifier;
    _refreshApiOnLocationChange();
    _refreshDataForCurrentTab();
  }

  void _applyCategoryAppBar(CategoryData category) {
    final bgType = (category.backgroundType ?? 'color').toLowerCase();
    final String? image = bgType == 'animation'
        ? category.backgroundAnimation
        : (bgType == 'image' ? (category.backgroundImage ?? category.banner) : null);
    updateAppBarBackground(
      image: image,
      bgColor: category.backgroundColor,
      fontColor: hexStringToColor(category.fontColor),
      // Mirror the home tab's transformation so category labels render
      // without underscores.
      searchHintTextList: removeUnderscoresFromStringList(category.searchLabels ?? []),
    );
  }

  Widget _buildHomeTabContent({required String categorySlug}) {
    if (Global.wantNewUI) {
      return HomeTabContent(
        categorySlug: categorySlug,
        onRefresh: () async {
          apiCalls(categorySlug);
          if (categorySlug.isEmpty) {
            _applyHomeGeneralSettingsToAppBar();
          } else {
            final category = _categories.firstWhere(
              (item) => item.slug == categorySlug,
              orElse: () => CategoryData(),
            );
            _applyCategoryAppBar(category);
          }
          context.read<CategoryBloc>().add(FetchCategory(context: context));
        },
        onRetry: () {
          apiCalls(categorySlug);
        },
      );
    } else {
      return CustomRefreshIndicator(
        onRefresh: () async {
          apiCalls(categorySlug);
          if (categorySlug.isEmpty) {
            _applyHomeGeneralSettingsToAppBar();
          } else {
            final category = _categories.firstWhere(
              (item) => item.slug == categorySlug,
              orElse: () => CategoryData(),
            );
            _applyCategoryAppBar(category);
          }
          context.read<CategoryBloc>().add(FetchCategory(context: context));
        },
        child: HomeTabContentSection(
          brandsSectionTitle: AppLocalizations.of(context)!.topBrands,
          categorySlug: categorySlug,
          middleBanner: middleBannersWidget(),
          loadingPlaceholder: const HomeFeaturedPlaceholder(),
          buildFeatureSection: buildFeatureSection,
          onRetry: () => showHomeLocationBottomSheet(context),
        ),
      );
    }
  }

  Widget _buildNotificationAction() {
    return HomeNotificationAction(textColor: textColor);
  }

  Widget _buildHomeTabBar(List<Widget> tabBarTabs) {
    if (!_canUseTabController || _tabController.length != tabBarTabs.length) {
      return const SizedBox(height: 50);
    }
    return TabBar(
      dividerColor: Colors.transparent,
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      enableFeedback: true,
      labelColor: textColor,
      automaticIndicatorColorAdjustment: true,
      unselectedLabelColor: textColor,
      labelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
      ),
      unselectedLabelStyle: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
      ),
      indicatorColor: textColor,
      indicatorWeight: 3,
      indicatorSize: TabBarIndicatorSize.label,
      padding: const EdgeInsets.symmetric(horizontal: 0),
      tabs: tabBarTabs,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (Global.homeNeedsReferralCheck) {
      Global.homeNeedsReferralCheck = false;
      final userProfileState = context.read<UserProfileBloc>().state;
      if (userProfileState is UserProfileLoaded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _maybeShowReferralPrompt(userProfileState);
        });
      }
    }

    return MultiBlocListener(
      listeners: [
        BlocListener<GetUserCartBloc, GetUserCartState>(
          listener: (context, state) {},
        ),
        BlocListener<SettingsBloc, SettingsState>(
          listener: (context, state) {
            if (state is SettingsLoaded && mounted) {
              if (!_canUseTabController || _tabController.index == 0) {
                _applyHomeGeneralSettingsToAppBar();
              }
            }
          },
        ),
        BlocListener<UserProfileBloc, UserProfileState>(
          listener: (context, state) {
            if (state is UserProfileLoaded && mounted) {
              _maybeShowReferralPrompt(state);
            }
          },
        ),
      ],
      child: CustomScaffold(
        showViewCart: !_showReferralBanner,
        onConnectivityRestored: (context) async {
          context.read<CartBloc>().add(SyncLocalCart(context: context));
          _refreshDataForCurrentTab();
        },
        body: Stack(
          children: [
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (BuildContext context, CategoryState state) {
                final homeGeneralSettings = SettingsData.instance.homeGeneralSettings;
                List<Widget> tabBarTabs = [
                  if (homeGeneralSettings != null && isValidHomeGeneralSettings(homeGeneralSettings))
                    HomeAllTabDynamic(
                      controller: _tabController,
                      settings: homeGeneralSettings,
                    )
                  else
                    const HomeAllTabStatic(),
                ];
                List<Widget> tabBarViewChildren = [
                  _buildHomeTabContent(categorySlug: ''),
                ];

                if (state is CategoryLoaded) {
                  // Pre-cache banner images so the first switch to any category
                  // tab is instant rather than waiting for the network.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    for (final category in state.categoryData) {
                      final banner = category.banner ?? '';
                      if (banner.startsWith('http')) {
                        precacheImage(NetworkImage(banner), context);
                      }
                    }
                  });

                  if (isRetry) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      Future.delayed(const Duration(seconds: 1), () {
                        if (mounted) {
                          setState(() {
                            isRetry = false;
                          });
                        }
                      });
                    });
                  }
                  final newCategories = state.categoryData;
                  final int totalTabs = newCategories.length + 1;
                  final bool categoriesChanged = _previousCategoryLength != newCategories.length;
                  final int oldLength = _previousCategoryLength;
                  _previousCategoryLength = newCategories.length;

                  _categories = newCategories;

                  if (_tabController.length != totalTabs) {
                    _initializeTabController(newCategories.length);

                    if (oldLength == 0) {
                      apiCalls('');
                    }
                  }

                  // Critical: Handle invalid tab index when category is removed
                  if (_tabController.index >= totalTabs) {
                    _ensureValidTabIndex();
                  } else if (categoriesChanged && _tabController.index > 0 && !_isRedirecting) {
                    // Verify current category still exists by slug
                    final currentIndex = _tabController.index - 1;
                    if (currentIndex >= 0 && currentIndex < oldLength - (oldLength - newCategories.length)) {
                      // Check if we need to redirect
                      if (currentIndex >= newCategories.length) {
                        _ensureValidTabIndex();
                      } else {
                        Future.delayed(const Duration(milliseconds: 600), () {
                          apiCalls('');
                          _applyHomeGeneralSettingsToAppBar();
                        });
                      }
                    }
                  }

                  tabBarTabs.addAll(_categories.asMap().entries.map((entry) {
                    return HomeCategoryTab(
                      controller: _tabController,
                      category: entry.value,
                      index: entry.key,
                    );
                  }).toList());

                  // Build TabBarView children for categories
                  tabBarViewChildren.addAll(_categories.asMap().entries.map((entry) {
                    final category = entry.value;
                    return _buildHomeTabContent(
                      categorySlug: category.slug ?? '',
                    );
                  }).toList());
                }

                if (state is CategoryFailed && isRetry) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Future.delayed(const Duration(seconds: 1), () {
                      if (mounted) {
                        setState(() {
                          isRetry = false;
                        });
                      }
                    });
                  });
                }

                return AbsorbPointer(
                  absorbing: _isScrollingToTop,
                  child: NestedScrollView(
                    key: _nestedScrollViewKey,
                    controller: nestedScrollController,
                    physics: _canUseTabController
                        ? const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics())
                        : const NeverScrollableScrollPhysics(),
                    headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
                      return [
                        HomeAppBarSection(
                          canUseTabController: _canUseTabController,
                          appBarOpacity: _appBarOpacity,
                          textColor: textColor,
                          title: HomeTopAddressSection(
                            textColor: textColor,
                            onLocationChanged: _handleLocationChange,
                          ),
                          flexibleSpaceBackground: _buildFlexibleSpaceBackground(),
                          searchField: CustomAnimatedTextField(
                            key: ValueKey(
                              searchHintList?.join('|') ?? '',
                            ),
                            searchHintTextList: searchHintList,
                          ),
                          tabBar: _buildHomeTabBar(tabBarTabs),
                          notificationsAction: Global.userData != null ? _buildNotificationAction() : null,
                          isDarkMode: isDarkMode(context),
                          darkBackgroundColor: AppTheme.darkProductCardColor,
                          appBarColor: hexStringToColor(backgroundColor),
                        ),
                        if (isRetry) const SliverToBoxAdapter()
                      ];
                    },
                    body: _canUseTabController
                        ? Stack(
                            children: [
                              NotificationListener<ScrollNotification>(
                                onNotification: (ScrollNotification notification) {
                                  if (notification is ScrollUpdateNotification) {
                                    final metrics = notification.metrics;
                                    // Ignore horizontal strips (e.g. featured-section product rows) so reaching the last card doesn't trigger pagination.
                                    if (metrics.axis == Axis.vertical &&
                                        metrics.pixels >= metrics.maxScrollExtent * 0.85) {
                                      _loadMoreForCurrentTab(_tabController.index);
                                    }
                                    if (metrics.axis == Axis.vertical) {
                                      final delta = notification.scrollDelta ?? 0.0;
                                      bool shouldShow = _showScrollToTop;

                                      if (metrics.pixels <= 300) {
                                        shouldShow = false;
                                      } else if (delta < 0) {
                                        // Scrolling up (revealing top) -> show
                                        shouldShow = true;
                                      } else if (delta > 0) {
                                        // Scrolling down (scrolling away from top) -> hide
                                        shouldShow = false;
                                      }

                                      if (_showScrollToTop != shouldShow && !_isScrollingToTop) {
                                        WidgetsBinding.instance.addPostFrameCallback((_) {
                                          if (mounted) {
                                            setState(() {
                                              _showScrollToTop = shouldShow;
                                            });
                                          }
                                        });
                                      }
                                    }
                                  }
                                  return false;
                                },
                                child: (_canUseTabController && _tabController.length == tabBarViewChildren.length)
                                    ? TabBarView(
                                        key: ValueKey(_tabBarViewKey),
                                        physics: const NeverScrollableScrollPhysics(),
                                        controller: _tabController,
                                        children: tabBarViewChildren,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 400),
                                top: _showScrollToTop
                                    ? (isTablet(context) ? 100 : 165).h
                                    : (isTablet(context) ? 90 : 150).h,
                                left: 0,
                                right: 0,
                                child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 300),
                                  opacity: _showScrollToTop ? 1.0 : 0.0,
                                  child: Align(
                                    alignment: Alignment.topCenter,
                                    child: GestureDetector(
                                      onTap: scrollToTop,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 6.5.h),
                                        decoration: BoxDecoration(
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDarkMode(context)
                                                  ? Colors.black.withValues(alpha: 0.45)
                                                  : Colors.black.withValues(alpha: 0.3),
                                              blurRadius: isDarkMode(context) ? 10 : 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                          borderRadius: BorderRadius.circular(20.r),
                                          color: isDarkMode(context) ? Colors.white : Colors.black,
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              AppLocalizations.of(context)!.backToTop,
                                              style: TextStyle(
                                                  color: isDarkMode(context) ? Colors.black : Colors.white,
                                                  fontSize: isTablet(context) ? 20 : 13.sp,
                                                  fontWeight: FontWeight.w600),
                                            ),
                                            SizedBox(width: 4.w),
                                            HugeIcon(
                                              icon: HugeIcons.strokeRoundedCircleArrowUp02,
                                              size: isTablet(context) ? 25 : 16.sp,
                                              color: isDarkMode(context) ? Colors.black : Colors.white,
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : !isRetry
                            ? NoDeliveryLocationPage(
                                onRetry: () => showHomeLocationBottomSheet(
                                  context,
                                ),
                              )
                            : const SizedBox.shrink(),
                  ),
                );
              },
            ),
            if (isRetry)
              const Positioned.fill(
                top: 120,
                child: Center(
                  child: CustomCircularProgressIndicator(),
                ),
              ),
            if (_showReferralBanner)
              Positioned(
                bottom: 10,
                left: 10,
                right: 10,
                child: ReferralBanner(
                  onYes: _onYesReferral,
                  onNo: _onNoReferral,
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _loadMoreForCurrentTab(int tabIndex) {
    if (Global.wantNewUI) {
      final state = context.read<HomeLayoutBloc>().state;
      if (state is HomeLayoutLoaded && !state.hasReachedMax && !state.isLoadingMore) {
        context.read<HomeLayoutBloc>().add(const FetchMoreHomeLayout());
      }
    } else {
      if (_isLoadingMoreForTab[tabIndex] == true) return;

      final featureSectionState = context.read<FeatureSectionProductBloc>().state;
      if (featureSectionState is FeatureSectionProductLoaded && !featureSectionState.hasReachedMax) {
        final slug = tabIndex == 0
            ? ''
            : (tabIndex - 1 < _categories.length)
                ? _categories[tabIndex - 1].slug ?? ''
                : '';

        _isLoadingMoreForTab[tabIndex] = true;
        context.read<FeatureSectionProductBloc>().add(FetchMoreFeatureSectionProducts(slug: slug));

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            _isLoadingMoreForTab[tabIndex] = false;
          }
        });
      }
    }
  }

  void scrollToTop() {
    if (_isScrollingToTop) return;

    final inner = _nestedScrollViewKey.currentState?.innerController;

    setState(() {
      _isScrollingToTop = true;
      _showScrollToTop = false;
    });

    final futures = <Future<void>>[];

    if (inner?.hasClients ?? false) {
      futures.add(
        inner!.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    if (nestedScrollController.hasClients) {
      futures.add(
        nestedScrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        ),
      );
    }

    if (futures.isEmpty) {
      setState(() => _isScrollingToTop = false);
      return;
    }

    Future.wait(futures).whenComplete(() {
      if (mounted) {
        setState(() {
          _isScrollingToTop = false;
        });
      }
    });
  }
}
