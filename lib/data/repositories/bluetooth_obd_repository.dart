import 'dart:async';
import 'package:flutter/foundation.dart';

import '../../core/services/bluetooth_service.dart';
import '../../core/services/elm327_service.dart';
import '../../domain/models/vehicle_data.dart';
import '../../domain/models/diagnostic_code.dart';
import '../../domain/repositories/obd_repository.dart';

/// Implementação real do [ObdRepository] usando Bluetooth Classic + ELM327.
///
/// Faz polling periódico dos PIDs OBD-II e emite [VehicleData] via stream.
class BluetoothObdRepository implements ObdRepository {
  final BleManager _bluetoothService;
  final Elm327Service _elm327;

  Timer? _pollingTimer;
  final _dataController = StreamController<VehicleData>.broadcast();

  bool _isPollInProgress = false;

  // Polling em dois níveis:
  //   Rápido (todo ciclo):  RPM, Velocidade, Boost, Borboleta — ~600ms/ciclo BLE
  //   Lento  (a cada 5):   Temperatura, Bateria, Carga, Consumo — ~3s
  int _pollCycle = 0;
  static const _slowEvery = 5;

  // Timer em 300ms: descartado pelo flag enquanto o ciclo está ativo.
  // Taxa efetiva: ~600ms para PIDs rápidos, ~3s para lentos.
  static const _pollInterval = Duration(milliseconds: 300);

  VehicleData _lastData = VehicleData(
    speed: 0,
    rpm: 0,
    boost: 0,
    temperature: 0,
    batteryVoltage: 0,
    engineLoad: 0,
    fuelConsumption: 0,
  );

  BluetoothObdRepository({
    required BleManager bluetoothService,
    required Elm327Service elm327Service,
  })  : _bluetoothService = bluetoothService,
        _elm327 = elm327Service;

  // ─── ObdRepository interface ────────────────────────────────────────────────

  @override
  Future<void> connect(String deviceAddress) async {
    try {
      // 1. Conecta via BLE
      final transport = await _bluetoothService.connectToDevice(deviceAddress);

      // 2. Inicializa o ELM327
      _elm327.attach(transport);
      final version = await _elm327.initialize();
      debugPrint('[OBD] ELM327 inicializado: $version');

      // 3. Inicia polling de dados
      _startPolling();
    } catch (e) {
      debugPrint('[OBD] Erro ao conectar: $e');
      _elm327.detach();
      await _bluetoothService.disconnect();
      rethrow;
    }
  }

  @override
  Future<void> disconnect() async {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _elm327.detach();
    await _bluetoothService.disconnect();
  }

  @override
  Stream<VehicleData> getLiveData() {
    return _dataController.stream;
  }

  @override
  Future<List<DiagnosticCode>> getErrors() async {
    if (!_elm327.isConnected) {
      throw StateError('OBD-II não conectado');
    }

    // Pausa o polling durante a leitura de DTCs
    _pollingTimer?.cancel();

    try {
      final codes = await _elm327.readDtcCodes();

      if (codes.isEmpty) return [];

      // Mapa de descrições conhecidas para DTCs comuns
      return codes.map((code) => _buildDiagnosticCode(code)).toList();
    } finally {
      // Retoma o polling
      _startPolling();
    }
  }

  @override
  Future<void> clearErrors() async {
    if (!_elm327.isConnected) {
      throw StateError('OBD-II não conectado');
    }

    _pollingTimer?.cancel();

    try {
      final success = await _elm327.clearDtcCodes();
      if (!success) {
        throw Exception('ECU não confirmou a limpeza dos códigos');
      }
    } finally {
      _startPolling();
    }
  }

  @override
  Future<bool> checkCompatibility() async {
    if (!_elm327.isConnected) return false;

    try {
      final pids = await _elm327.detectSupportedPids();
      // Verifica se ao menos RPM e velocidade estão disponíveis
      final hasRpm = pids.any((p) => p.pidCode == '0C' && p.supported);
      final hasSpeed = pids.any((p) => p.pidCode == '0D' && p.supported);
      return hasRpm && hasSpeed;
    } catch (e) {
      debugPrint('[OBD] Erro na verificação de compatibilidade: $e');
      return false;
    }
  }

  /// Retorna a lista de PIDs suportados pela ECU (para a tela de compatibilidade).
  Future<List<SupportedPid>> getSupportedPids() async {
    if (!_elm327.isConnected) return [];
    return _elm327.detectSupportedPids();
  }

  // ─── Polling interno ────────────────────────────────────────────────────────

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_pollInterval, (_) => _pollOnce());
  }

  /// Polling em dois níveis:
  ///   • Rápido (todo ciclo): RPM, Velocidade, Boost, Borboleta
  ///   • Lento  (a cada [_slowEvery] ciclos): Temperatura, Bateria, Carga, Consumo
  ///
  /// Se o ELM327 desconectar, emite erro no stream e cancela o timer.
  Future<void> _pollOnce() async {
    if (_isPollInProgress) return;

    // Detecta desconexão e propaga erro para o StreamProvider da UI.
    if (!_elm327.isConnected || !_elm327.isInitialized) {
      _pollingTimer?.cancel();
      _pollingTimer = null;
      if (!_dataController.isClosed) {
        _dataController.addError(
          Exception('OBD2 desconectado. Verifique o adaptador e reconecte.'),
        );
      }
      return;
    }

    _isPollInProgress = true;
    _pollCycle++;

    try {
      // ── PIDs rápidos: lidos todo ciclo (~600ms/ciclo via BLE) ──────────────
      final rpm      = await _safeRead(_elm327.readRpm,              _lastData.rpm);
      final speed    = await _safeRead(_elm327.readSpeed,            _lastData.speed);
      final boost    = await _safeRead(_elm327.readBoost,            _lastData.boost);
      final throttle = await _safeRead(_elm327.readThrottlePosition, _lastData.throttlePosition);

      // ── PIDs lentos: lidos a cada [_slowEvery] ciclos (~3s) ───────────────
      double temp    = _lastData.temperature;
      double voltage = _lastData.batteryVoltage;
      double load    = _lastData.engineLoad;
      double fuel    = _lastData.fuelConsumption;

      if (_pollCycle % _slowEvery == 0) {
        temp    = await _safeRead(_elm327.readCoolantTemp,      _lastData.temperature);
        voltage = await _safeRead(_elm327.readBatteryVoltage,   _lastData.batteryVoltage);
        load    = await _safeRead(_elm327.readEngineLoad,       _lastData.engineLoad);
        fuel    = await _safeRead(_elm327.readFuelConsumption,  _lastData.fuelConsumption);
      }

      _lastData = VehicleData(
        rpm: rpm,
        speed: speed,
        boost: boost,
        throttlePosition: throttle,
        temperature: temp,
        batteryVoltage: voltage,
        engineLoad: load,
        fuelConsumption: fuel,
      );

      if (!_dataController.isClosed) _dataController.add(_lastData);
    } catch (e) {
      debugPrint('[OBD] Erro no polling: $e');
    } finally {
      _isPollInProgress = false;
    }
  }

  /// Executa uma leitura OBD com fallback em caso de erro.
  Future<double> _safeRead(
    Future<double> Function() reader,
    double fallback,
  ) async {
    try {
      return await reader();
    } catch (e) {
      return fallback;
    }
  }

  // ─── DTCs ───────────────────────────────────────────────────────────────────

  /// Monta um [DiagnosticCode] a partir de um código DTC string.
  /// Inclui descrições e causas para DTCs conhecidos.
  DiagnosticCode _buildDiagnosticCode(String code) {
    final known = _knownDtcs[code];
    if (known != null) return known;

    // DTC desconhecido — retorna info básica
    final severity = _inferSeverity(code);
    return DiagnosticCode(
      code: code,
      description: 'Código de diagnóstico desconhecido',
      severity: severity,
      causes: ['Consulte manual de serviço do veículo'],
      suggestions: ['Pesquise o código $code para seu modelo específico'],
      confidencePercent: 50,
    );
  }

  ErrorSeverity _inferSeverity(String code) {
    if (code.startsWith('P0')) return ErrorSeverity.medium; // Genérico powertrain
    if (code.startsWith('P1')) return ErrorSeverity.medium; // Fabricante powertrain
    if (code.startsWith('P2')) return ErrorSeverity.high;   // Genérico powertrain
    if (code.startsWith('P3')) return ErrorSeverity.high;   // Genérico powertrain
    if (code.startsWith('C')) return ErrorSeverity.high;     // Chassis
    if (code.startsWith('B')) return ErrorSeverity.low;      // Body
    if (code.startsWith('U')) return ErrorSeverity.medium;   // Network
    return ErrorSeverity.medium;
  }

  /// Base de DTCs conhecidos com descrições em português.
  static final Map<String, DiagnosticCode> _knownDtcs = {
    'P0171': DiagnosticCode(
      code: 'P0171',
      description: 'Sistema muito pobre (Banco 1)',
      severity: ErrorSeverity.medium,
      causes: ['Vazamento de vácuo', 'Sensor MAF sujo', 'Injetor obstruído', 'Bomba de combustível fraca'],
      suggestions: ['Verificar mangueiras de vácuo', 'Limpar ou trocar sensor MAF', 'Testar pressão de combustível'],
      confidencePercent: 80,
    ),
    'P0172': DiagnosticCode(
      code: 'P0172',
      description: 'Sistema muito rico (Banco 1)',
      severity: ErrorSeverity.medium,
      causes: ['Injetor com vazamento', 'Regulador de pressão', 'Sensor O2 defeituoso'],
      suggestions: ['Verificar injetores', 'Testar sensor de oxigênio', 'Checar pressão de combustível'],
      confidencePercent: 78,
    ),
    'P0299': DiagnosticCode(
      code: 'P0299',
      description: 'Turbo/Supercharger A - Condição de Underboost',
      severity: ErrorSeverity.medium,
      causes: ['Vazamento de boost', 'Wastegate defeituoso', 'Vazamento no intercooler', 'Válvula desviadora com falha'],
      suggestions: ['Verificar tubulação do intercooler', 'Inspecionar válvula desviadora (DV)', 'Checar operação do wastegate'],
      confidencePercent: 85,
    ),
    'P0300': DiagnosticCode(
      code: 'P0300',
      description: 'Falha de ignição aleatória detectada',
      severity: ErrorSeverity.high,
      causes: ['Velas de ignição gastas', 'Bobinas de ignição', 'Problema de combustível', 'Baixa compressão'],
      suggestions: ['Trocar velas e bobinas', 'Verificar pressão de combustível', 'Teste de compressão'],
      confidencePercent: 75,
    ),
    'P0301': DiagnosticCode(
      code: 'P0301',
      description: 'Falha de Ignição no Cilindro 1',
      severity: ErrorSeverity.high,
      causes: ['Vela de ignição defeituosa', 'Bobina de ignição com falha', 'Problema no injetor'],
      suggestions: ['Trocar bobina para cilindro 2 e re-testar', 'Inspecionar estado da vela', 'Verificar pressão de combustível'],
      confidencePercent: 92,
    ),
    'P0302': DiagnosticCode(
      code: 'P0302',
      description: 'Falha de Ignição no Cilindro 2',
      severity: ErrorSeverity.high,
      causes: ['Vela de ignição defeituosa', 'Bobina de ignição com falha', 'Problema no injetor'],
      suggestions: ['Trocar bobina para outro cilindro e re-testar', 'Inspecionar estado da vela'],
      confidencePercent: 92,
    ),
    'P0303': DiagnosticCode(
      code: 'P0303',
      description: 'Falha de Ignição no Cilindro 3',
      severity: ErrorSeverity.high,
      causes: ['Vela de ignição defeituosa', 'Bobina de ignição com falha', 'Problema no injetor'],
      suggestions: ['Trocar bobina para outro cilindro e re-testar', 'Inspecionar estado da vela'],
      confidencePercent: 92,
    ),
    'P0304': DiagnosticCode(
      code: 'P0304',
      description: 'Falha de Ignição no Cilindro 4',
      severity: ErrorSeverity.high,
      causes: ['Vela de ignição defeituosa', 'Bobina de ignição com falha', 'Problema no injetor'],
      suggestions: ['Trocar bobina para outro cilindro e re-testar', 'Inspecionar estado da vela'],
      confidencePercent: 92,
    ),
    'P0420': DiagnosticCode(
      code: 'P0420',
      description: 'Eficiência do Catalisador abaixo do limiar (Banco 1)',
      severity: ErrorSeverity.medium,
      causes: ['Catalisador degradado', 'Sensor O2 downstream defeituoso', 'Vazamento de escape'],
      suggestions: ['Verificar sensor O2', 'Inspecionar catalisador', 'Verificar vazamentos no escape'],
      confidencePercent: 70,
    ),
    'P0455': DiagnosticCode(
      code: 'P0455',
      description: 'Vazamento grande detectado no sistema EVAP',
      severity: ErrorSeverity.low,
      causes: ['Tampa do tanque solta', 'Mangueira EVAP desconectada', 'Válvula de purga com vazamento'],
      suggestions: ['Verificar tampa do tanque', 'Inspecionar mangueiras EVAP', 'Teste de fumaça'],
      confidencePercent: 85,
    ),
  };

  void dispose() {
    _pollingTimer?.cancel();
    _dataController.close();
  }
}
