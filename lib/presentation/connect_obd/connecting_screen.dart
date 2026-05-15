import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';

class ConnectingScreen extends ConsumerStatefulWidget {
  /// Endereço MAC do dispositivo Bluetooth a conectar.
  final String deviceAddress;

  const ConnectingScreen({super.key, required this.deviceAddress});

  @override
  ConsumerState<ConnectingScreen> createState() => _ConnectingScreenState();
}

class _ConnectingScreenState extends ConsumerState<ConnectingScreen> {
  int _currentStep = 0;
  bool _hasError = false;
  String _errorMessage = '';

  final List<String> _steps = [
    'Conectando ao Bluetooth...',
    'Inicializando ELM327...',
    'Lendo dados da ECU...',
    'Verificando protocolo OBD2...',
  ];

  @override
  void initState() {
    super.initState();
    _performRealConnection();
  }

  Future<void> _performRealConnection() async {
    try {
      // Step 1: Conectar Bluetooth RFCOMM
      _setStep(0);
      final repository = ref.read(obdRepositoryProvider);
      
      // Atualiza estado para 'connecting'
      ref.read(obdConnectionStateProvider.notifier)
          .updateState(ObdConnectionState.connecting);

      // Step 2: Conectar e inicializar ELM327
      _setStep(1);
      await repository.connect(widget.deviceAddress);

      // Step 3: Lendo ECU
      _setStep(2);
      await Future.delayed(const Duration(milliseconds: 800)); // Breve pausa visual

      // Step 4: Verificando protocolo
      _setStep(3);
      await Future.delayed(const Duration(milliseconds: 500));

      // Conexão bem-sucedida
      final notifier = ref.read(obdConnectionStateProvider.notifier);
      notifier.saveDeviceId(widget.deviceAddress);
      notifier.updateState(ObdConnectionState.connected);

      if (!mounted) return;
      context.go('/compatibility');
    } catch (e) {
      if (!mounted) return;

      ref.read(obdConnectionStateProvider.notifier)
          .updateState(ObdConnectionState.disconnected);

      setState(() {
        _hasError = true;
        _errorMessage = _friendlyError(e.toString());
      });
    }
  }

  void _setStep(int step) {
    if (mounted) {
      setState(() => _currentStep = step);
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('IOException') || raw.contains('socket')) {
      return 'Não foi possível conectar ao dispositivo.\n'
          'Verifique se o ELM327 está ligado e pareado.';
    }
    if (raw.contains('timeout') || raw.contains('TimeoutException')) {
      return 'Tempo esgotado ao conectar.\n'
          'O dispositivo não respondeu a tempo.';
    }
    if (raw.contains('refused') || raw.contains('denied')) {
      return 'Conexão recusada pelo dispositivo.\n'
          'Tente parear novamente nas configurações do sistema.';
    }
    return 'Erro ao conectar: $raw';
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _currentStep = 0;
    });
    _performRealConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
            child: _hasError ? _buildErrorUI() : _buildConnectingUI(),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectingUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween<double>(
              begin: 0, end: (_currentStep + 1) / _steps.length),
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
    );
  }

  Widget _buildErrorUI() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.pulseRed.withValues(alpha: 0.15),
          ),
          child: const Icon(
            Icons.error_outline,
            size: 64,
            color: AppTheme.pulseRed,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          'Falha na Conexão',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          _errorMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
        const SizedBox(height: 40),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _retry,
            icon: const Icon(Icons.refresh),
            label: const Text('TENTAR NOVAMENTE'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => context.go('/search'),
          child: const Text('Voltar para a busca'),
        ),
      ],
    );
  }
}
