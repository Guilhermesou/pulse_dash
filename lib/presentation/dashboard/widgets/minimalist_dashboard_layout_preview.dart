import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../domain/models/vehicle_data.dart';
import 'minimalist_dashboard_layout.dart';
import 'sporty_dashboard_layout_preview.dart' show appThemeWrapper;

VehicleData _minimalistDriving() => VehicleData(
      speed: 63,
      rpm: 2400,
      boost: 0.2,
      temperature: 90,
      batteryVoltage: 14.1,
      engineLoad: 42,
      fuelConsumption: 7.1,
      throttlePosition: 28,
    );

VehicleData _minimalistHighRpm() => VehicleData(
      speed: 201,
      rpm: 6200,
      boost: 1.3,
      temperature: 98,
      batteryVoltage: 13.9,
      engineLoad: 90,
      fuelConsumption: 19.4,
      throttlePosition: 92,
    );

@Preview(
  name: 'Minimalist — câmbio manual, cruzeiro',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget minimalistManualCruise() =>
    MinimalistDashboardLayout(data: _minimalistDriving(), isManual: true);

@Preview(
  name: 'Minimalist — câmbio automático',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget minimalistAuto() =>
    MinimalistDashboardLayout(data: _minimalistDriving(), isManual: false);

@Preview(
  name: 'Minimalist — RPM alto',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget minimalistHighRpm() =>
    MinimalistDashboardLayout(data: _minimalistHighRpm(), isManual: true);
