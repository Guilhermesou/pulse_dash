import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class ConnectObdScreen extends StatelessWidget {
  const ConnectObdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conectar OBD'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.pulseRed.withValues(alpha: 0.5), width: 2),
                ),
                child: const Icon(
                  Icons.bluetooth_connected,
                  size: 80,
                  color: AppTheme.pulseRed,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Conexão Bluetooth',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              const Text(
                'Certifique-se de que o dispositivo ELM327\nestá pareado com o seu celular.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/search'),
                  icon: const Icon(Icons.search),
                  label: const Text('PROCURAR DISPOSITIVOS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
