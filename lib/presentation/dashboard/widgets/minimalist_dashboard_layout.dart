import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/vehicle_data.dart';

class MinimalistDashboardLayout extends StatelessWidget {
  final VehicleData data;
  final bool isManual;

  const MinimalistDashboardLayout({super.key, required this.data, required this.isManual});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Painel esquerdo: velocidade + barra RPM
            SizedBox(
              width: constraints.maxWidth * 0.34,
              child: _SpeedPanel(data: data, isManual: isManual),
            ),

            // Divisor sutil
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 20),
              color: Colors.white.withValues(alpha: 0.07),
            ),

            // Painel direito: grade de métricas
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: _MetricsGrid(data: data),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SpeedPanel extends StatelessWidget {
  final VehicleData data;
  final bool isManual;
  const _SpeedPanel({required this.data, required this.isManual});

  @override
  Widget build(BuildContext context) {
    final rpmRatio = (data.rpm / 8000).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Velocidade principal
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: rpmRatio),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, ratio, _) {
              return Text(
                data.speed.toInt().toString(),
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.w200,
                  fontFamily: 'Outfit',
                  color: Colors.white,
                  letterSpacing: -4,
                  height: 1,
                  shadows: ratio > 0.5
                      ? [
                          Shadow(
                            color: AppTheme.pulseRed.withValues(alpha: ratio * 0.35),
                            blurRadius: 18,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          const Text(
            'KM/H',
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 5,
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),

          // Barra de RPM fina
          _RpmBar(rpmRatio: rpmRatio),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '0',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9),
              ),
              Text(
                '${(data.rpm / 1000).toStringAsFixed(1)}k rpm',
                style: const TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '8',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.25), fontSize: 9),
              ),
            ],
          ),
          if (isManual) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'MARCHA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.25),
                    fontSize: 9,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  data.estimatedGear?.toString() ?? 'N',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w300,
                    fontFamily: 'Outfit',
                    color: Colors.white,
                    height: 1,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RpmBar extends StatelessWidget {
  final double rpmRatio;
  const _RpmBar({required this.rpmRatio});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 4,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: rpmRatio),
            duration: const Duration(milliseconds: 300),
            builder: (context, ratio, _) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: ratio,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.6),
                        ratio > 0.8 ? AppTheme.pulseRed : Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: ratio > 0.75
                        ? [
                            BoxShadow(
                              color: AppTheme.pulseRed.withValues(alpha: 0.55),
                              blurRadius: 6,
                            ),
                          ]
                        : null,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  final VehicleData data;
  const _MetricsGrid({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'RPM',
                value: data.rpm.toInt().toString(),
                unit: '',
                alert: data.rpm > 6400,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'TEMP',
                value: data.temperature.toInt().toString(),
                unit: '°C',
                alert: data.temperature > 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'BOOST',
                value: data.boost.toStringAsFixed(2),
                unit: 'bar',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _MetricCard(
                label: 'BATERIA',
                value: data.batteryVoltage.toStringAsFixed(1),
                unit: 'V',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final bool alert;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.unit,
    this.alert = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = alert ? AppTheme.pulseRed : Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: alert
              ? AppTheme.pulseRed.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 26,
                  fontWeight: FontWeight.w300,
                  fontFamily: 'Outfit',
                  letterSpacing: -1,
                  height: 1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 3),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    unit,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
