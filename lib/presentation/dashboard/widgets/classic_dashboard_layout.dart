import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/vehicle_data.dart';
import 'classic_gauge.dart';

class ClassicDashboardLayout extends StatelessWidget {
  final VehicleData data;

  const ClassicDashboardLayout({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLandscape = constraints.maxWidth > constraints.maxHeight;
        final hScale = constraints.maxHeight / 600; // Ref base height
        final wScale = constraints.maxWidth / 1000; // Ref base width

        return Stack(
          children: [
            // Decoração do Topo (Linha Vermelha)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: Size(constraints.maxWidth, 60 * hScale),
                painter: _TopDecorationPainter(),
              ),
            ),

            // Top Bar Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40 * wScale, vertical: 20 * hScale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '14:35',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16 * hScale.clamp(0.8, 1.2)),
                  ),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        children: [
                          const Text(
                            'PULSE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          Text(
                            'DASH',
                            style: TextStyle(
                              color: AppTheme.pulseRed,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text(
                    '24.5°C',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 16 * hScale.clamp(0.8, 1.2)),
                  ),
                ],
              ),
            ),

            // Main Content Area
            Positioned.fill(
              top: 80 * hScale,
              bottom: 120 * hScale,
              child: Row(
                children: [
                  // RPM Gauge
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FittedBox(
                        child: ClassicGauge(
                          value: data.rpm / 1000,
                          min: 0,
                          max: 8,
                          label: 'x1000',
                          unit: 'rpm',
                          ticks: const [0, 1, 2, 3, 4, 5, 6, 7, 8],
                          size: constraints.maxHeight * 0.45,
                        ),
                      ),
                    ),
                  ),

                  // Center Section
                  Expanded(
                    flex: 4,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Speed
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            data.speed.toInt().toString().padLeft(3, '0'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 120,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Outfit',
                              height: 1,
                            ),
                          ),
                        ),
                        Text(
                          'km/h',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.4),
                            fontSize: 18 * hScale.clamp(0.8, 1.2),
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(height: 24 * hScale),
                        // 4 Info Boxes Grid
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildInfoItem(Icons.local_gas_station, 'CONSUMO', data.fuelConsumption.toStringAsFixed(1), 'km/l', hScale),
                                _buildVerticalDivider(hScale),
                                _buildInfoItem(Icons.thermostat, 'TEMP. MOTOR', data.temperature.toInt().toString(), '°C', hScale),
                                _buildVerticalDivider(hScale),
                                _buildInfoItem(Icons.directions_car, 'AUTONOMIA', '320', 'km', hScale),
                                _buildVerticalDivider(hScale),
                                _buildInfoItem(Icons.battery_charging_full, 'TENSÃO', data.batteryVoltage.toStringAsFixed(1), 'V', hScale),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Boost Gauge
                  Expanded(
                    flex: 3,
                    child: Center(
                      child: FittedBox(
                        child: ClassicGauge(
                          value: data.boost,
                          min: -1.0,
                          max: 2.0,
                          label: 'bar',
                          unit: 'boost',
                          ticks: const [-1.0, -0.5, 0, 0.5, 1.0, 1.5, 2.0],
                          size: constraints.maxHeight * 0.45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Info Bar
            Positioned(
              bottom: 80 * hScale,
              left: 0,
              right: 0,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'TRIP A   ${(152.4).toStringAsFixed(1)} km',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14 * hScale.clamp(0.8, 1.2)),
                      ),
                      const SizedBox(width: 40),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppTheme.pulseRed, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'D',
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Text(
                        'ODO   ${45678} km',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14 * hScale.clamp(0.8, 1.2)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Fuel and Temp Bars at the very bottom corners
            if (isLandscape) ...[
              Positioned(
                bottom: 30 * hScale,
                left: 40 * wScale,
                child: _buildHorizontalBar(Icons.local_gas_station, 'E', 'F', 0.4, wScale, hScale),
              ),
              Positioned(
                bottom: 30 * hScale,
                right: 40 * wScale,
                child: _buildHorizontalBar(Icons.thermostat, 'C', 'H', 0.6, wScale, hScale),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, String unit, double scale) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 12 * scale.clamp(0.8, 1.2), color: Colors.white.withValues(alpha: 0.5)),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 9 * scale.clamp(0.8, 1.2))),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 24 * scale.clamp(0.8, 1.2), fontWeight: FontWeight.bold)),
        Text(unit, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10 * scale.clamp(0.8, 1.2))),
      ],
    );
  }

  Widget _buildVerticalDivider(double scale) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      height: 30 * scale,
      width: 1,
      color: Colors.white.withValues(alpha: 0.1),
    );
  }

  Widget _buildHorizontalBar(IconData icon, String startLabel, String endLabel, double progress, double wScale, double hScale) {
    return Row(
      children: [
        Icon(icon, size: 20 * hScale.clamp(0.8, 1.2), color: Colors.white.withValues(alpha: 0.6)),
        const SizedBox(width: 8),
        Text(startLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12 * hScale.clamp(0.8, 1.2))),
        const SizedBox(width: 8),
        Container(
          width: 100 * wScale.clamp(0.5, 1.5),
          height: 10,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Stack(
            children: [
              // Ticks background
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(8, (index) => Container(width: 1, height: 10, color: Colors.black)),
              ),
              // Progress
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(endLabel, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12 * hScale.clamp(0.8, 1.2))),
      ],
    );
  }
}

class _TopDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.pulseRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final w = size.width;
    
    // Desenha a linha superior característica
    path.moveTo(0, 0);
    path.lineTo(w * 0.3, 0);
    path.lineTo(w * 0.35, 40);
    path.lineTo(w * 0.65, 40);
    path.lineTo(w * 0.7, 0);
    path.lineTo(w, 0);

    canvas.drawPath(path, paint);
    
    // Glow effect sutil
    final glowPaint = Paint()
      ..color = AppTheme.pulseRed.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    
    canvas.drawPath(path, glowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
