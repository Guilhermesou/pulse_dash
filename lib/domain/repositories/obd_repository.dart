import '../models/vehicle_data.dart';
import '../models/diagnostic_code.dart';

abstract class ObdRepository {
  Stream<VehicleData> getLiveData();
  Future<List<DiagnosticCode>> getErrors();
  Future<void> connect(String deviceId);
  Future<void> disconnect();
  Future<bool> checkCompatibility();
  Future<void> clearErrors();
}
