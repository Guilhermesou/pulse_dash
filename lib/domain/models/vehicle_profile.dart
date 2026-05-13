import 'dart:math' as math;

class VehicleProfile {
  // ─── Motor ──────────────────────────────────────────────────────────────────
  final String engineCode;
  final int displacementCc;
  final int powerHp;
  final int powerRpm;
  final int torqueNm;
  final int torqueRpm;
  final bool turbocharged;
  final double compressionRatio;

  // ─── Câmbio ─────────────────────────────────────────────────────────────────
  final String transmissionType; // 'Manual', 'DSG', 'Automático'
  final int gearCount;
  final List<double> gearRatios; // índice 0 = 1ª marcha
  final double finalDriveRatio;

  // ─── Pneus & Rodas ───────────────────────────────────────────────────────────
  final int tireWidth;       // mm (ex: 225)
  final int tireAspect;      // % (ex: 45)
  final int wheelDiameterIn; // polegadas (ex: 17)

  // ─── Combustível ────────────────────────────────────────────────────────────
  final int tankCapacityL;

  const VehicleProfile({
    required this.engineCode,
    required this.displacementCc,
    required this.powerHp,
    required this.powerRpm,
    required this.torqueNm,
    required this.torqueRpm,
    required this.turbocharged,
    required this.compressionRatio,
    required this.transmissionType,
    required this.gearCount,
    required this.gearRatios,
    required this.finalDriveRatio,
    required this.tireWidth,
    required this.tireAspect,
    required this.wheelDiameterIn,
    required this.tankCapacityL,
  });

  // Defaults: Golf GTI MK7 (EA888 Gen3 220cv, manual 6v)
  static final defaults = VehicleProfile(
    engineCode: 'EA888 Gen3',
    displacementCc: 1984,
    powerHp: 220,
    powerRpm: 4700,
    torqueNm: 350,
    torqueRpm: 1500,
    turbocharged: true,
    compressionRatio: 9.6,
    transmissionType: 'Manual',
    gearCount: 6,
    gearRatios: [3.769, 2.050, 1.345, 0.976, 0.778, 0.643],
    finalDriveRatio: 3.94,
    tireWidth: 225,
    tireAspect: 45,
    wheelDiameterIn: 17,
    tankCapacityL: 55,
  );

  // ─── Cálculo de velocidade teórica ──────────────────────────────────────────

  /// Circunferência externa do pneu em metros.
  double get tireCircumferenceM {
    final sidewallMm = tireWidth * tireAspect / 100;
    final rimMm = wheelDiameterIn * 25.4;
    final diameterMm = rimMm + 2 * sidewallMm;
    return diameterMm * math.pi / 1000;
  }

  /// Velocidade teórica em km/h para um dado RPM e marcha (1-based).
  double theoreticalSpeed(int gear, double rpm) {
    if (gear < 1 || gear > gearRatios.length) return 0;
    final totalRatio = gearRatios[gear - 1] * finalDriveRatio;
    return (rpm / totalRatio) * tireCircumferenceM * 60 / 1000;
  }

  // ─── copyWith ────────────────────────────────────────────────────────────────

  VehicleProfile copyWith({
    String? engineCode,
    int? displacementCc,
    int? powerHp,
    int? powerRpm,
    int? torqueNm,
    int? torqueRpm,
    bool? turbocharged,
    double? compressionRatio,
    String? transmissionType,
    int? gearCount,
    List<double>? gearRatios,
    double? finalDriveRatio,
    int? tireWidth,
    int? tireAspect,
    int? wheelDiameterIn,
    int? tankCapacityL,
  }) {
    return VehicleProfile(
      engineCode: engineCode ?? this.engineCode,
      displacementCc: displacementCc ?? this.displacementCc,
      powerHp: powerHp ?? this.powerHp,
      powerRpm: powerRpm ?? this.powerRpm,
      torqueNm: torqueNm ?? this.torqueNm,
      torqueRpm: torqueRpm ?? this.torqueRpm,
      turbocharged: turbocharged ?? this.turbocharged,
      compressionRatio: compressionRatio ?? this.compressionRatio,
      transmissionType: transmissionType ?? this.transmissionType,
      gearCount: gearCount ?? this.gearCount,
      gearRatios: gearRatios ?? this.gearRatios,
      finalDriveRatio: finalDriveRatio ?? this.finalDriveRatio,
      tireWidth: tireWidth ?? this.tireWidth,
      tireAspect: tireAspect ?? this.tireAspect,
      wheelDiameterIn: wheelDiameterIn ?? this.wheelDiameterIn,
      tankCapacityL: tankCapacityL ?? this.tankCapacityL,
    );
  }
}
