import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/obd_repository.dart';
import 'mocks/mock_obd_repository.dart';
import '../domain/models/vehicle_data.dart';
import '../domain/models/diagnostic_code.dart';
import '../domain/models/app_state.dart';
import '../domain/models/app_settings.dart';
import '../core/storage/storage_service.dart';

// Provider for the repository
final obdRepositoryProvider = Provider<ObdRepository>((ref) {
  return MockObdRepository();
});

// Provider for live vehicle data stream
final vehicleDataProvider = StreamProvider<VehicleData>((ref) {
  final repository = ref.watch(obdRepositoryProvider);
  return repository.getLiveData();
});

// Provider for diagnostic errors
final diagnosticErrorsProvider = FutureProvider<List<DiagnosticCode>>((ref) async {
  final repository = ref.watch(obdRepositoryProvider);
  return repository.getErrors();
});

class ObdConnectionStateNotifier extends Notifier<ObdConnectionState> {
  @override
  ObdConnectionState build() => StorageService.getConnectionState();
  
  void updateState(ObdConnectionState newState) {
    state = newState;
    StorageService.saveConnectionState(newState);
  }
}

final obdConnectionStateProvider = NotifierProvider<ObdConnectionStateNotifier, ObdConnectionState>(() {
  return ObdConnectionStateNotifier();
});

class DashboardStyleNotifier extends Notifier<DashboardStyle> {
  @override
  DashboardStyle build() => StorageService.getDashboardStyle();
  
  void setStyle(DashboardStyle style) {
    state = style;
    StorageService.saveDashboardStyle(style);
  }
}

final dashboardStyleProvider = NotifierProvider<DashboardStyleNotifier, DashboardStyle>(() {
  return DashboardStyleNotifier();
});

class AppSettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => StorageService.getAppSettings();

  void update(AppSettings settings) {
    state = settings;
    StorageService.saveAppSettings(settings);
  }
}

final appSettingsProvider =
    NotifierProvider<AppSettingsNotifier, AppSettings>(AppSettingsNotifier.new);
