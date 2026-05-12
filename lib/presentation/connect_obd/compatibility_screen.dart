import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../data/repositories/bluetooth_obd_repository.dart';

class CompatibilityScreen extends ConsumerStatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  ConsumerState<CompatibilityScreen> createState() =>
      _CompatibilityScreenState();
}

class _CompatibilityScreenState extends ConsumerState<CompatibilityScreen> {
  bool _isAnalyzing = true;
  List<_PidStatus> _pids = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _analyzeVehicle();
  }

  Future<void> _analyzeVehicle() async {
    try {
      final repository = ref.read(obdRepositoryProvider);

      // Tenta ler PIDs suportados se for o repo real
      if (repository is BluetoothObdRepository) {
        final supported = await repository.getSupportedPids();

        if (mounted) {
          setState(() {
            _pids = supported.map((p) => _PidStatus(
              name: p.name,
              status: p.supported ? 'disponível' : 'não disponível',
              icon: p.supported ? Icons.check_circle : Icons.error,
              color: p.supported ? Colors.green : AppTheme.pulseRed,
            )).toList();

            // Adiciona tensão da bateria (sempre disponível via AT)
            _pids.add(const _PidStatus(
              name: 'Tensão Bateria',
              status: 'disponível',
              icon: Icons.check_circle,
              color: Colors.green,
            ));

            _isAnalyzing = false;
          });
        }
      } else {
        // Mock mode — simula análise
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          setState(() {
            _pids = const [
              _PidStatus(name: 'RPM', status: 'disponível', icon: Icons.check_circle, color: Colors.green),
              _PidStatus(name: 'Velocidade', status: 'disponível', icon: Icons.check_circle, color: Colors.green),
              _PidStatus(name: 'Temperatura do Motor', status: 'disponível', icon: Icons.check_circle, color: Colors.green),
              _PidStatus(name: 'Pressão MAP/Boost', status: 'limitado', icon: Icons.warning, color: Colors.orange),
              _PidStatus(name: 'Fluxo MAF', status: 'disponível', icon: Icons.check_circle, color: Colors.green),
              _PidStatus(name: 'Tensão Bateria', status: 'disponível', icon: Icons.check_circle, color: Colors.green),
            ];
            _isAnalyzing = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao analisar: $e';
          _isAnalyzing = false;
        });
      }
    }
  }

  int get _availableCount =>
      _pids.where((p) => p.status == 'disponível').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilidade'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // ─── Header ─────────────────────────────────────────────────────
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                if (_isAnalyzing) ...[
                  const CircularProgressIndicator(color: AppTheme.pulseRed),
                  const SizedBox(height: 24),
                  Text(
                    'Analisando seu veículo...',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Verificando PIDs suportados pela ECU',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ] else if (_error != null) ...[
                  const Icon(Icons.warning_amber, color: Colors.orange, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ] else ...[
                  const Icon(Icons.verified, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Análise Concluída',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$_availableCount de ${_pids.length} sensores disponíveis.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),

          // ─── Lista de PIDs ──────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              itemCount: _pids.length,
              itemBuilder: (context, index) {
                final pid = _pids[index];
                if (_isAnalyzing && index > 2) return const SizedBox.shrink();

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: _isAnalyzing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(pid.icon, color: pid.color),
                    title: Text(pid.name),
                    trailing: _isAnalyzing
                        ? const Text('Lendo...')
                        : Text(
                            pid.status.toUpperCase(),
                            style: TextStyle(
                              color: pid.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // ─── Botão continuar ────────────────────────────────────────────
          if (!_isAnalyzing)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pulseRed,
                  ),
                  onPressed: () => context.go('/style-selection'),
                  child: const Text('CONTINUAR'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Modelo interno para status de um PID na UI.
class _PidStatus {
  final String name;
  final String status;
  final IconData icon;
  final Color color;

  const _PidStatus({
    required this.name,
    required this.status,
    required this.icon,
    required this.color,
  });
}
