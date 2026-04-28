import 'package:go_router/go_router.dart';

import '../../presentation/onboarding/onboarding_screen.dart';
import '../../presentation/connect_obd/connect_obd_screen.dart';
import '../../presentation/connect_obd/search_device_screen.dart';
import '../../presentation/connect_obd/connecting_screen.dart';
import '../../presentation/connect_obd/compatibility_screen.dart';
import '../../presentation/dashboard/dashboard_screen.dart';
import '../../presentation/diagnostics/diagnostics_screen.dart';
import '../../presentation/dashboard/live_data_screen.dart';
import '../../presentation/style_selection/style_selection_screen.dart';
import '../../presentation/settings/settings_screen.dart';
import '../../presentation/widgets/main_layout.dart';
import '../../presentation/map/map_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/connect',
      builder: (context, state) => const ConnectObdScreen(),
    ),
    GoRoute(
      path: '/search',
      builder: (context, state) => const SearchDeviceScreen(),
    ),
    GoRoute(
      path: '/connecting',
      builder: (context, state) => const ConnectingScreen(),
    ),
    GoRoute(
      path: '/compatibility',
      builder: (context, state) => const CompatibilityScreen(),
    ),
    GoRoute(
      path: '/style-selection',
      builder: (context, state) => const StyleSelectionScreen(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainLayout(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/live-data',
          builder: (context, state) => const LiveDataScreen(),
        ),
        GoRoute(
          path: '/diagnostics',
          builder: (context, state) => const DiagnosticsScreen(),
        ),
        GoRoute(
          path: '/map',
          builder: (context, state) => const MapScreen(),
        ),
      ],
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
