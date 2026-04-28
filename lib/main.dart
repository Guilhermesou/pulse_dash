import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/storage/storage_service.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  
  await Hive.initFlutter();
  await StorageService.init();
  
  // Modo imersivo: esconde status bar e nav bar do sistema.
  // Devolve a tela inteira para o painel e reduz overhead de compositing.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Force landscape mode for better dashboard experience
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  runApp(const ProviderScope(child: PulseDashApp()));
  
  // Remove splash screen after initialization
  FlutterNativeSplash.remove();
}

class PulseDashApp extends StatelessWidget {
  const PulseDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pulse Dash',
      theme: AppTheme.darkTheme,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
