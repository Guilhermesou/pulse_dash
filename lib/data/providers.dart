import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/repositories/obd_repository.dart';
import '../domain/models/vehicle_data.dart';
import '../domain/models/diagnostic_code.dart';
import '../domain/models/app_state.dart';
import '../domain/models/app_settings.dart';
import '../core/storage/storage_service.dart';
import '../core/services/bluetooth_service.dart';
import '../core/services/elm327_service.dart';
import '../data/repositories/bluetooth_obd_repository.dart';
import 'mocks/mock_obd_repository.dart';

// ─── Serviços Bluetooth ─────────────────────────────────────────────────────

/// Gerenciador BLE singleton — gerencia scan e conexão.
final bluetoothServiceProvider = Provider<BleManager>((ref) {
  final service = BleManager();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Serviço ELM327 singleton — protocolo serial OBD-II.
final elm327ServiceProvider = Provider<Elm327Service>((ref) {
  return Elm327Service();
});

/// Stream de dispositivos BLE descobertos durante o scan.
final bluetoothDevicesProvider = StreamProvider<List<BluetoothDeviceInfo>>((ref) {
  final btService = ref.watch(bluetoothServiceProvider);
  return btService.devicesStream;
});

// ─── Repositório OBD (Mock ↔ Real) ─────────────────────────────────────────

/// Repositório real (Bluetooth + ELM327).
final bluetoothObdRepositoryProvider = Provider<BluetoothObdRepository>((ref) {
  final bt = ref.watch(bluetoothServiceProvider);
  final elm = ref.watch(elm327ServiceProvider);
  final repo = BluetoothObdRepository(
    bluetoothService: bt,
    elm327Service: elm,
  );
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Repositório mock para desenvolvimento sem hardware.
final mockObdRepositoryProvider = Provider<MockObdRepository>((ref) {
  return MockObdRepository();
});

/// Provider principal do repositório OBD.
///
/// Retorna o repositório real (Bluetooth) quando [devMode] está desativado
/// e o mock quando está ativado — permitindo desenvolvimento e testes
/// sem hardware físico.
final obdRepositoryProvider = Provider<ObdRepository>((ref) {
  final settings = ref.watch(appSettingsProvider);
  if (settings.devMode) {
    return ref.watch(mockObdRepositoryProvider);
  }
  return ref.watch(bluetoothObdRepositoryProvider);
});

// ─── Dados live do veículo ──────────────────────────────────────────────────

/// Stream de dados do veículo em tempo real.
final vehicleDataProvider = StreamProvider<VehicleData>((ref) {
  final repository = ref.watch(obdRepositoryProvider);
  return repository.getLiveData();
});

/// Códigos de diagnóstico (DTCs).
final diagnosticErrorsProvider = FutureProvider<List<DiagnosticCode>>((ref) async {
  final repository = ref.watch(obdRepositoryProvider);
  return repository.getErrors();
});

// ─── Estado de conexão OBD ──────────────────────────────────────────────────

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

// ─── Estilo do dashboard ────────────────────────────────────────────────────

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

// ─── Configurações do app ───────────────────────────────────────────────────

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
