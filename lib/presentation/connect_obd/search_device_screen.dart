import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class SearchDeviceScreen extends StatefulWidget {
  const SearchDeviceScreen({super.key});

  @override
  State<SearchDeviceScreen> createState() => _SearchDeviceScreenState();
}

class _SearchDeviceScreenState extends State<SearchDeviceScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isSearching = true;

  final List<Map<String, String>> _mockDevices = [
    {'name': 'OBDII', 'mac': '00:1D:A5:00:11:22', 'signal': 'Excelente'},
    {'name': 'ELM327 v1.5', 'mac': '11:22:33:44:55:66', 'signal': 'Bom'},
    {'name': 'V-LINK', 'mac': 'AA:BB:CC:DD:EE:FF', 'signal': 'Fraco'},
  ];

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

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        _pulseController.stop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos'),
      ),
      body: Column(
        children: [
          Flexible(
            flex: 2,
            child: Container(
              alignment: Alignment.center,
              child: _isSearching
                  ? ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.pulseRed.withValues(alpha: 0.2),
                        ),
                        child: const Icon(Icons.bluetooth_searching, size: 48, color: AppTheme.pulseRed),
                      ),
                    )
                  : const Icon(Icons.bluetooth, size: 64, color: AppTheme.textMuted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _isSearching ? 'Procurando dispositivos...' : 'Selecione um dispositivo',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: AppTheme.pulseRed))
                : ListView.builder(
                    itemCount: _mockDevices.length,
                    itemBuilder: (context, index) {
                      final device = _mockDevices[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ListTile(
                          leading: const Icon(Icons.bluetooth_drive, color: AppTheme.pulseRed),
                          title: Text(device['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('MAC: ${device['mac']} \nSinal: ${device['signal']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            context.go('/connecting');
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
