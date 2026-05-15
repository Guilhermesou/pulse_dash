import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_service.dart';
import 'data/providers.dart';
import 'presentation/widgets/auto_connect_manager.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  await Hive.initFlutter();
  await StorageService.init();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(const ProviderScope(child: PulseDashApp()));
  FlutterNativeSplash.remove();
}

class PulseDashApp extends ConsumerWidget {
  const PulseDashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final colorIndex = settings.primaryColorIndex.clamp(0, AppTheme.accentColors.length - 1);
    final primary = AppTheme.accentColors[colorIndex].color;

    return MaterialApp.router(
      title: 'Pulse Dash',
      theme: AppTheme.buildTheme(primary),
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) => AutoConnectManager(child: child!),
    );
  }
}
