import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';

class AutoConnectManager extends ConsumerStatefulWidget {
  final Widget child;

  const AutoConnectManager({super.key, required this.child});

  @override
  ConsumerState<AutoConnectManager> createState() => _AutoConnectManagerState();
}

class _AutoConnectManagerState extends ConsumerState<AutoConnectManager> {
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoConnect();
    });
  }

  Future<void> _checkAutoConnect() async {
    final settings = ref.read(appSettingsProvider);
    final connectionState = ref.read(obdConnectionStateProvider);
    final lastDevice = StorageService.getLastDeviceId();

    // Se as configurações permitem auto-connect, estávamos "conectados" e temos um ID salvo
    if (settings.autoConnect && 
        connectionState == ObdConnectionState.connected && 
        lastDevice != null &&
        !settings.devMode) {
      
      setState(() => _isReconnecting = true);

      try {
        final repository = ref.read(obdRepositoryProvider);
        
        // Atualiza estado temporariamente para 'connecting'
        ref.read(obdConnectionStateProvider.notifier)
            .updateState(ObdConnectionState.connecting);

        await repository.connect(lastDevice);

        // Sucesso
        ref.read(obdConnectionStateProvider.notifier)
            .updateState(ObdConnectionState.connected);
      } catch (e) {
        // Falha no auto-connect: volta para desconectado
        ref.read(obdConnectionStateProvider.notifier)
            .updateState(ObdConnectionState.disconnected);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Não foi possível reconectar ao OBD automaticamente.'),
              backgroundColor: AppTheme.pulseRed,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isReconnecting = false);
      }
    } else if (connectionState == ObdConnectionState.connected && lastDevice == null) {
      // Estado inconsistente: diz que está conectado mas não tem ID. Reseta.
      ref.read(obdConnectionStateProvider.notifier)
          .updateState(ObdConnectionState.disconnected);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isReconnecting) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundBlack,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppTheme.pulseRed),
              const SizedBox(height: 24),
              Text(
                'RECONECTANDO AO OBD...',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: 2,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}
