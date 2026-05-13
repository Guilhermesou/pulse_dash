import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/vehicle_data.dart';

class SportyDashboardLayout extends StatelessWidget {
  final VehicleData data;
  final bool isManual;

  const SportyDashboardLayout({super.key, required this.data, required this.isManual});

  @override
  Widget build(BuildContext context) {
    final rpmRatio = (data.rpm / 8000).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hScale = constraints.maxHeight / 600;
        final wScale = constraints.maxWidth / 1000;

        return Stack(
          children: [
            // Glow animado em RepaintBoundary própria.
            // TweenAnimationBuilder aqui roda a 60fps durante a animação (350ms),
            // mas NÃO afeta o conteúdo de dados que fica em camada separada.
            Positioned.fill(
              child: RepaintBoundary(
                child: _RpmGlowLayer(rpmRatio: rpmRatio),
              ),
            ),

            // Conteúdo de dados — repinta APENAS quando o stream emite (250ms).
            // Isolado do glow pela RepaintBoundary acima.
            _SportyContent(
              data: data,
              hScale: hScale,
              wScale: wScale,
              maxWidth: constraints.maxWidth,
              isManual: isManual,
            ),
          ],
        );
      },
    );
  }
}

// ─── Camada de glow reativo ao RPM ──────────────────────────────────────────
// Responsável apenas pelos gradientes animados. Fica em RepaintBoundary
// própria para não arrastar repaints para o conteúdo de dados.
class _RpmGlowLayer extends StatelessWidget {
  final double rpmRatio;
  const _RpmGlowLayer({required this.rpmRatio});

  Color _glowColor(double ratio) {
    if (ratio < 0.5) {
      return Color.lerp(
        const Color(0x00E3000F),
        const Color(0x55E3000F),
        ratio * 2,
      )!;
    } else if (ratio < 0.8) {
      return Color.lerp(
        const Color(0x55E3000F),
        const Color(0xAAFF2200),
        (ratio - 0.5) / 0.3,
      )!;
    } else {
      return Color.lerp(
        const Color(0xAAFF2200),
        const Color(0xEEFF5500),
        (ratio - 0.8) / 0.2,
      )!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: rpmRatio),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
      builder: (context, animRatio, _) {
        final glowColor = _glowColor(animRatio);

        return Stack(
          children: [
            // Bloom principal vindo de baixo
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, 1.8),
                    radius: 0.7 + animRatio * 0.7,
                    colors: [glowColor, Colors.transparent],
                  ),
                ),
              ),
            ),

            // Halo central em RPM alto (>65%)
            if (animRatio > 0.65)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.55,
                      colors: [
                        glowColor.withValues(alpha: (animRatio - 0.65) * 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

            // Vinheta de borda na zona vermelha (>85%)
            if (animRatio > 0.85)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.4,
                      colors: [
                        Colors.transparent,
                        AppTheme.pulseRed.withValues(
                            alpha: (animRatio - 0.85) * 0.4),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Conteúdo de dados ───────────────────────────────────────────────────────
// Reconstruído apenas quando VehicleData muda (taxa do stream, 250ms).
// Não anima — apenas exibe os valores atuais.
class _SportyContent extends StatelessWidget {
  final VehicleData data;
  final double hScale;
  final double wScale;
  final double maxWidth;
  final bool isManual;

  const _SportyContent({
    required this.data,
    required this.hScale,
    required this.wScale,
    required this.maxWidth,
    required this.isManual,
  });

  @override
  Widget build(BuildContext context) {
    final rpmRatio = (data.rpm / 8000).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Barra de RPM no topo
        Positioned(
          top: 20 * hScale,
          left: 50 * wScale,
          right: 50 * wScale,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(10, (index) {
                  final isActive = rpmRatio * 10 > index;
                  final isRedline = index > 7;
                  final Color segColor;
                  if (isActive) {
                    segColor = isRedline
                        ? AppTheme.pulseRed
                        : Color.lerp(Colors.white, const Color(0xFFFF8800),
                            rpmRatio)!;
                  } else {
                    segColor = const Color.fromRGBO(255, 255, 255, 0.1);
                  }
                  return Container(
                    width: (maxWidth - 120 * wScale) / 10 - 4,
                    height: 20 * hScale,
                    decoration: BoxDecoration(
                      color: segColor,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: isActive && isRedline
                          ? [
                              BoxShadow(
                                color: AppTheme.pulseRed
                                    .withValues(alpha: 0.7),
                                blurRadius: 8,
                              )
                            ]
                          : null,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  9,
                  (i) => Text(
                    '$i',
                    style: const TextStyle(
                      color: Color.fromRGBO(255, 255, 255, 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Velocidade central
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                data.speed.toInt().toString(),
                style: const TextStyle(
                  fontSize: 180,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Outfit',
                  height: 1,
                  color: Colors.white,
                ),
              ),
              const Text(
                'KM/H',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                  color: AppTheme.pulseRed,
                ),
              ),
            ],
          ),
        ),

        // Marcha estimada (centro inferior) — apenas câmbio manual
        if (isManual)
          Positioned(
            bottom: 40 * hScale,
            left: 0,
            right: 0,
            child: Center(child: GearBadge(gear: data.estimatedGear)),
          ),

        // Boost (direita inferior)
        Positioned(
          bottom: 40 * hScale,
          right: 40 * wScale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('BOOST',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.boost.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit'),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('bar',
                        style: TextStyle(
                            color: AppTheme.pulseRed,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Temperatura (esquerda inferior)
        Positioned(
          bottom: 40 * hScale,
          left: 40 * wScale,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('TEMP',
                  style: TextStyle(
                      color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data.temperature.toInt().toString(),
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Outfit'),
                  ),
                  const SizedBox(width: 4),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text('°C',
                        style: TextStyle(
                            color: AppTheme.pulseRed,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class GearBadge extends StatelessWidget {
  final int? gear;
  const GearBadge({super.key, required this.gear});

  @override
  Widget build(BuildContext context) {
    final label = gear?.toString() ?? 'N';
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.pulseRed, width: 2),
        color: AppTheme.pulseRed.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontFamily: 'Outfit',
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
