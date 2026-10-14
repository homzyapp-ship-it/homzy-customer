import 'dart:async';
import 'dart:developer';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'config/global_keys.dart';

class AppLinksDeepLink {
  AppLinksDeepLink._privateConstructor();

  static final AppLinksDeepLink _instance = AppLinksDeepLink._privateConstructor();
  static AppLinksDeepLink get instance => _instance;

  late final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isInitialized = false;
  Uri? _lastProcessedUri;
  bool _hasPendingLink = false;

  bool get hasPendingLink => _hasPendingLink;

  void clearPendingLink() {
    _hasPendingLink = false;
  }

  Future<void> initDeepLinks(BuildContext context) async {
    if (_isInitialized) {
      log('Deep links already initialized, skipping');
      return;
    }
    _isInitialized = true;

    try {
      log('NAVIGATOR CONTEXT INITIALIZED');

      // Handle initial link if the app was opened via a link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        log('Initial deep link: $initialUri');
        if (!_isFirebaseAuthCallback(initialUri)) {
          _hasPendingLink = true;
          final navContext = GlobalKeys.navigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            await _handleDeepLink(initialUri, navContext);
          } else if (context.mounted) {
            await _handleDeepLink(initialUri, context);
          } else {
            _hasPendingLink = false;
          }
        } else {
          log('Ignoring initial Firebase Auth callback deep link: $initialUri');
          _hasPendingLink = false;
        }
      }

      // Listen for subsequent links while the app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) async {
          log('Received deep link: $uri');
          if (uri != null) {
            if (_isFirebaseAuthCallback(uri)) {
              log('Ignoring Firebase Auth callback deep link: ${uri.scheme}://${uri.host}${uri.path}');
              _hasPendingLink = false;
              return;
            }
            _hasPendingLink = true;
            final navContext = GlobalKeys.navigatorKey.currentContext;
            if (navContext != null && navContext.mounted) {
              await _handleDeepLink(uri, navContext);
            } else if (context.mounted) {
              await _handleDeepLink(uri, context);
            } else {
              _hasPendingLink = false;
            }
          }
        },
        onError: (err) {
          log('Deep link error: $err');
        },
      );
    } catch (e, stack) {
      log('Deep link initialization error: $e');
      log('Stack trace: $stack');
    }
  }

  Future<void> _handleDeepLink(Uri uri, BuildContext context) async {
    if (_isFirebaseAuthCallback(uri)) {
      log('Ignoring Firebase Auth callback deep link inside handler: ${uri.scheme}://${uri.host}${uri.path}');
      _hasPendingLink = false;
      return;
    }

    if (_lastProcessedUri == uri) {
      log('URI $uri was just processed, skipping');
      _hasPendingLink = false;
      return;
    }
    _lastProcessedUri = uri;
    _hasPendingLink = true;

    // Clear the last processed URI after a short delay to allow re-processing the same link later
    Future.delayed(const Duration(seconds: 2), () {
      if (_lastProcessedUri == uri) {
        _lastProcessedUri = null;
      }
    });

    final navigatorContext = GlobalKeys.navigatorKey.currentContext ?? context;
    if (!navigatorContext.mounted) {
      log('Navigator context is not mounted, skipping deep link handling');
      _hasPendingLink = false;
      return;
    }

    debugPrint('Processing deep link URI: ${uri.toString()}');

    try {
      String? productSlug = _extractProductSlug(uri);

      if (productSlug != null && productSlug.isNotEmpty) {
        log('Redirecting to product detail page with slug: $productSlug');

        // Ensure we're on the main thread and context is still valid
        await WidgetsBinding.instance.endOfFrame;
        if (!navigatorContext.mounted) {
          _hasPendingLink = false;
          return;
        }

        final router = GoRouter.of(navigatorContext);

        // Ensure Home is the base route
        router.go(AppRoutes.home);

        // Navigate to product detail page on top of Home
        router.push(
          AppRoutes.productDetailPage,
          extra: {'productSlug': productSlug},
        );
        _hasPendingLink = false; // Successfully handled
      } else {
        log('No product slug found in deep link: $uri');
        _hasPendingLink = false;
      }
    } catch (e, stack) {
      _hasPendingLink = false;
      debugPrint('Navigation error: $e');
      debugPrint('Stack trace: $stack');
    }
  }

  /// Returns true when the URI is a Firebase Auth callback that the Firebase.
  bool _isFirebaseAuthCallback(Uri uri) {
    // Google's reverse-client-ID scheme is used for OAuth + Firebase callbacks.
    if (uri.scheme.startsWith('com.googleusercontent.apps.')) return true;

    // Custom `<bundle>://firebaseauth/...` or `<scheme>://firebase-auth/...`
    final host = uri.host.toLowerCase();
    if (host == 'firebaseauth' || host == 'firebase-auth') return true;

    // Firebase Auth callback query params (any of these means Firebase owns it).
    if (uri.queryParameters.containsKey('deep_link_id')) return true;
    if (uri.queryParameters.containsKey('authType')) return true;

    // Email-link sign-in and reCAPTCHA callbacks on the Firebase hosting domain.
    if (uri.path.contains('/__/auth/')) return true;

    return false;
  }

  String? _extractProductSlug(Uri uri) {
    if (uri.pathSegments.contains('product') || uri.pathSegments.contains('p')) {
      final index =
          uri.pathSegments.contains('product') ? uri.pathSegments.indexOf('product') : uri.pathSegments.indexOf('p');

      if (index != -1 && index + 1 < uri.pathSegments.length) {
        final slug = uri.pathSegments[index + 1];
        if (slug.isNotEmpty) return slug;
      }
    }

    // 2. Check query parameters (e.g., ?slug=my-slug or ?product_slug=my-slug)
    if (uri.queryParameters.containsKey('slug')) {
      return uri.queryParameters['slug'];
    }
    if (uri.queryParameters.containsKey('product_slug')) {
      return uri.queryParameters['product_slug'];
    }

    // 3.
    const keywords = {'product', 'p', 'home', 'shop', 'categories', 'cart'};
    if (uri.pathSegments.isNotEmpty) {
      final lastSegment = uri.pathSegments.last;
      if (lastSegment.isNotEmpty && !keywords.contains(lastSegment.toLowerCase())) {
        return lastSegment;
      }
    }

    return null;
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
