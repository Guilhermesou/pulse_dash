import 'dart:async';
import 'dart:math';

import '../../domain/models/diagnostic_code.dart';
import '../../domain/models/vehicle_data.dart';
import '../../domain/repositories/obd_repository.dart';

class MockObdRepository implements ObdRepository {
  final _random = Random();
  bool _isConnected = false;
  Timer? _timer;
  final _dataController = StreamController<VehicleData>.broadcast();

  VehicleData _currentData = VehicleData(
    speed: 0,
    rpm: 800, // idle
    boost: -0.5,
    temperature: 90,
    batteryVoltage: 14.2,
    engineLoad: 20.0,
    fuelConsumption: 0.8,
  );

  @override
  Future<void> connect(String deviceId) async {
    await Future.delayed(const Duration(seconds: 3));
    _isConnected = true;
    _startMockStream();
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _timer?.cancel();
    _dataController.close();
  }

  void _startMockStream() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (timer) {
      if (!_isConnected) return;

      // Simulate some sporty driving dynamics
      double targetRpm = _currentData.rpm + (_random.nextDouble() * 400 - 150);
      targetRpm = targetRpm.clamp(800.0, 7000.0);

      double targetSpeed = _currentData.speed;
      if (targetRpm > 3000) {
        targetSpeed += 0.5;
      } else if (targetSpeed > 0) {
        targetSpeed -= 0.2;
      }
      targetSpeed = targetSpeed.clamp(0.0, 260.0);

      double targetBoost = -0.6 + (targetRpm / 7000) * 2.5; // Simulate boost based on RPM
      targetBoost += (_random.nextDouble() * 0.2 - 0.1);
      targetBoost = targetBoost.clamp(-0.8, 1.8);

      _currentData = _currentData.copyWith(
        rpm: targetRpm,
        speed: targetSpeed,
        boost: targetBoost,
        temperature: 90.0 + _random.nextDouble() * 5 - 2.5,
        engineLoad: (targetRpm / 7000) * 100,
        batteryVoltage: 14.2 + _random.nextDouble() * 0.2 - 0.1,
        fuelConsumption: (targetRpm / 1000) * 2.5,
      );

      _dataController.add(_currentData);
    });
  }

  @override
  Stream<VehicleData> getLiveData() {
    return _dataController.stream;
  }

  @override
  Future<List<DiagnosticCode>> getErrors() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      DiagnosticCode(
        code: 'P0299',
        description: 'Turbocharger/Supercharger A Underboost Condition',
        severity: ErrorSeverity.medium,
        causes: ['Boost leak', 'Faulty wastegate', 'Intercooler leak', 'Diverter valve failure'],
        suggestions: ['Check intercooler piping', 'Inspect diverter valve (DV)', 'Check turbo wastegate operation'],
        confidencePercent: 85,
      ),
      DiagnosticCode(
        code: 'P0301',
        description: 'Cylinder 1 Misfire Detected',
        severity: ErrorSeverity.high,
        causes: ['Faulty spark plug', 'Failing ignition coil', 'Fuel injector issue'],
        suggestions: ['Swap ignition coil to cylinder 2 and re-check', 'Inspect spark plug condition', 'Check fuel pressure'],
        confidencePercent: 92,
      ),
    ];
  }

  @override
  Future<bool> checkCompatibility() async {
    await Future.delayed(const Duration(seconds: 2));
    return true; // Simulate full compatibility
  }

  @override
  Future<void> clearErrors() async {
    await Future.delayed(const Duration(seconds: 1));
    // In a real app, this would clear codes on ECU
  }
}
