import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/vehicle_profile.dart';

class StorageService {
  static const String _box = 'settings';

  static Future<void> init() async {
    await Hive.openBox(_box);
  }

  // ─── Dashboard style ───────────────────────────────────────────────────────

  static void saveDashboardStyle(DashboardStyle style) =>
      Hive.box(_box).put('dashboard_style', style.index);

  static DashboardStyle getDashboardStyle() {
    final index = Hive.box(_box)
        .get('dashboard_style', defaultValue: DashboardStyle.sporty.index);
    return DashboardStyle.values[index as int];
  }

  // ─── OBD connection state ─────────────────────────────────────────────────

  static void saveConnectionState(ObdConnectionState state) =>
      Hive.box(_box).put('connection_state', state.index);

  static ObdConnectionState getConnectionState() {
    final index = Hive.box(_box).get('connection_state',
        defaultValue: ObdConnectionState.disconnected.index);
    return ObdConnectionState.values[index as int];
  }

  // ─── Onboarding ───────────────────────────────────────────────────────────

  static bool isOnboardingComplete() =>
      Hive.box(_box).get('onboarding_complete', defaultValue: false) as bool;

  static void setOnboardingComplete() =>
      Hive.box(_box).put('onboarding_complete', true);

  // ─── App settings ─────────────────────────────────────────────────────────

  static AppSettings getAppSettings() {
    final b = Hive.box(_box);
    final d = AppSettings.defaults;
    return AppSettings(
      vehicleName:     b.get('vehicle_name',     defaultValue: d.vehicleName)     as String,
      fuelType:        b.get('fuel_type',         defaultValue: d.fuelType)        as String,
      weight:          b.get('weight',            defaultValue: d.weight)          as String,
      speedUnit:       b.get('speed_unit',        defaultValue: d.speedUnit)       as String,
      tempUnit:        b.get('temp_unit',         defaultValue: d.tempUnit)        as String,
      showRPM:         b.get('show_rpm',          defaultValue: d.showRPM)         as bool,
      showBoost:       b.get('show_boost',        defaultValue: d.showBoost)       as bool,
      showTemp:        b.get('show_temp',         defaultValue: d.showTemp)        as bool,
      showConsumption: b.get('show_consumption',  defaultValue: d.showConsumption) as bool,
      showBattery:     b.get('show_battery',      defaultValue: d.showBattery)     as bool,
      visualAlerts:    b.get('visual_alerts',     defaultValue: d.visualAlerts)    as bool,
      maxTemp:         b.get('max_temp',          defaultValue: d.maxTemp)         as String,
      maxRPM:          b.get('max_rpm',           defaultValue: d.maxRPM)          as String,
      maxBoost:        b.get('max_boost',         defaultValue: d.maxBoost)        as String,
      smartDiag:       b.get('smart_diag',        defaultValue: d.smartDiag)       as bool,
      devMode:         b.get('dev_mode',          defaultValue: d.devMode)         as bool,
      keepScreenOn:    b.get('keep_screen_on',    defaultValue: d.keepScreenOn)    as bool,
      autoConnect:     b.get('auto_connect',      defaultValue: d.autoConnect)     as bool,
      isManual:          b.get('is_manual',            defaultValue: d.isManual)          as bool,
      primaryColorIndex: b.get('primary_color_index', defaultValue: d.primaryColorIndex) as int,
    );
  }

  static void saveAppSettings(AppSettings s) {
    final b = Hive.box(_box);
    b.put('vehicle_name',    s.vehicleName);
    b.put('fuel_type',       s.fuelType);
    b.put('weight',          s.weight);
    b.put('speed_unit',      s.speedUnit);
    b.put('temp_unit',       s.tempUnit);
    b.put('show_rpm',        s.showRPM);
    b.put('show_boost',      s.showBoost);
    b.put('show_temp',       s.showTemp);
    b.put('show_consumption',s.showConsumption);
    b.put('show_battery',    s.showBattery);
    b.put('visual_alerts',   s.visualAlerts);
    b.put('max_temp',        s.maxTemp);
    b.put('max_rpm',         s.maxRPM);
    b.put('max_boost',       s.maxBoost);
    b.put('smart_diag',      s.smartDiag);
    b.put('dev_mode',        s.devMode);
    b.put('keep_screen_on',  s.keepScreenOn);
    b.put('auto_connect',    s.autoConnect);
    b.put('is_manual',           s.isManual);
    b.put('primary_color_index', s.primaryColorIndex);
  }

  // ─── Ficha técnica do veículo ─────────────────────────────────────────────

  static VehicleProfile getVehicleProfile() {
    final b = Hive.box(_box);
    final d = VehicleProfile.defaults;

    final rawRatios = b.get('vp_gear_ratios') as List?;
    final gearRatios = rawRatios != null
        ? rawRatios.map((e) => (e as num).toDouble()).toList()
        : d.gearRatios;

    return VehicleProfile(
      engineCode:       b.get('vp_engine_code',       defaultValue: d.engineCode)       as String,
      displacementCc:   b.get('vp_displacement_cc',   defaultValue: d.displacementCc)   as int,
      powerHp:          b.get('vp_power_hp',          defaultValue: d.powerHp)          as int,
      powerRpm:         b.get('vp_power_rpm',         defaultValue: d.powerRpm)         as int,
      torqueNm:         b.get('vp_torque_nm',         defaultValue: d.torqueNm)         as int,
      torqueRpm:        b.get('vp_torque_rpm',        defaultValue: d.torqueRpm)        as int,
      turbocharged:     b.get('vp_turbocharged',      defaultValue: d.turbocharged)     as bool,
      compressionRatio: b.get('vp_compression_ratio', defaultValue: d.compressionRatio) as double,
      transmissionType: b.get('vp_transmission_type', defaultValue: d.transmissionType) as String,
      gearCount:        b.get('vp_gear_count',        defaultValue: d.gearCount)        as int,
      gearRatios:       gearRatios,
      finalDriveRatio:  b.get('vp_final_drive_ratio', defaultValue: d.finalDriveRatio)  as double,
      tireWidth:        b.get('vp_tire_width',        defaultValue: d.tireWidth)        as int,
      tireAspect:       b.get('vp_tire_aspect',       defaultValue: d.tireAspect)       as int,
      wheelDiameterIn:  b.get('vp_wheel_diameter_in', defaultValue: d.wheelDiameterIn)  as int,
      tankCapacityL:    b.get('vp_tank_capacity_l',   defaultValue: d.tankCapacityL)    as int,
    );
  }

  static void saveVehicleProfile(VehicleProfile p) {
    final b = Hive.box(_box);
    b.put('vp_engine_code',       p.engineCode);
    b.put('vp_displacement_cc',   p.displacementCc);
    b.put('vp_power_hp',          p.powerHp);
    b.put('vp_power_rpm',         p.powerRpm);
    b.put('vp_torque_nm',         p.torqueNm);
    b.put('vp_torque_rpm',        p.torqueRpm);
    b.put('vp_turbocharged',      p.turbocharged);
    b.put('vp_compression_ratio', p.compressionRatio);
    b.put('vp_transmission_type', p.transmissionType);
    b.put('vp_gear_count',        p.gearCount);
    b.put('vp_gear_ratios',       p.gearRatios);
    b.put('vp_final_drive_ratio', p.finalDriveRatio);
    b.put('vp_tire_width',        p.tireWidth);
    b.put('vp_tire_aspect',       p.tireAspect);
    b.put('vp_wheel_diameter_in', p.wheelDiameterIn);
    b.put('vp_tank_capacity_l',   p.tankCapacityL);
  }
}
