import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/constants/app_colors.dart';
import 'core/router/app_router.dart';
import 'core/router/app_routes.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'services/firebase_service.dart';

class ObpAppScrollBehavior extends MaterialScrollBehavior {
  const ObpAppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (safely handles missing google-services.json)
  await FirebaseService.initialize();

  // Configure dark mode status bar and navigation bar styling
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.surfaceContainerLow,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ObpSubsidyApp());
}

class ObpSubsidyApp extends StatefulWidget {
  const ObpSubsidyApp({super.key});

  @override
  State<ObpSubsidyApp> createState() => _ObpSubsidyAppState();
}

class _ObpSubsidyAppState extends State<ObpSubsidyApp> {
  final AppState _appState = AppState();

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: ListenableBuilder(
        listenable: _appState,
        builder: (context, _) {
          return MaterialApp(
            title: 'OBP Driver Hub',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.darkTheme,
            scrollBehavior: const ObpAppScrollBehavior(),
            initialRoute: _appState.isAuthenticated ? AppRoutes.shell : AppRoutes.login,
            onGenerateRoute: AppRouter.onGenerateRoute,
          );
        },
      ),
    );
  }
}
