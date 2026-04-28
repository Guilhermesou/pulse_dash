import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout handle background
      body: vehicleDataAsync.when(
        data: (data) {
          return SafeArea(
            child: _buildSelectedLayout(selectedStyle, data),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.pulseRed)),
        error: (error, stack) => Center(
          child: Text('Erro: $error',
              style: const TextStyle(color: AppTheme.pulseRed)),
        ),
      ),
    );
  }

  Widget _buildSelectedLayout(DashboardStyle style, dynamic data) {
    switch (style) {
      case DashboardStyle.sporty:
        return SportyDashboardLayout(data: data);
      case DashboardStyle.classic:
        return ClassicDashboardLayout(data: data);
      case DashboardStyle.minimalist:
        return MinimalistDashboardLayout(data: data);
    }
  }
}
