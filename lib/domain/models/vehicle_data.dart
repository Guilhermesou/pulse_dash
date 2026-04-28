class VehicleData {
  final double speed;
  final double rpm;
  final double boost;
  final double temperature;
  final double batteryVoltage;
  final double engineLoad;
  final double fuelConsumption;

  VehicleData({
    required this.speed,
    required this.rpm,
    required this.boost,
    required this.temperature,
    required this.batteryVoltage,
    required this.engineLoad,
    required this.fuelConsumption,
  });

  VehicleData copyWith({
    double? speed,
    double? rpm,
    double? boost,
    double? temperature,
    double? batteryVoltage,
    double? engineLoad,
    double? fuelConsumption,
  }) {
    return VehicleData(
      speed: speed ?? this.speed,
      rpm: rpm ?? this.rpm,
      boost: boost ?? this.boost,
      temperature: temperature ?? this.temperature,
      batteryVoltage: batteryVoltage ?? this.batteryVoltage,
      engineLoad: engineLoad ?? this.engineLoad,
      fuelConsumption: fuelConsumption ?? this.fuelConsumption,
    );
  }
}
