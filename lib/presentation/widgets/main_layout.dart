import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

class MainLayout extends StatelessWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;

    return Scaffold(
      backgroundColor: AppTheme.backgroundBlack,
      body: Column(
        children: [
          Expanded(child: child),

          // Navigation Bar
          Container(
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D0D),
              border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(context, Icons.speed, 'PAINEL', '/dashboard',
                      location == '/dashboard'),
                  _buildVerticalSeparator(),
                  _buildNavItem(context, Icons.bar_chart, 'DADOS', '/live-data',
                      location == '/live-data'),
                  _buildVerticalSeparator(),
                  _buildNavItem(context, Icons.warning_amber, 'ERROS',
                      '/diagnostics', location == '/diagnostics'),
                  _buildVerticalSeparator(),
                  _buildNavItem(
                      context, Icons.map, 'MAPA', '/map', location == '/map'),
                  _buildVerticalSeparator(),
                  _buildNavItem(
                      context, Icons.settings, 'CONFIG.', '/settings', false),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalSeparator() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withValues(alpha: 0.05),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
      String route, bool isActive) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (route == '/settings') {
            context.push(route);
          } else {
            context.go(route);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppTheme.pulseRed.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: isActive
                    ? AppTheme.pulseRed
                    : Colors.white.withValues(alpha: 0.4),
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
                fontSize: 10,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
                letterSpacing: 1.0,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            if (isActive) ...[
              const SizedBox(height: 4),
              Container(
                width: 30,
                height: 2,
                color: AppTheme.pulseRed,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
