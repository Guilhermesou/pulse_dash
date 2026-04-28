import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/models/app_state.dart';
import '../../domain/models/app_settings.dart';

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
  }
}
