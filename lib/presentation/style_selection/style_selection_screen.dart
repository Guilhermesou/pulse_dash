import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';

class StyleSelectionScreen extends ConsumerWidget {
  const StyleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedStyle = ref.watch(dashboardStyleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Escolha o Estilo'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Selecione o design do seu painel',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            _buildStyleCard(
              context,
              ref,
              title: 'Esportivo (Pulse)',
              description: 'Design agressivo focado em performance, com detalhes em vermelho.',
              icon: Icons.speed,
              style: DashboardStyle.sporty,
              isSelected: selectedStyle == DashboardStyle.sporty,
            ),
            const SizedBox(height: 16),
            _buildStyleCard(
              context,
              ref,
              title: 'Clássico',
              description: 'Painel tradicional analógico, elegante e de fácil leitura.',
              icon: Icons.av_timer,
              style: DashboardStyle.classic,
              isSelected: selectedStyle == DashboardStyle.classic,
            ),
            const SizedBox(height: 16),
            _buildStyleCard(
              context,
              ref,
              title: 'Minimalista',
              description: 'Apenas os dados essenciais na tela, sem distrações.',
              icon: Icons.space_dashboard,
              style: DashboardStyle.minimalist,
              isSelected: selectedStyle == DashboardStyle.minimalist,
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  StorageService.setOnboardingComplete();
                  context.go('/dashboard');
                },
                child: const Text('IR PARA O PAINEL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleCard(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required String description,
    required IconData icon,
    required DashboardStyle style,
    required bool isSelected,
  }) {
    return GestureDetector(
      onTap: () {
        ref.read(dashboardStyleProvider.notifier).setStyle(style);
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardGray,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.pulseRed : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.pulseRed.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 2)]
              : null,
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: isSelected ? AppTheme.pulseRed : AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: isSelected ? Colors.white : AppTheme.textMuted,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
