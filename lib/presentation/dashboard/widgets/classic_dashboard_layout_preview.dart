import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../../../domain/models/vehicle_data.dart';
import 'classic_dashboard_layout.dart';
import 'sporty_dashboard_layout_preview.dart' show appThemeWrapper;

VehicleData _classicDriving() => VehicleData(
      speed: 87,
      rpm: 3100,
      boost: 0.4,
      temperature: 91,
      batteryVoltage: 14.0,
      engineLoad: 58,
      fuelConsumption: 8.5,
      throttlePosition: 38,
    );

VehicleData _classicIdle() => VehicleData(
      speed: 0,
      rpm: 820,
      boost: -0.6,
      temperature: 87,
      batteryVoltage: 14.2,
      engineLoad: 15,
      fuelConsumption: 0.8,
      throttlePosition: 0,
    );

@Preview(
  name: 'Classic — câmbio manual, em movimento',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget classicManualDriving() =>
    ClassicDashboardLayout(data: _classicDriving(), isManual: true);

@Preview(
  name: 'Classic — câmbio automático',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget classicAutoDriving() =>
    ClassicDashboardLayout(data: _classicDriving(), isManual: false);

@Preview(
  name: 'Classic — idle',
  size: Size(900, 500),
  wrapper: appThemeWrapper,
)
Widget classicIdle() =>
    ClassicDashboardLayout(data: _classicIdle(), isManual: true);
