import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/bluetooth_service.dart';
import '../../data/providers.dart';

class SearchDeviceScreen extends ConsumerStatefulWidget {
  const SearchDeviceScreen({super.key});

  @override
  ConsumerState<SearchDeviceScreen> createState() => _SearchDeviceScreenState();
}

class _SearchDeviceScreenState extends ConsumerState<SearchDeviceScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isInitializing = true;
  String? _error;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initAndScan();
  }

  Future<void> _initAndScan() async {
    final btService = ref.read(bluetoothServiceProvider);

    // 1. Android: solicita permissões em runtime.
    //    iOS: CoreBluetooth exibe o diálogo automaticamente no próximo passo.
    final granted = await btService.requestPermissions();
    if (!granted) {
      if (mounted) {
        setState(() {
          _error = 'Permissões de Bluetooth necessárias.\nAcesse as configurações do sistema.';
          _isInitializing = false;
        });
      }
      return;
    }

    // 2. Lê o estado do adapter — no iOS esta chamada inicializa o CoreBluetooth
    //    e exibe o diálogo de permissão de Bluetooth (se ainda não determinado).
    final state = await btService.getAdapterState();
    if (!mounted) return;

    if (state == BluetoothAdapterState.unauthorized) {
      setState(() {
        _error = 'Acesso ao Bluetooth negado.\nPermita nas configurações do sistema.';
        _isInitializing = false;
      });
      return;
    }

    if (state != BluetoothAdapterState.on) {
      setState(() {
        _error = 'Bluetooth está desligado.\nLigue o Bluetooth para continuar.';
        _isInitializing = false;
      });
      return;
    }

    // 3. Inicia o scan
    setState(() => _isInitializing = false);
    await btService.startScan();
    if (mounted) _pulseController.stop();
  }

  @override
  void dispose() {
    ref.read(bluetoothServiceProvider).stopScan();
    _pulseController.dispose();
    super.dispose();
  }

  void _onDeviceTap(BluetoothDeviceInfo device) {
    ref.read(bluetoothServiceProvider).stopScan();
    context.go('/connecting?address=${Uri.encodeComponent(device.address)}');
  }

  void _retry() {
    setState(() {
      _error = null;
      _isInitializing = true;
    });
    _pulseController.repeat(reverse: true);
    _initAndScan();
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(bluetoothDevicesProvider);
    final btService = ref.watch(bluetoothServiceProvider);
    final isActive = btService.isScanning || _isInitializing;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos Bluetooth'),
        actions: [
          if (!_isInitializing && _error == null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retry,
              tooltip: 'Buscar novamente',
            ),
        ],
      ),
      // SafeArea(top: false) cuida das laterais com notch em landscape.
      // A AppBar já tratou o topo.
      body: SafeArea(
        top: false,
        child: _error != null
            ? _buildError()
            : Row(
                children: [
                  // ─── Esquerda: ícone + status ───────────────────────────
                  SizedBox(
                    width: 160,
                    child: _buildIconPanel(isActive),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  // ─── Direita: lista ─────────────────────────────────────
                  Expanded(
                    child: devicesAsync.when(
                      data: (devices) => _buildDeviceList(devices),
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.pulseRed),
                      ),
                      error: (err, _) => Center(
                        child: Text('Erro: $err',
                            style:
                                const TextStyle(color: AppTheme.pulseRed)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildIconPanel(bool isActive) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 72,
          height: 72,
          child: isActive
              ? ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.pulseRed.withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.bluetooth_searching,
                        size: 36, color: AppTheme.pulseRed),
                  ),
                )
              : Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.textMuted.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.bluetooth_connected,
                      size: 36, color: AppTheme.textMuted),
                ),
        ),
        const SizedBox(height: 14),
        Text(
          isActive ? 'Procurando...' : 'Pronto',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            isActive
                ? 'Mantenha o ELM327\nligado e próximo'
                : 'Toque no dispositivo\npara conectar',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ),
        if (isActive) ...[
          const SizedBox(height: 16),
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.pulseRed,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildError() {
    return Row(
      children: [
        // Ícone de erro à esquerda
        SizedBox(
          width: 160,
          child: Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.pulseRed.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.bluetooth_disabled,
                  size: 48, color: AppTheme.pulseRed),
            ),
          ),
        ),
        const VerticalDivider(width: 1, thickness: 1),
        // Mensagem e botão à direita
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _error!,
                    style: const TextStyle(
                        color: AppTheme.textMuted, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _retry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('TENTAR NOVAMENTE'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList(List<BluetoothDeviceInfo> devices) {
    // Filtra: por padrão mostra só adaptadores OBD; _showAll exibe tudo.
    final visible = _showAll
        ? devices
        : devices.where((d) => d.isObdDevice).toList();

    if (visible.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.bluetooth_searching,
                size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              devices.isEmpty
                  ? 'Nenhum dispositivo encontrado.'
                  : 'Nenhum adaptador OBD2 encontrado.',
              style: const TextStyle(
                  color: AppTheme.textMuted, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Certifique-se de que o ELM327 está ligado.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            if (devices.isNotEmpty) ...[
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: () => setState(() => _showAll = true),
                icon: const Icon(Icons.list, size: 18),
                label: Text(
                    'Mostrar todos os ${devices.length} dispositivos encontrados'),
              ),
            ],
          ],
        ),
      );
    }

    final sorted = List<BluetoothDeviceInfo>.from(visible)
      ..sort((a, b) {
        if (a.isObdDevice != b.isObdDevice) return a.isObdDevice ? -1 : 1;
        if (a.isBonded != b.isBonded) return a.isBonded ? -1 : 1;
        return a.name.compareTo(b.name);
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: sorted.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
      itemBuilder: (context, index) {
        final device = sorted[index];
        return _DeviceTile(device: device, onTap: () => _onDeviceTap(device));
      },
    );
  }
}

// ─── Tile de dispositivo ──────────────────────────────────────────────────────

class _DeviceTile extends StatelessWidget {
  final BluetoothDeviceInfo device;
  final VoidCallback onTap;

  const _DeviceTile({required this.device, required this.onTap});

  String _signalLabel(int? rssi) {
    if (rssi == null) return '';
    if (rssi >= -60) return '●●●';
    if (rssi >= -75) return '●●○';
    return '●○○';
  }

  @override
  Widget build(BuildContext context) {
    final isObd = device.isObdDevice;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ─── Ícone ───────────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isObd ? AppTheme.pulseRed : AppTheme.textMuted)
                    .withValues(alpha: 0.12),
              ),
              child: Icon(
                isObd ? Icons.directions_car : Icons.bluetooth,
                size: 22,
                color: isObd ? AppTheme.pulseRed : AppTheme.textMuted,
              ),
            ),
            const SizedBox(width: 14),

            // ─── Nome + sinal ─────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    device.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (device.rssi != null) ...[
                        Text(
                          _signalLabel(device.rssi),
                          style: TextStyle(
                            fontSize: 10,
                            color: device.rssi! >= -75
                                ? Colors.green
                                : Colors.orange,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${device.rssi} dBm',
                          style: const TextStyle(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                        if (device.isBonded) ...[
                          const SizedBox(width: 6),
                          const Text('·',
                              style: TextStyle(color: AppTheme.textMuted)),
                          const SizedBox(width: 6),
                        ],
                      ],
                      if (device.isBonded)
                        const Text('Pareado',
                            style: TextStyle(
                                color: AppTheme.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Badge OBD ou seta ────────────────────────────────────────
            if (isObd)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.pulseRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'OBD',
                  style: TextStyle(
                    color: AppTheme.pulseRed,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              )
            else
              const Icon(Icons.chevron_right, color: AppTheme.textMuted),
          ],
        ),
      ),
    );
  }
}
