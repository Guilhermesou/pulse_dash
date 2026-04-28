import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class CustomGauge extends StatelessWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final bool isReversed;
  final double size;

  const CustomGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    this.isReversed = false,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: value, end: value),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: size,
              height: size,
              child: CustomPaint(
                painter: _GaugePainter(
                  value: animatedValue,
                  min: min,
                  max: max,
                  isReversed: isReversed,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: size * 0.2),
                      Text(
                        animatedValue.toStringAsFixed(label == 'RPM' ? 0 : 1),
                        style: TextStyle(
                          fontSize: size * 0.16,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Outfit',
                          color: AppTheme.textLight,
                        ),
                      ),
                      Text(
                        unit,
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: size * 0.07,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.pulseRed,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 12,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;
  final bool isReversed;

  _GaugePainter({
    required this.value,
    required this.min,
    required this.max,
    required this.isReversed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Configurações dos arcos (começa em 140 graus e vai até 40 graus)
    const startAngle = 140 * (math.pi / 180);
    const sweepAngle = 260 * (math.pi / 180);

    // Fundo do gauge
    final bgPaint = Paint()
      ..color = const Color(0xFF2A2A2A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Redline no final
    final redlinePaint = Paint()
      ..color = AppTheme.pulseRed.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;
    
    // Últimos 20% é redline
    const redlineSweep = sweepAngle * 0.2;
    final redlineStart = isReversed ? startAngle : startAngle + sweepAngle - redlineSweep;
    
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      redlineStart,
      redlineSweep,
      false,
      redlinePaint,
    );

    // Preenchimento do valor atual
    final clampedValue = value.clamp(min, max);
    final progress = (clampedValue - min) / (max - min);
    final currentSweep = sweepAngle * progress;

    final fillPaint = Paint()
      ..color = AppTheme.textLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final startFillAngle = isReversed ? (startAngle + sweepAngle - currentSweep) : startAngle;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startFillAngle,
      currentSweep,
      false,
      fillPaint,
    );

    // Ponteiro
    final pointerAngle = startFillAngle + (isReversed ? 0 : currentSweep);
    final pointerPaint = Paint()
      ..color = AppTheme.pulseRed
      ..style = PaintingStyle.fill;
    
    final pointerLength = radius - 15;
    final pX = center.dx + pointerLength * math.cos(pointerAngle);
    final pY = center.dy + pointerLength * math.sin(pointerAngle);

    canvas.drawCircle(Offset(pX, pY), 6, pointerPaint);
    
    // Desenhar as marcas    
    for (int i = 0; i <= 10; i++) {
      final markProgress = i / 10;
      final markAngle = startAngle + (sweepAngle * markProgress);
      
      final innerRadius = radius - 20;
      final outerRadius = radius - 5;
      
      final m1X = center.dx + innerRadius * math.cos(markAngle);
      final m1Y = center.dy + innerRadius * math.sin(markAngle);
      final m2X = center.dx + outerRadius * math.cos(markAngle);
      final m2Y = center.dy + outerRadius * math.sin(markAngle);
      
      final markPaint = Paint()
        ..color = markProgress >= 0.8 ? AppTheme.pulseRed : AppTheme.textMuted
        ..strokeWidth = i % 2 == 0 ? 3 : 1;
        
      canvas.drawLine(Offset(m1X, m1Y), Offset(m2X, m2Y), markPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}
