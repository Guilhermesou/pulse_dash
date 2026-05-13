import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';
import '../../domain/models/vehicle_profile.dart';
import '../widgets/settings_components.dart';

class VehicleProfileScreen extends ConsumerWidget {
  const VehicleProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(vehicleProfileProvider);
    final notifier = ref.read(vehicleProfileProvider.notifier);

    void save(VehicleProfile updated) => notifier.update(updated);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'FICHA TÉCNICA',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        actions: [
          TextButton(
            onPressed: () => _confirmReset(context, ref),
            child: Text(
              'RESETAR',
              style: GoogleFonts.outfit(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // ── Buscar no banco de dados ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
            child: InkWell(
              onTap: () => context.push('/vehicle-search'),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.18),
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search,
                        color: Theme.of(context).colorScheme.primary,
                        size: 26),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buscar Veículo',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            'Pré-preencher com dados do banco de veículos',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: Theme.of(context).colorScheme.primary),
                  ],
                ),
              ),
            ),
          ),

          // ── Motor ─────────────────────────────────────────────────────────
          SettingsSection(
            title: 'Motor',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SettingsTile(
                      icon: Icons.code,
                      label: 'Código do Motor',
                      subtitle: profile.engineCode,
                      onTap: () => _editText(
                        context,
                        'Código do Motor',
                        profile.engineCode,
                        (v) => save(profile.copyWith(engineCode: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.straighten,
                      label: 'Cilindrada',
                      subtitle: '${profile.displacementCc} cc',
                      onTap: () => _editInt(
                        context,
                        'Cilindrada (cc)',
                        profile.displacementCc,
                        (v) => save(profile.copyWith(displacementCc: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.bolt,
                      label: 'Potência',
                      subtitle: '${profile.powerHp} cv @ ${profile.powerRpm} rpm',
                      onTap: () => _editPowerOrTorque(
                        context,
                        'Potência',
                        profile.powerHp,
                        profile.powerRpm,
                        'cv',
                        (val, rpm) => save(
                            profile.copyWith(powerHp: val, powerRpm: rpm)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.rotate_right,
                      label: 'Torque',
                      subtitle: '${profile.torqueNm} Nm @ ${profile.torqueRpm} rpm',
                      onTap: () => _editPowerOrTorque(
                        context,
                        'Torque',
                        profile.torqueNm,
                        profile.torqueRpm,
                        'Nm',
                        (val, rpm) => save(
                            profile.copyWith(torqueNm: val, torqueRpm: rpm)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.compress,
                      label: 'Compressão',
                      subtitle: '${profile.compressionRatio}:1',
                      onTap: () => _editDouble(
                        context,
                        'Taxa de Compressão',
                        profile.compressionRatio,
                        (v) => save(profile.copyWith(compressionRatio: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    _ToggleTileThemed(
                      icon: Icons.air,
                      label: 'Turbocompressor',
                      value: profile.turbocharged,
                      onChanged: (v) => save(profile.copyWith(turbocharged: v)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Câmbio ────────────────────────────────────────────────────────
          SettingsSection(
            title: 'Câmbio',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    SelectTile<String>(
                      icon: Icons.settings_input_component,
                      label: 'Tipo',
                      value: profile.transmissionType,
                      items: ['Manual', 'DSG', 'Automático']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          save(profile.copyWith(transmissionType: v)),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SelectTile<int>(
                      icon: Icons.numbers,
                      label: 'Nº de Marchas',
                      value: profile.gearCount,
                      items: [5, 6, 7, 8]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text('$e marchas')))
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        final current = List<double>.from(profile.gearRatios);
                        final defaults = VehicleProfile.defaults.gearRatios;
                        while (current.length < v) {
                          current.add(current.isNotEmpty
                              ? current.last * 0.85
                              : defaults[0]);
                        }
                        save(profile.copyWith(
                          gearCount: v,
                          gearRatios: current.take(v).toList(),
                        ));
                      },
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    // Relações de marcha dinâmicas
                    ...List.generate(profile.gearCount, (i) {
                      final gear = i + 1;
                      final ratio = i < profile.gearRatios.length
                          ? profile.gearRatios[i]
                          : 0.0;
                      return Column(
                        children: [
                          SettingsTile(
                            icon: _gearIcon(gear),
                            label: '$gearª Marcha',
                            subtitle: ratio.toStringAsFixed(3),
                            onTap: () => _editDouble(
                              context,
                              'Relação da $gearª Marcha',
                              ratio,
                              (v) {
                                final ratios =
                                    List<double>.from(profile.gearRatios);
                                if (i < ratios.length) {
                                  ratios[i] = v;
                                } else {
                                  ratios.add(v);
                                }
                                save(profile.copyWith(gearRatios: ratios));
                              },
                            ),
                          ),
                          if (i < profile.gearCount - 1)
                            const Divider(color: Colors.white10, height: 1),
                        ],
                      );
                    }),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.account_tree,
                      label: 'Relação Final (diferencial)',
                      subtitle: profile.finalDriveRatio.toStringAsFixed(3),
                      onTap: () => _editDouble(
                        context,
                        'Relação Final',
                        profile.finalDriveRatio,
                        (v) => save(profile.copyWith(finalDriveRatio: v)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Pneus & Rodas ─────────────────────────────────────────────────
          SettingsSection(
            title: 'Pneus & Rodas',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // Header com a especificação formatada
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      child: Row(
                        children: [
                          const Icon(Icons.circle_outlined,
                              color: AppTheme.textMuted, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            '${profile.tireWidth}/${profile.tireAspect} R${profile.wheelDiameterIn}',
                            style: GoogleFonts.outfit(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Circ. ${(profile.tireCircumferenceM * 100).toStringAsFixed(1)} cm',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.width_normal,
                      label: 'Largura',
                      subtitle: '${profile.tireWidth} mm',
                      onTap: () => _editInt(
                        context,
                        'Largura do Pneu (mm)',
                        profile.tireWidth,
                        (v) => save(profile.copyWith(tireWidth: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.height,
                      label: 'Perfil',
                      subtitle: '${profile.tireAspect}%',
                      onTap: () => _editInt(
                        context,
                        'Perfil do Pneu (%)',
                        profile.tireAspect,
                        (v) => save(profile.copyWith(tireAspect: v)),
                      ),
                    ),
                    const Divider(color: Colors.white10, height: 1),
                    SettingsTile(
                      icon: Icons.radio_button_unchecked,
                      label: 'Aro',
                      subtitle: '${profile.wheelDiameterIn}"',
                      onTap: () => _editInt(
                        context,
                        'Diâmetro do Aro (pol.)',
                        profile.wheelDiameterIn,
                        (v) => save(profile.copyWith(wheelDiameterIn: v)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // ── Tanque ────────────────────────────────────────────────────────
          SettingsSection(
            title: 'Combustível',
            children: [
              SettingsCard(
                padding: EdgeInsets.zero,
                child: SettingsTile(
                  icon: Icons.local_gas_station,
                  label: 'Capacidade do Tanque',
                  subtitle: '${profile.tankCapacityL} L',
                  onTap: () => _editInt(
                    context,
                    'Capacidade do Tanque (L)',
                    profile.tankCapacityL,
                    (v) => save(profile.copyWith(tankCapacityL: v)),
                  ),
                ),
              ),
            ],
          ),

          // ── Velocidade Teórica por Marcha ─────────────────────────────────
          SettingsSection(
            title: 'Velocidade Teórica (@ redline)',
            children: [
              SettingsCard(
                child: _SpeedTable(profile: profile, redlineRpm: profile.powerRpm.toDouble()),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  IconData _gearIcon(int gear) {
    const icons = [
      Icons.looks_one,
      Icons.looks_two,
      Icons.looks_3,
      Icons.looks_4,
      Icons.looks_5,
      Icons.looks_6,
    ];
    return gear <= icons.length ? icons[gear - 1] : Icons.filter_7;
  }

  // ─── Dialogs de edição ────────────────────────────────────────────────────

  Future<void> _editText(
    BuildContext context,
    String title,
    String current,
    ValueChanged<String> onSave,
  ) async {
    final ctrl = TextEditingController(text: current);
    final primary = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: title,
        primary: primary,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: _inputDecoration(primary),
        ),
        onSave: () => onSave(ctrl.text.trim()),
      ),
    );
    ctrl.dispose();
  }

  Future<void> _editInt(
    BuildContext context,
    String title,
    int current,
    ValueChanged<int> onSave,
  ) async {
    final ctrl = TextEditingController(text: current.toString());
    final primary = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: title,
        primary: primary,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: _inputDecoration(primary),
        ),
        onSave: () {
          final v = int.tryParse(ctrl.text.trim());
          if (v != null) onSave(v);
        },
      ),
    );
    ctrl.dispose();
  }

  Future<void> _editDouble(
    BuildContext context,
    String title,
    double current,
    ValueChanged<double> onSave,
  ) async {
    final ctrl =
        TextEditingController(text: current.toStringAsFixed(3));
    final primary = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: title,
        primary: primary,
        child: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: AppTheme.textLight),
          decoration: _inputDecoration(primary),
        ),
        onSave: () {
          final v = double.tryParse(ctrl.text.trim());
          if (v != null) onSave(v);
        },
      ),
    );
    ctrl.dispose();
  }

  Future<void> _editPowerOrTorque(
    BuildContext context,
    String title,
    int value,
    int rpm,
    String unit,
    void Function(int val, int rpm) onSave,
  ) async {
    final valCtrl = TextEditingController(text: value.toString());
    final rpmCtrl = TextEditingController(text: rpm.toString());
    final primary = Theme.of(context).colorScheme.primary;
    await showDialog<void>(
      context: context,
      builder: (ctx) => _EditDialog(
        title: title,
        primary: primary,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: valCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textLight),
              decoration:
                  _inputDecoration(primary).copyWith(labelText: unit),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: rpmCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: AppTheme.textLight),
              decoration:
                  _inputDecoration(primary).copyWith(labelText: 'RPM'),
            ),
          ],
        ),
        onSave: () {
          final v = int.tryParse(valCtrl.text.trim());
          final r = int.tryParse(rpmCtrl.text.trim());
          if (v != null && r != null) onSave(v, r);
        },
      ),
    );
    valCtrl.dispose();
    rpmCtrl.dispose();
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final primary = Theme.of(context).colorScheme.primary;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardGray,
        title: Text('Restaurar padrões',
            style: GoogleFonts.outfit(color: AppTheme.textLight)),
        content: const Text(
          'A ficha técnica voltará aos valores do Golf GTI MK7. Deseja continuar?',
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
            child:
                Text('RESTAURAR', style: TextStyle(color: primary)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref
          .read(vehicleProfileProvider.notifier)
          .update(VehicleProfile.defaults);
    }
  }

  InputDecoration _inputDecoration(Color primary) => InputDecoration(
        labelStyle: TextStyle(color: primary),
        enabledBorder: UnderlineInputBorder(
          borderSide:
              BorderSide(color: primary.withValues(alpha: 0.5)),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: primary),
        ),
      );
}

// ─── Dialog genérico de edição ───────────────────────────────────────────────

class _EditDialog extends StatelessWidget {
  final String title;
  final Color primary;
  final Widget child;
  final VoidCallback onSave;

  const _EditDialog({
    required this.title,
    required this.primary,
    required this.child,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.cardGray,
      title:
          Text(title, style: GoogleFonts.outfit(color: AppTheme.textLight)),
      content: child,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        TextButton(
          onPressed: () {
            onSave();
            Navigator.pop(context);
          },
          child: Text('SALVAR', style: TextStyle(color: primary)),
        ),
      ],
    );
  }
}

// ─── Toggle que usa o tema (sem AppTheme.pulseRed hardcoded) ─────────────────

class _ToggleTileThemed extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTileThemed({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ToggleTile(
      icon: icon,
      label: label,
      value: value,
      onChanged: onChanged,
    );
  }
}

// ─── Tabela de velocidade teórica por marcha ─────────────────────────────────

class _SpeedTable extends StatelessWidget {
  final VehicleProfile profile;
  final double redlineRpm;

  const _SpeedTable({required this.profile, required this.redlineRpm});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            'RPM usado: ${redlineRpm.toInt()}',
            style:
                GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12),
          ),
        ),
        ...List.generate(profile.gearCount, (i) {
          final gear = i + 1;
          final speed =
              profile.theoreticalSpeed(gear, redlineRpm);
          final ratio = i < profile.gearRatios.length
              ? profile.gearRatios[i]
              : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '$gearª',
                    style: GoogleFonts.outfit(
                      color: primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  ratio.toStringAsFixed(3),
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '${speed.toStringAsFixed(0)} km/h',
                  style: GoogleFonts.outfit(
                    color: AppTheme.textLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 4),
        Divider(color: primary.withValues(alpha: 0.2)),
        Row(
          children: [
            const Icon(Icons.info_outline,
                color: AppTheme.textMuted, size: 12),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Velocidades teóricas sem considerar derrapagem de embreagem ou limitações de ECU.',
                style: GoogleFonts.inter(
                    color: AppTheme.textMuted, fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
