import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/models/vehicle_data.dart';
import 'sporty_dashboard_layout.dart';

// Wrapper top-level público exigido pela API de previews para injetar tema.
Widget appThemeWrapper(Widget child) => MaterialApp(
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      home: Scaffold(backgroundColor: AppTheme.backgroundBlack, body: child),
    );

VehicleData _driving() => VehicleData(
      speed: 112,
      rpm: 4200,
      boost: 0.9,
      temperature: 93,
      batteryVoltage: 14.1,
      engineLoad: 72,
      fuelConsumption: 11.3,
      throttlePosition: 55,
    );

VehicleData _idle() => VehicleData(
      speed: 0,
      rpm: 850,
      boost: -0.5,
      temperature: 88,
      batteryVoltage: 14.2,
      engineLoad: 18,
      fuelConsumption: 0.9,
      throttlePosition: 0,
    );

VehicleData _redline() => VehicleData(
      speed: 178,
      rpm: 6800,
      boost: 1.4,
      temperature: 101,
      batteryVoltage: 13.8,
      engineLoad: 95,
      fuelConsumption: 22.0,
      throttlePosition: 98,
    );

@Preview(
  name: 'Sporty — câmbio manual, em movimento',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget sportyManualDriving() =>
    SportyDashboardLayout(data: _driving(), isManual: true);

@Preview(
  name: 'Sporty — câmbio automático (sem marcha)',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget sportyAutoDriving() =>
    SportyDashboardLayout(data: _driving(), isManual: false);

@Preview(
  name: 'Sporty — idle',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget sportyIdle() =>
    SportyDashboardLayout(data: _idle(), isManual: true);

@Preview(
  name: 'Sporty — zona vermelha',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget sportyRedline() =>
    SportyDashboardLayout(data: _redline(), isManual: true);

@Preview(name: 'GearBadge — 1ª marcha', wrapper: appThemeWrapper)
Widget gearBadge1() => const Center(child: GearBadge(gear: 1));

@Preview(name: 'GearBadge — 3ª marcha', wrapper: appThemeWrapper)
Widget gearBadge3() => const Center(child: GearBadge(gear: 3));

@Preview(name: 'GearBadge — 6ª marcha', wrapper: appThemeWrapper)
Widget gearBadge6() => const Center(child: GearBadge(gear: 6));

@Preview(name: 'GearBadge — neutro', wrapper: appThemeWrapper)
Widget gearBadgeNeutral() => const Center(child: GearBadge(gear: null));
