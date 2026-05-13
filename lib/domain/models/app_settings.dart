class AppSettings {
  final String vehicleName;
  final String fuelType;
  final String weight;
  final String speedUnit;
  final String tempUnit;
  final bool showRPM;
  final bool showBoost;
  final bool showTemp;
  final bool showConsumption;
  final bool showBattery;
  final bool visualAlerts;
  final String maxTemp;
  final String maxRPM;
  final String maxBoost;
  final bool smartDiag;
  final bool devMode;
  final bool keepScreenOn;
  final bool autoConnect;
  final bool isManual;
  final int primaryColorIndex;

  const AppSettings({
    required this.vehicleName,
    required this.fuelType,
    required this.weight,
    required this.speedUnit,
    required this.tempUnit,
    required this.showRPM,
    required this.showBoost,
    required this.showTemp,
    required this.showConsumption,
    required this.showBattery,
    required this.visualAlerts,
    required this.maxTemp,
    required this.maxRPM,
    required this.maxBoost,
    required this.smartDiag,
    required this.devMode,
    required this.keepScreenOn,
    required this.autoConnect,
    this.isManual = false,
    this.primaryColorIndex = 0,
  });

  static const defaults = AppSettings(
    vehicleName: 'VW Golf GTI MK7',
    fuelType: 'Gasolina',
    weight: '1350',
    speedUnit: 'km/h',
    tempUnit: '°C',
    showRPM: true,
    showBoost: true,
    showTemp: true,
    showConsumption: true,
    showBattery: true,
    visualAlerts: true,
    maxTemp: '105',
    maxRPM: '6500',
    maxBoost: '1.5',
    smartDiag: true,
    devMode: false,
    keepScreenOn: true,
    autoConnect: true,
    isManual: false,
    primaryColorIndex: 0,
  );

  AppSettings copyWith({
    String? vehicleName,
    String? fuelType,
    String? weight,
    String? speedUnit,
    String? tempUnit,
    bool? showRPM,
    bool? showBoost,
    bool? showTemp,
    bool? showConsumption,
    bool? showBattery,
    bool? visualAlerts,
    String? maxTemp,
    String? maxRPM,
    String? maxBoost,
    bool? smartDiag,
    bool? devMode,
    bool? keepScreenOn,
    bool? autoConnect,
    bool? isManual,
    int? primaryColorIndex,
  }) {
    return AppSettings(
      vehicleName: vehicleName ?? this.vehicleName,
      fuelType: fuelType ?? this.fuelType,
      weight: weight ?? this.weight,
      speedUnit: speedUnit ?? this.speedUnit,
      tempUnit: tempUnit ?? this.tempUnit,
      showRPM: showRPM ?? this.showRPM,
      showBoost: showBoost ?? this.showBoost,
      showTemp: showTemp ?? this.showTemp,
      showConsumption: showConsumption ?? this.showConsumption,
      showBattery: showBattery ?? this.showBattery,
      visualAlerts: visualAlerts ?? this.visualAlerts,
      maxTemp: maxTemp ?? this.maxTemp,
      maxRPM: maxRPM ?? this.maxRPM,
      maxBoost: maxBoost ?? this.maxBoost,
      smartDiag: smartDiag ?? this.smartDiag,
      devMode: devMode ?? this.devMode,
      keepScreenOn: keepScreenOn ?? this.keepScreenOn,
      autoConnect: autoConnect ?? this.autoConnect,
      isManual: isManual ?? this.isManual,
      primaryColorIndex: primaryColorIndex ?? this.primaryColorIndex,
    );
  }
}
