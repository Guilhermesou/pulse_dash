import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';
import 'widgets/classic_dashboard_layout.dart';
import 'widgets/sporty_dashboard_layout.dart';
import 'widgets/minimalist_dashboard_layout.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleDataAsync = ref.watch(vehicleDataProvider);
    final selectedStyle = ref.watch(dashboardStyleProvider);
    final isManual = ref.watch(appSettingsProvider.select((s) => s.isManual));

    final connectionState = ref.watch(obdConnectionStateProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: connectionState == ObdConnectionState.disconnected
          ? _DisconnectedOverlay(
              onReconnect: () => context.go('/search'),
            )
          : vehicleDataAsync.when(
              data: (data) => SafeArea(
                child: _buildSelectedLayout(selectedStyle, data, isManual),
              ),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (_, _) => _DisconnectedOverlay(
                onReconnect: () {
                  ref
                      .read(obdConnectionStateProvider.notifier)
                      .updateState(ObdConnectionState.disconnected);
                  context.go('/search');
                },
              ),
            ),
    );
  }

  Widget _buildSelectedLayout(DashboardStyle style, dynamic data, bool isManual) {
    switch (style) {
      case DashboardStyle.sporty:
        return SportyDashboardLayout(data: data, isManual: isManual);
      case DashboardStyle.classic:
        return ClassicDashboardLayout(data: data, isManual: isManual);
      case DashboardStyle.minimalist:
        return MinimalistDashboardLayout(data: data, isManual: isManual);
    }
  }
}

class _DisconnectedOverlay extends StatelessWidget {
  final VoidCallback onReconnect;
  const _DisconnectedOverlay({required this.onReconnect});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.pulseRed.withValues(alpha: 0.15),
              ),
              child: const Icon(
                Icons.bluetooth_disabled,
                size: 64,
                color: AppTheme.pulseRed,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'OBD2 Desconectado',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: AppTheme.textLight),
            ),
            const SizedBox(height: 12),
            const Text(
              'A conexão com o adaptador foi perdida.\nVerifique se o ELM327 está ligado.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textMuted),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onReconnect,
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('RECONECTAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
