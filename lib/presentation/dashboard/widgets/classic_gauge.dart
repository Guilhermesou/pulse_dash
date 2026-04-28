import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

// StatefulWidget para manter AnimationController e o painter estático entre rebuilds.
class ClassicGauge extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final String label;
  final String unit;
  final double size;
  final List<double> ticks;
  final bool isReversed;

  const ClassicGauge({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    this.size = 240,
    required this.ticks,
    this.isReversed = false,
  });

  @override
  State<ClassicGauge> createState() => _ClassicGaugeState();
}

class _ClassicGaugeState extends State<ClassicGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  // Painter estático criado UMA VEZ em initState e reutilizado.
  // Isso evita recriar TextPainter + layout() a cada rebuild do pai.
  late final _StaticGaugePainter _staticPainter;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = _buildTween(widget.value, widget.value);
    _staticPainter = _StaticGaugePainter(
      min: widget.min,
      max: widget.max,
      label: widget.label,
      unit: widget.unit,
      ticks: widget.ticks,
    );
  }

  @override
  void didUpdateWidget(ClassicGauge old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Anima do valor atual (posição do ponteiro) até o novo valor.
      _animation = _buildTween(_animation.value, widget.value);
      _controller.forward(from: 0);
    }
  }

  Animation<double> _buildTween(double from, double to) {
    return Tween<double>(begin: from, end: to).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // RepaintBoundary externo isola o gauge inteiro de repaints do pai.
    return RepaintBoundary(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          children: [
            // Camada estática: arcos, marcações, rótulos.
            // RepaintBoundary interno + shouldRepaint: false → pintado UMA VEZ,
            // resultado é cacheado como textura GPU.
            RepaintBoundary(
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _staticPainter,
              ),
            ),
            // Camada dinâmica: apenas o ponteiro — repinta somente nos frames
            // da animação, sem afetar a camada estática.
            AnimatedBuilder(
              animation: _animation,
              builder: (_, _) => CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _NeedlePainter(
                  value: _animation.value,
                  min: widget.min,
                  max: widget.max,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Painter estático ────────────────────────────────────────────────────────
// shouldRepaint sempre retorna false → canvas nunca é invalidado após a 1ª pintura.
class _StaticGaugePainter extends CustomPainter {
  final double min;
  final double max;
  final String label;
  final String unit;
  final List<double> ticks;

  // Paint objects criados uma única vez (campos da instância, não dentro de paint()).
  final Paint _bgPaint = Paint()
    ..color = Color.fromRGBO(255, 255, 255, 0.1)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final Paint _redlinePaint = Paint()
    ..color = AppTheme.pulseRed
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6;

  _StaticGaugePainter({
    required this.min,
    required this.max,
    required this.label,
    required this.unit,
    required this.ticks,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    // Arco de fundo
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      _bgPaint,
    );

    // Arco de redline (últimos 45°)
    const redlineSweep = 45 * (math.pi / 180);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius + 4),
      startAngle + sweepAngle - redlineSweep,
      redlineSweep,
      false,
      _redlinePaint,
    );

    // Marcações e rótulos — executado UMA VEZ e cacheado.
    final majorTickPaint = Paint()..strokeWidth = 2.5;
    final minorTickPaint = Paint()..strokeWidth = 1.0;

    for (var i = 0; i <= 50; i++) {
      final progress = i / 50;
      final angle = startAngle + sweepAngle * progress;
      final isMajor = i % 5 == 0;
      final isRedzone = progress >= 0.83;
      final tickLength = isMajor ? 15.0 : 8.0;

      final paint = isMajor ? majorTickPaint : minorTickPaint;
      paint.color = isRedzone
          ? AppTheme.pulseRed
          : const Color.fromRGBO(255, 255, 255, 0.6);

      final p1 = Offset(
        center.dx + (radius - tickLength) * math.cos(angle),
        center.dy + (radius - tickLength) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      canvas.drawLine(p1, p2, paint);

      if (isMajor) {
        final tickValue = min + (max - min) * progress;
        if (ticks.any((t) => (t - tickValue).abs() < 0.01)) {
          _drawTickLabel(canvas, center, angle, radius, tickValue);
        }
      }
    }

    // Rótulo central (ex: "x1000")
    _drawText(
      canvas,
      label.toLowerCase(),
      const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.5), fontSize: 14),
      Offset(center.dx, center.dy - radius * 0.4),
    );

    // Unidade (ex: "rpm")
    _drawText(
      canvas,
      unit.toLowerCase(),
      const TextStyle(color: Color.fromRGBO(255, 255, 255, 0.5), fontSize: 12),
      Offset(center.dx, center.dy + radius * 0.4),
    );

    // Ícone decorativo
    _drawIcon(
      canvas,
      center,
      Offset(0, radius * 0.25),
      label == 'x1000' ? Icons.thermostat : Icons.speed,
      20,
    );
  }

  void _drawTickLabel(
      Canvas canvas, Offset center, double angle, double radius, double value) {
    final text =
        value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
    _drawText(
      canvas,
      text,
      const TextStyle(
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        fontFamily: 'Outfit',
      ),
      Offset(
        center.dx + (radius - 35) * math.cos(angle),
        center.dy + (radius - 35) * math.sin(angle),
      ),
    );
  }

  void _drawText(Canvas canvas, String text, TextStyle style, Offset center) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawIcon(
      Canvas canvas, Offset center, Offset offset, IconData icon, double size) {
    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: size,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: const Color.fromRGBO(255, 255, 255, 0.4),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(
        center.dx + offset.dx - tp.width / 2,
        center.dy + offset.dy - tp.height / 2,
      ),
    );
  }

  // Nunca repinta — resultado é reutilizado da textura GPU.
  @override
  bool shouldRepaint(_StaticGaugePainter old) => false;
}

// ─── Painter dinâmico (apenas ponteiro) ─────────────────────────────────────
class _NeedlePainter extends CustomPainter {
  final double value;
  final double min;
  final double max;

  // Paint objects estáticos compartilhados por todas as instâncias.
  static final Paint _needlePaint = Paint()
    ..color = AppTheme.pulseRed
    ..style = PaintingStyle.fill;

  static final Paint _centerFill = Paint()
    ..color = const Color(0xFF1A1A1A);

  static final Paint _centerBorder = Paint()
    ..color = const Color(0xFF444444)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final Paint _centerGlow = Paint()
    ..color = const Color.fromRGBO(255, 255, 255, 0.1);

  const _NeedlePainter({
    required this.value,
    required this.min,
    required this.max,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    const startAngle = 135 * (math.pi / 180);
    const sweepAngle = 270 * (math.pi / 180);

    final progress = ((value - min) / (max - min)).clamp(0.0, 1.0);
    final angle = startAngle + sweepAngle * progress;
    final needleLength = radius - 5;
    const baseWidth = 4.0;

    final path = Path()
      ..moveTo(
        center.dx + needleLength * math.cos(angle),
        center.dy + needleLength * math.sin(angle),
      )
      ..lineTo(
        center.dx + baseWidth * math.cos(angle + math.pi / 2),
        center.dy + baseWidth * math.sin(angle + math.pi / 2),
      )
      ..lineTo(
        center.dx + baseWidth * math.cos(angle - math.pi / 2),
        center.dy + baseWidth * math.sin(angle - math.pi / 2),
      )
      ..close();

    canvas.drawPath(path, _needlePaint);
    canvas.drawCircle(center, 12, _centerFill);
    canvas.drawCircle(center, 12, _centerBorder);
    canvas.drawCircle(center, 4, _centerGlow);
  }

  @override
  bool shouldRepaint(_NeedlePainter old) => old.value != value;
}
