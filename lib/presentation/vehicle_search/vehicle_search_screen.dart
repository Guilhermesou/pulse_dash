import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/vehicle_search_service.dart';
import '../../core/theme/app_theme.dart';
import '../../data/providers.dart';

class VehicleSearchScreen extends ConsumerStatefulWidget {
  const VehicleSearchScreen({super.key});

  @override
  ConsumerState<VehicleSearchScreen> createState() =>
      _VehicleSearchScreenState();
}

class _VehicleSearchScreenState extends ConsumerState<VehicleSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  List<VehicleSearchResult> _results = [];
  bool _loading = false;
  String? _error;
  bool _searched = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    _debounce?.cancel();
    if (_controller.text.trim().length < 2) {
      setState(() {
        _results = [];
        _searched = false;
        _error = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), _runSearch);
  }

  Future<void> _runSearch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await VehicleSearchService.search(_controller.text);
      if (mounted) {
        setState(() {
          _results = results;
          _searched = true;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao buscar. Verifique sua conexão.';
          _loading = false;
        });
      }
    }
  }

  void _applyResult(VehicleSearchResult result) {
    ref.read(vehicleProfileProvider.notifier).update(result.profile);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'BUSCAR VEÍCULO',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
      ),
      body: Column(
        children: [
          // ── Campo de busca ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(color: AppTheme.textLight, fontSize: 16),
              decoration: InputDecoration(
                hintText: 'Ex: Golf GTI MK7, Civic Type R, Onix Turbo…',
                hintStyle:
                    const TextStyle(color: AppTheme.textMuted, fontSize: 14),
                prefixIcon:
                    Icon(Icons.search, color: primary),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            color: AppTheme.textMuted),
                        onPressed: () {
                          _controller.clear();
                          _focusNode.requestFocus();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppTheme.cardGray,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 14, horizontal: 16),
              ),
            ),
          ),

          // ── Corpo ─────────────────────────────────────────────────────
          Expanded(
            child: _buildBody(primary),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(Color primary) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: primary));
    }

    if (_error != null) {
      return _Placeholder(
        icon: Icons.cloud_off,
        primary: primary,
        title: 'Sem conexão',
        subtitle: _error!,
      );
    }

    if (!_searched) {
      return _Placeholder(
        icon: Icons.directions_car_outlined,
        primary: primary,
        title: 'Busque seu veículo',
        subtitle:
            'Digite marca, modelo ou geração\npara pré-preencher a ficha técnica.',
      );
    }

    if (_results.isEmpty) {
      return _Placeholder(
        icon: Icons.search_off,
        primary: primary,
        title: 'Nenhum resultado',
        subtitle: 'Tente "Golf GTI", "Civic", "Onix Turbo"…\n'
            'Você ainda pode configurar manualmente.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _results.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Colors.white10, height: 1, indent: 16),
      itemBuilder: (_, i) => _ResultTile(
        result: _results[i],
        primary: primary,
        onTap: () => _applyResult(_results[i]),
      ),
    );
  }
}

// ─── Tile de resultado ───────────────────────────────────────────────────────

class _ResultTile extends StatelessWidget {
  final VehicleSearchResult result;
  final Color primary;
  final VoidCallback onTap;

  const _ResultTile({
    required this.result,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = result.profile;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            // ícone
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.directions_car, color: primary, size: 22),
            ),
            const SizedBox(width: 14),

            // texto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.displayName,
                    style: GoogleFonts.outfit(
                      color: AppTheme.textLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (result.trim != null) result.trim!,
                      result.yearRange,
                    ].join(' · '),
                    style: GoogleFonts.inter(
                        color: AppTheme.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    children: [
                      _Chip('${p.powerHp} cv'),
                      _Chip('${p.torqueNm} Nm'),
                      _Chip(p.transmissionType),
                      if (p.turbocharged) _Chip('Turbo', accent: primary),
                    ],
                  ),
                ],
              ),
            ),

            Icon(Icons.chevron_right, color: primary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color? accent;
  const _Chip(this.label, {this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (accent ?? AppTheme.textMuted).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: accent ?? AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ─── Estado vazio / erro ─────────────────────────────────────────────────────

class _Placeholder extends StatelessWidget {
  final IconData icon;
  final Color primary;
  final String title;
  final String subtitle;

  const _Placeholder({
    required this.icon,
    required this.primary,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: primary.withValues(alpha: 0.4)),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: AppTheme.textLight,
                fontWeight: FontWeight.w600,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                  color: AppTheme.textMuted, fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
