class VehicleData {
  final double speed;
  final double rpm;
  final double boost;
  final double temperature;
  final double batteryVoltage;
  final double engineLoad;
  final double fuelConsumption;
  final double throttlePosition;

  VehicleData({
    required this.speed,
    required this.rpm,
    required this.boost,
    required this.temperature,
    required this.batteryVoltage,
    required this.engineLoad,
    required this.fuelConsumption,
    this.throttlePosition = 0,
  });

  // Estimativa da marcha baseada na razão RPM/velocidade (referência GTI MK7 DSG).
  // Retorna null quando velocidade < 3 km/h (difícil determinar).
  int? get estimatedGear {
    if (speed < 3) return null;
    final ratio = rpm / speed;
    if (ratio > 110) return 1;
    if (ratio > 60) return 2;
    if (ratio > 43) return 3;
    if (ratio > 32) return 4;
    if (ratio > 25) return 5;
    return 6;
  }

  VehicleData copyWith({
    double? speed,
    double? rpm,
    double? boost,
    double? temperature,
    double? batteryVoltage,
    double? engineLoad,
    double? fuelConsumption,
    double? throttlePosition,
  }) {
    return VehicleData(
      speed: speed ?? this.speed,
      rpm: rpm ?? this.rpm,
      boost: boost ?? this.boost,
      temperature: temperature ?? this.temperature,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      engineLoad: engineLoad ?? this.engineLoad,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
      throttlePosition: throttlePosition ?? this.throttlePosition,
    );
  }
}
