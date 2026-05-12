import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/diagnostic_code.dart';

class DiagnosticsScreen extends ConsumerWidget {
  const DiagnosticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final errorsAsync = ref.watch(diagnosticErrorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico OBD2'),
        actions: [
          TextButton.icon(
            onPressed: () => _clearCodes(context, ref),
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Limpar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: errorsAsync.when(
        data: (errors) {
          if (errors.isEmpty) {
            return _buildNoErrors();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: errors.length,
            itemBuilder: (context, index) {
              return _buildErrorCard(context, errors[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.pulseRed)),
        error: (err, stack) => Center(child: Text('Erro ao ler códigos: $err')),
      ),
    );
  }

  Future<void> _clearCodes(BuildContext context, WidgetRef ref) async {
    final repository = ref.read(obdRepositoryProvider);
    try {
      await repository.clearErrors();
      ref.invalidate(diagnosticErrorsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Códigos de falha apagados da ECU.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao limpar códigos: $e')),
        );
      }
    }
  }

  Widget _buildNoErrors() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          SizedBox(height: 16),
          Text('Nenhum código de falha encontrado.', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, DiagnosticCode error) {
    Color severityColor;
    switch (error.severity) {
      case ErrorSeverity.high:
        severityColor = AppTheme.pulseRed;
        break;
      case ErrorSeverity.medium:
        severityColor = Colors.orange;
        break;
      case ErrorSeverity.low:
        severityColor = Colors.yellow;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: severityColor.withValues(alpha: 0.2),
          child: Icon(Icons.warning_amber, color: severityColor),
        ),
        title: Text(
          error.code,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.pulseRed),
        ),
        subtitle: Text(error.description),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Análise Inteligente', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text('Confiança: ${error.confidencePercent}%', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Possíveis Causas:', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                ...error.causes.map((cause) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_right, color: AppTheme.pulseRed, size: 20),
                          Expanded(child: Text(cause)),
                        ],
                      ),
                    )),
                const SizedBox(height: 16),
                const Text('Sugestões de Verificação:', style: TextStyle(color: AppTheme.textMuted)),
                const SizedBox(height: 8),
                ...error.suggestions.map((sug) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.build, color: Colors.blueAccent, size: 16),
                          const SizedBox(width: 8),
                          Expanded(child: Text(sug)),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
