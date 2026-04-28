import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  const ConnectingScreen({super.key});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  int _currentStep = 0;
  final List<String> _steps = [
    'Conectando ao Bluetooth...',
    'Inicializando ELM327...',
    'Lendo dados da ECU...',
    'Verificando protocolo OBD2...',
  ];

  @override
  void initState() {
    super.initState();
    _simulateConnection();
  }

  Future<void> _simulateConnection() async {
    for (int i = 0; i < _steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentStep = i;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
    }
    if (!mounted) return;
    
    // Connect the repository
    await ref.read(obdRepositoryProvider).connect('dummy_mac');
    ref.read(obdConnectionStateProvider.notifier).updateState(ObdConnectionState.connected);
    
    if (!mounted) return;
    context.go('/compatibility');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween<double>(begin: 0, end: (_currentStep + 1) / _steps.length),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, value, child) {
                  return SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: value,
                          strokeWidth: 8,
                          backgroundColor: AppTheme.cardGray,
                          color: AppTheme.pulseRed,
                        ),
                        Center(
                          child: Text(
                            '${(value * 100).toInt()}%',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 48),
              Text(
                _steps[_currentStep],
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Por favor, mantenha a ignição ligada.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
