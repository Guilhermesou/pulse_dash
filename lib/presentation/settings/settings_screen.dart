import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/app_state.dart';
import '../widgets/settings_components.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final connectionState = ref.watch(obdConnectionStateProvider);
    final currentStyle = ref.watch(dashboardStyleProvider);

    void save(AppSettings updated) => notifier.update(updated);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CONFIGURAÇÕES',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Conexão OBD ─────────────────────────────────────────────────
          SettingsSection(
            title: 'Conexão OBD',
            children: [
              SettingsCard(
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.bluetooth,
                      label: 'V-LINK OBDII',
                      subtitle: connectionState == ObdConnectionState.connected
                          ? 'Status: Conectado'
                          : 'Status: Desconectado',
                      trailing: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: connectionState == ObdConnectionState.connected
                              ? Colors.green
                              : Colors.red,
                          boxShadow: [
                            if (connectionState == ObdConnectionState.connected)
                              const BoxShadow(
                                color: Colors.green,
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: AppTheme.pulseRed),
                                foregroundColor: AppTheme.pulseRed,
                              ),
                              child: const Text('Reconectar'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Trocar'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Veículo ───────────────────────────────────────────────────────
          SettingsSection(
            title: 'Veículo',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.directions_car,
                      label: 'Nome do Veículo',
                      subtitle: settings.vehicleName,
                      onTap: () => _editText(
                        context,
                        'Nome do Veículo',
                        settings.vehicleName,
                        (v) => save(settings.copyWith(vehicleName: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SelectTile<String>(
                      icon: Icons.local_gas_station,
                      label: 'Combustível',
                      value: settings.fuelType,
                      items: ['Gasolina', 'Etanol', 'Diesel', 'Flex']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => save(settings.copyWith(fuelType: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.settings_input_component,
                      label: 'Câmbio manual',
                      value: settings.isManual,
                      onChanged: (v) => save(settings.copyWith(isManual: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.monitor_weight,
                      label: 'Peso (kg)',
                      subtitle: '${settings.weight} kg',
                      onTap: () => _editText(
                        context,
                        'Peso do Veículo',
                        settings.weight,
                        (v) => save(settings.copyWith(weight: v)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Aparência ────────────────────────────────────────────────────
          SettingsSection(
            title: 'Aparência',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SelectTile<DashboardStyle>(
                      icon: Icons.palette,
                      label: 'Tema',
                      value: currentStyle,
                      items: const [
                        DropdownMenuItem(
                            value: DashboardStyle.sporty,
                            child: Text('Esportivo')),
                        DropdownMenuItem(
                            value: DashboardStyle.minimalist,
                            child: Text('Minimalista')),
                        DropdownMenuItem(
                            value: DashboardStyle.classic,
                            child: Text('Clássico')),
                      ],
                      onChanged: (v) =>
                          ref.read(dashboardStyleProvider.notifier).setStyle(v!),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SelectTile<String>(
                      icon: Icons.straighten,
                      label: 'Unidade de Velocidade',
                      value: settings.speedUnit,
                      items: ['km/h', 'mph']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => save(settings.copyWith(speedUnit: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SelectTile<String>(
                      icon: Icons.thermostat,
                      label: 'Unidade de Temp.',
                      value: settings.tempUnit,
                      items: ['°C', '°F']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => save(settings.copyWith(tempUnit: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Dados do Painel ───────────────────────────────────────────────
          SettingsSection(
            title: 'Dados do Painel',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ToggleTile(
                      icon: Icons.speed,
                      label: 'Mostrar RPM',
                      value: settings.showRPM,
                      onChanged: (v) => save(settings.copyWith(showRPM: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.compress,
                      label: 'Mostrar Boost',
                      value: settings.showBoost,
                      onChanged: (v) => save(settings.copyWith(showBoost: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.thermostat,
                      label: 'Mostrar Temperatura',
                      value: settings.showTemp,
                      onChanged: (v) => save(settings.copyWith(showTemp: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.ev_station,
                      label: 'Mostrar Consumo',
                      value: settings.showConsumption,
                      onChanged: (v) =>
                          save(settings.copyWith(showConsumption: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.battery_charging_full,
                      label: 'Tensão da Bateria',
                      value: settings.showBattery,
                      onChanged: (v) => save(settings.copyWith(showBattery: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Calibração ───────────────────────────────────────────────────
          SettingsSection(
            title: 'Calibração',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.settings_input_component,
                      label: 'Calibrar marchas',
                      onTap: () {},
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.tune,
                      label: 'Ajustar turbo (offset)',
                      onTap: () {},
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.analytics,
                      label: 'Ajustar consumo',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Alertas ───────────────────────────────────────────────────────
          SettingsSection(
            title: 'Alertas',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.warning_amber,
                      label: 'Temperatura máxima',
                      subtitle: '${settings.maxTemp} °C',
                      onTap: () => _editText(
                        context,
                        'Temp Máxima',
                        settings.maxTemp,
                        (v) => save(settings.copyWith(maxTemp: v)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.error_outline,
                      label: 'RPM máximo',
                      subtitle: '${settings.maxRPM} RPM',
                      onTap: () => _editText(
                        context,
                        'RPM Máximo',
                        settings.maxRPM,
                        (v) => save(settings.copyWith(maxRPM: v)),
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.shutter_speed,
                      label: 'Boost máximo',
                      subtitle: '${settings.maxBoost} bar',
                      onTap: () => _editText(
                        context,
                        'Boost Máximo',
                        settings.maxBoost,
                        (v) => save(settings.copyWith(maxBoost: v)),
                        keyboardType: TextInputType.numberWithOptions(
                            decimal: true),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.visibility,
                      label: 'Ativar alertas visuais',
                      value: settings.visualAlerts,
                      onChanged: (v) =>
                          save(settings.copyWith(visualAlerts: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Diagnóstico ───────────────────────────────────────────────────
          SettingsSection(
            title: 'Diagnóstico',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ToggleTile(
                      icon: Icons.psychology,
                      label: 'Diagnóstico inteligente',
                      value: settings.smartDiag,
                      onChanged: (v) => save(settings.copyWith(smartDiag: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.data_object,
                      label: 'Ver dados brutos',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Avançado ─────────────────────────────────────────────────────
          SettingsSection(
            title: 'Avançado',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ToggleTile(
                      icon: Icons.developer_mode,
                      label: 'Modo desenvolvedor',
                      value: settings.devMode,
                      onChanged: (v) => save(settings.copyWith(devMode: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.history,
                      label: 'Logs de conexão',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Sistema ───────────────────────────────────────────────────────
          SettingsSection(
            title: 'Sistema',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    ToggleTile(
                      icon: Icons.screen_lock_rotation,
                      label: 'Manter tela ligada',
                      value: settings.keepScreenOn,
                      onChanged: (v) =>
                          save(settings.copyWith(keepScreenOn: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    ToggleTile(
                      icon: Icons.autorenew,
                      label: 'Conectar automaticamente',
                      value: settings.autoConnect,
                      onChanged: (v) => save(settings.copyWith(autoConnect: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.restore,
                      label: 'Restaurar padrões',
                      onTap: () => _confirmReset(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 40),
          Center(
            child: Text(
              'GTI Dash v1.0.0',
              style: GoogleFonts.inter(
                  color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Future<void> _editText(
    BuildContext context,
    String title,
    String current,
    ValueChanged<String> onSave, {
    TextInputType? keyboardType,
  }) async {
    final controller = TextEditingController(text: current);
    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: AppTheme.cardGray,
          title: Text(title,
              style: GoogleFonts.outfit(color: AppTheme.textLight)),
          content: TextField(
            controller: controller,
            keyboardType: keyboardType,
            autofocus: false,
            style: const TextStyle(color: AppTheme.textLight),
            decoration: InputDecoration(
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color: AppTheme.pulseRed.withValues(alpha: 0.5)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppTheme.pulseRed),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('CANCELAR',
                  style: TextStyle(color: AppTheme.textMuted)),
            ),
            TextButton(
              onPressed: () {
                onSave(controller.text.trim());
                Navigator.pop(dialogContext);
              },
              child: const Text('SALVAR',
                  style: TextStyle(color: AppTheme.pulseRed)),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardGray,
        title: Text('Restaurar padrões',
            style: GoogleFonts.outfit(color: AppTheme.textLight)),
        content: const Text(
          'Todas as configurações voltarão aos valores originais. Deseja continuar?',
          style: TextStyle(color: AppTheme.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('CANCELAR',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('RESTAURAR',
                style: TextStyle(color: AppTheme.pulseRed)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(appSettingsProvider.notifier).update(AppSettings.defaults);
    }
  }
}
