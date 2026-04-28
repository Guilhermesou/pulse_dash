import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class CompatibilityScreen extends StatefulWidget {
  const CompatibilityScreen({super.key});

  @override
  State<CompatibilityScreen> createState() => _CompatibilityScreenState();
}

class _CompatibilityScreenState extends State<CompatibilityScreen> {
  bool _isAnalyzing = true;
  
  final List<Map<String, dynamic>> _pids = [
    {'name': 'RPM', 'status': 'disponível', 'icon': Icons.check_circle, 'color': Colors.green},
    {'name': 'Velocidade', 'status': 'disponível', 'icon': Icons.check_circle, 'color': Colors.green},
    {'name': 'Temperatura do Motor', 'status': 'disponível', 'icon': Icons.check_circle, 'color': Colors.green},
    {'name': 'Pressão MAP/Boost', 'status': 'limitado', 'icon': Icons.warning, 'color': Colors.orange},
    {'name': 'Fluxo MAF', 'status': 'disponível', 'icon': Icons.check_circle, 'color': Colors.green},
    {'name': 'Pressão de Combustível', 'status': 'não disponível', 'icon': Icons.error, 'color': AppTheme.pulseRed},
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compatibilidade'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
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
                ] else ...[
                  const Icon(Icons.verified, color: Colors.green, size: 64),
                  const SizedBox(height: 16),
                  Text(
                    'Análise Concluída',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A maioria dos sensores essenciais estão disponíveis.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                ],
              ],
            ),
          ),
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
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                        : Icon(pid['icon'], color: pid['color']),
                    title: Text(pid['name']),
                    trailing: _isAnalyzing 
                        ? const Text('Lendo...')
                        : Text(
                            pid['status'].toUpperCase(),
                            style: TextStyle(
                              color: pid['color'],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                  ),
                );
              },
            ),
          ),
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
