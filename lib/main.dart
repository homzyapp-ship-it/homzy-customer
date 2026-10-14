import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hyper_local/bloc/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/widgets/cart_state_listener.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';
import 'utils/theme_switcher_provider.dart';
import 'app/app_bloc_observer.dart';
import 'app/app_bootstrap.dart';
import 'config/dependency_injection_container.dart';
import 'config/global_bloc_providers.dart';
import 'config/theme.dart';
import 'l10n/app_localizations.dart';

import 'package:flutter_http_inspector/flutter_http_inspector.dart';

void main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Debug-only: the inspector captures every request, including auth headers.
    if (kDebugMode) {
      HttpInspector.setup();
    }

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
    await AppBootstrap.initialize();
    setupLocator();
    Bloc.observer = AppBlocObserver();
    runApp(
      const MyApp(),
    );
  }, (error, stackTrace) {
    debugPrint('Unhandled app error: $error');
    debugPrintStack(stackTrace: stackTrace);
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: globalBlocProviders(),
      child: const CartStateListener(
        child: _AnimatedThemeWrapper(),
      ),
    );
  }
}

class _AnimatedThemeWrapper extends StatelessWidget {
  const _AnimatedThemeWrapper();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((ThemeBloc bloc) => bloc.state);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final initialTheme = AppTheme.resolveFromMode(themeMode, brightness);

    return ThemeProvider(
      initTheme: initialTheme,
      builder: (context, theme) {
        return ThemeSwitcher.switcher(
          builder: (context, switcher) {
            return ThemeSwitcherProvider(
              changeTheme: (theme) => switcher.changeTheme(theme: theme),
              child: BlocBuilder<ThemeBloc, ThemeMode>(
                builder: (context, themeMode) {
                  return BlocBuilder<LanguageBloc, LanguageState>(
                    builder: (context, languageState) {
                      return GestureDetector(
                        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                        child: ScreenUtilInit(
                          child: SafeArea(
                            top: false,
                            bottom: Platform.isIOS ? false : true,
                            left: false,
                            right: false,
                            child: MaterialApp.router(
                              debugShowCheckedModeBanner: false,
                              theme: theme,
                              darkTheme: AppTheme.darkTheme,
                              themeMode: themeMode,
                              builder: FToastBuilder(),
                              routerConfig: MyAppRoute.router,
                              localizationsDelegates: AppLocalizations.localizationsDelegates,
                              supportedLocales: AppLocalizations.supportedLocales,
                              locale: languageState is LanguageLoaded ? languageState.locale : const Locale('en'),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
