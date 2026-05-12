import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/vehicle_data.dart';

// Metadados estáticos das métricas — definidos uma vez, nunca recriados.
typedef _MetricMeta = ({String label, String unit, int decimals});

const List<_MetricMeta> _kMetrics = [
  (label: 'RPM', unit: 'rpm', decimals: 0),
  (label: 'Velocidade', unit: 'km/h', decimals: 0),
  (label: 'Pressão Turbo', unit: 'bar', decimals: 2),
  (label: 'Temperatura', unit: '°C', decimals: 0),
  (label: 'Carga Motor', unit: '%', decimals: 1),
  (label: 'Tensão Bateria', unit: 'V', decimals: 1),
  (label: 'Consumo Inst.', unit: 'L/h', decimals: 1),
  (label: 'Pos. Borboleta', unit: '%', decimals: 1),
];

double _getValue(VehicleData data, int index) => switch (index) {
      0 => data.rpm,
      1 => data.speed,
      2 => data.boost,
      3 => data.temperature,
      4 => data.engineLoad,
      5 => data.batteryVoltage,
      6 => data.fuelConsumption,
      _ => data.throttlePosition,
    };

class LiveDataScreen extends ConsumerWidget {
  const LiveDataScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleDataAsync = ref.watch(vehicleDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Dados em Tempo Real')),
      body: vehicleDataAsync.when(
        data: (data) => LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth > 900
                ? 4
                : constraints.maxWidth > 600
                    ? 3
                    : 2;

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 1.5,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _kMetrics.length,
              itemBuilder: (context, index) {
                // RepaintBoundary isola cada card: a animação de um card
                // não invalida os outros.
                return RepaintBoundary(
                  child: _DataCard(
                    meta: _kMetrics[index],
                    value: _getValue(data, index),
                  ),
                );
              },
            );
          },
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppTheme.pulseRed)),
        error: (_, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.bluetooth_disabled, size: 48, color: AppTheme.pulseRed),
              const SizedBox(height: 16),
              const Text('OBD2 Desconectado', style: TextStyle(color: AppTheme.textMuted)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(obdConnectionStateProvider.notifier)
                      .updateState(ObdConnectionState.disconnected);
                  context.go('/search');
                },
                icon: const Icon(Icons.bluetooth_searching),
                label: const Text('RECONECTAR'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Card com animação própria ───────────────────────────────────────────────
// StatefulWidget: cada card gerencia seu próprio AnimationController.
// Apenas o Text do valor anima — o layout do card (label, unit) é estático.
class _DataCard extends StatefulWidget {
  final _MetricMeta meta;
  final double value;

  const _DataCard({required this.meta, required this.value});

  @override
  State<_DataCard> createState() => _DataCardState();
}

class _DataCardState extends State<_DataCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _animation = Tween<double>(begin: widget.value, end: widget.value)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(_DataCard old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // Anima do valor atual exibido até o novo valor.
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.value,
      ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _format(double v) => widget.meta.decimals == 0
      ? v.toInt().toString()
      : v.toStringAsFixed(widget.meta.decimals);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Rótulo — estático, não rebuilda durante a animação.
            Text(
              widget.meta.label.toUpperCase(),
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            // Apenas a Row com o valor anima a 60fps; o card em si não rebuilda.
            AnimatedBuilder(
              animation: _animation,
              builder: (_, _) => Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _format(_animation.value),
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Outfit',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      widget.meta.unit,
                      style: const TextStyle(
                        color: AppTheme.pulseRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
