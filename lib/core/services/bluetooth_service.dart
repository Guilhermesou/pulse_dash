import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'obd_transport.dart';

/// Modelo leve que representa um dispositivo BLE descoberto.
class BluetoothDeviceInfo {
  final String name;
  final String address; // remoteId.str do dispositivo
  final bool isBonded;  // sempre false em BLE/iOS
  final int? rssi;
  final List<Guid> serviceUuids; // UUIDs anunciados no advertisement

  const BluetoothDeviceInfo({
    required this.name,
    required this.address,
    this.isBonded = false,
    this.rssi,
    this.serviceUuids = const [],
  });

  // UUIDs dos perfis UART BLE usados por adaptadores OBD2.
  static final _obdServices = {
    Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e'), // Nordic NUS
    Guid('0000ffe0-0000-1000-8000-00805f9b34fb'), // HM-10 / HC-08
    Guid('e7810a71-73ae-499d-8c15-faa9aef0c3f2'), // Vgate iCar Pro
  };

  /// Detecta pelo UUID de serviço anunciado — método mais confiável.
  bool get hasObdService =>
      serviceUuids.any((uuid) => _obdServices.contains(uuid));

  /// Heurística por nome — cobre adaptadores que não anunciam serviço.
  bool get looksLikeObd {
    final lower = name.toLowerCase();
    return lower.contains('obd') ||
        lower.contains('elm') ||
        lower.contains('vgate') ||
        lower.contains('icar') ||
        lower.contains('v-link') ||
        lower.contains('vlink') ||
        lower.contains('konnwei') ||
        lower.contains('veepeak') ||
        lower.contains('bluedriver') ||
        lower.contains('obdlink') ||
        lower.contains('lelink') ||
        lower.contains('carista') ||
        lower.contains('carly') ||
        lower.contains('xtool') ||
        lower.contains('fixd') ||
        lower.contains('torque') ||
        lower.contains('autocom');
  }

  /// Verdadeiro se detectado por UUID ou por nome.
  bool get isObdDevice => hasObdService || looksLikeObd;
}

// ─── UUIDs dos perfis UART BLE conhecidos ─────────────────────────────────────

/// Nordic UART Service (NUS) — perfil mais comum em clones ELM327 BLE.
final _nusService  = Guid('6e400001-b5a3-f393-e0a9-e50e24dcca9e');
final _nusWrite    = Guid('6e400002-b5a3-f393-e0a9-e50e24dcca9e');
final _nusNotify   = Guid('6e400003-b5a3-f393-e0a9-e50e24dcca9e');

/// HM-10 / HC-08 (0xFFE0) — módulos BLE mais antigos.
final _hm10Service = Guid('0000ffe0-0000-1000-8000-00805f9b34fb');
final _hm10Char    = Guid('0000ffe1-0000-1000-8000-00805f9b34fb');

/// FFF0 — clones ELM327 BLE baratos (muito comuns no mercado).
final _fff0Service  = Guid('0000fff0-0000-1000-8000-00805f9b34fb');
final _fff1Notify   = Guid('0000fff1-0000-1000-8000-00805f9b34fb');
final _fff2Write    = Guid('0000fff2-0000-1000-8000-00805f9b34fb');

/// Microchip UART — usado em alguns adaptadores certificados.
final _microchipService = Guid('49535343-fe7d-4ae5-8fa9-9fafd205e455');
final _microchipWrite   = Guid('49535343-1e4d-4bd9-ba61-23c647249616');
final _microchipNotify  = Guid('49535343-8841-43f4-a8d4-ecbe34729bb3');

/// Vgate iCar Pro BLE.
final _vgateService = Guid('e7810a71-73ae-499d-8c15-faa9aef0c3f2');
final _vgateChar    = Guid('bef8d6c9-9c21-4c9e-b632-bd58c1009f9f');

/// Prefixos de serviços BLE padrão do sistema (bateria, acesso genérico, etc.)
/// Ignorados no fallback genérico para evitar falsos positivos.
const _systemServicePrefixes = ['00001800', '00001801', '0000180f', '0000180a'];

// ─── Transporte BLE ───────────────────────────────────────────────────────────

/// Implementação de [ObdTransport] sobre BLE GATT.
///
/// Suporta três perfis UART: Nordic NUS, HM-10 e Vgate iCar Pro.
/// Descobre automaticamente qual o adaptador suporta.
class BleObdTransport implements ObdTransport {
  final BluetoothDevice _device;

  BluetoothCharacteristic? _writeChar;  // phone → adapter
  BluetoothCharacteristic? _notifyChar; // adapter → phone

  final _inputController = StreamController<Uint8List>.broadcast();
  StreamSubscription? _notifySub;

  BleObdTransport(this._device);

  /// Conecta ao dispositivo e configura as características UART.
  Future<void> connect() async {
    await _device.connect(autoConnect: false, timeout: const Duration(seconds: 10));
    final gattServices = await _device.discoverServices();

    _findUartCharacteristics(gattServices);

    if (_notifyChar == null || _writeChar == null) {
      // Monta lista de serviços + características para diagnóstico na tela.
      final buf = StringBuffer('Perfil não reconhecido.\n\nServiços encontrados:');
      for (final svc in gattServices) {
        buf.write('\n• ${svc.serviceUuid.str}');
        for (final c in svc.characteristics) {
          final props = [
            if (c.properties.write || c.properties.writeWithoutResponse) 'W',
            if (c.properties.notify || c.properties.indicate) 'N',
          ].join('');
          if (props.isNotEmpty) {
            buf.write('\n  ↳ ${c.characteristicUuid.str} [$props]');
          }
        }
      }
      await _device.disconnect();
      throw StateError(buf.toString());
    }

    await _notifyChar!.setNotifyValue(true);
    _notifySub = _notifyChar!.onValueReceived.listen(
      (data) => _inputController.add(Uint8List.fromList(data)),
      onError: (e) => debugPrint('[BLE] Erro nas notificações: $e'),
      onDone: () {
        debugPrint('[BLE] Stream encerrado.');
        if (!_inputController.isClosed) _inputController.close();
      },
    );
  }

  /// Percorre os serviços GATT em ordem de prioridade.
  /// Fallback: qualquer par write+notify que não seja serviço de sistema.
  void _findUartCharacteristics(List<BluetoothService> gattServices) {
    // ── Perfis conhecidos ──────────────────────────────────────────────────────
    for (final svc in gattServices) {
      // Nordic NUS
      if (svc.serviceUuid == _nusService) {
        for (final c in svc.characteristics) {
          if (c.characteristicUuid == _nusWrite)  _writeChar  = c;
          if (c.characteristicUuid == _nusNotify) _notifyChar = c;
        }
        if (_writeChar != null && _notifyChar != null) {
          debugPrint('[BLE] Perfil: Nordic NUS'); return;
        }
      }

      // HM-10 / HC-08
      if (svc.serviceUuid == _hm10Service) {
        final c = svc.characteristics
            .where((c) => c.characteristicUuid == _hm10Char).firstOrNull;
        if (c != null) {
          _writeChar = c; _notifyChar = c;
          debugPrint('[BLE] Perfil: HM-10/HC-08'); return;
        }
      }

      // FFF0 — clone ELM327 barato (muito comum)
      if (svc.serviceUuid == _fff0Service) {
        for (final c in svc.characteristics) {
          if (c.characteristicUuid == _fff2Write)  _writeChar  = c;
          if (c.characteristicUuid == _fff1Notify) _notifyChar = c;
        }
        if (_writeChar != null && _notifyChar != null) {
          debugPrint('[BLE] Perfil: FFF0'); return;
        }
      }

      // Microchip UART
      if (svc.serviceUuid == _microchipService) {
        for (final c in svc.characteristics) {
          if (c.characteristicUuid == _microchipWrite)  _writeChar  = c;
          if (c.characteristicUuid == _microchipNotify) _notifyChar = c;
        }
        if (_writeChar != null && _notifyChar != null) {
          debugPrint('[BLE] Perfil: Microchip UART'); return;
        }
      }

      // Vgate iCar Pro
      if (svc.serviceUuid == _vgateService) {
        final c = svc.characteristics
            .where((c) => c.characteristicUuid == _vgateChar).firstOrNull;
        if (c != null) {
          _writeChar = c; _notifyChar = c;
          debugPrint('[BLE] Perfil: Vgate iCar Pro'); return;
        }
      }
    }

    // ── Fallback genérico ──────────────────────────────────────────────────────
    // Pega o primeiro par write+notify de qualquer serviço não-sistema.
    for (final svc in gattServices) {
      final svcStr = svc.serviceUuid.str.toLowerCase().replaceAll('-', '');
      if (_systemServicePrefixes.any((p) => svcStr.startsWith(p))) continue;

      for (final c in svc.characteristics) {
        if (_writeChar == null &&
            (c.properties.write || c.properties.writeWithoutResponse)) {
          _writeChar = c;
        }
        if (_notifyChar == null &&
            (c.properties.notify || c.properties.indicate)) {
          _notifyChar = c;
        }
      }
      if (_writeChar != null && _notifyChar != null) {
        debugPrint('[BLE] Perfil: fallback genérico '
            '(svc=${svc.serviceUuid})');
        return;
      }
    }
  }

  @override
  Stream<Uint8List> get inputStream => _inputController.stream;

  @override
  Future<void> write(Uint8List bytes) async {
    if (_writeChar == null) throw StateError('BLE não conectado');
    // Usa Write Without Response se disponível (mais rápido para UART serial BLE)
    final withoutResponse = _writeChar!.properties.writeWithoutResponse;
    await _writeChar!.write(bytes.toList(), withoutResponse: withoutResponse);
  }

  @override
  Future<void> close() async {
    try { await _notifyChar?.setNotifyValue(false); } catch (_) {}
    _notifySub?.cancel();
    if (!_inputController.isClosed) _inputController.close();
    try { await _device.disconnect(); } catch (_) {}
  }
}

// ─── Gerenciador de scan BLE ──────────────────────────────────────────────────

/// Gerencia scan e conexão BLE via `flutter_blue_plus`.
///
/// Substitui o antigo `flutter_bluetooth_serial` (Android-only).
/// Funciona em iOS e Android com adaptadores ELM327 BLE.
class BleManager {
  StreamSubscription? _scanSub;
  BleObdTransport? _activeTransport;

  final _devicesController =
      StreamController<List<BluetoothDeviceInfo>>.broadcast();
  Stream<List<BluetoothDeviceInfo>> get devicesStream =>
      _devicesController.stream;

  final _isScanning = ValueNotifier<bool>(false);
  ValueListenable<bool> get isScanningNotifier => _isScanning;
  bool get isScanning => _isScanning.value;

  final List<BluetoothDeviceInfo> _found = [];

  // ─── Permissões ─────────────────────────────────────────────────────────────

  /// Android: solicita permissões em tempo de execução (bluetoothScan/Connect).
  /// iOS: CoreBluetooth exibe o diálogo automaticamente ao acessar o adapter —
  ///      permission_handler não é necessário.
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform != TargetPlatform.android) return true;
    final statuses = await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();
    return statuses.values.every((s) => s.isGranted || s.isLimited);
  }

  /// Retorna o estado definitivo do adapter BLE.
  ///
  /// No iOS, acessar o adapterState inicializa o CoreBluetooth e exibe o
  /// diálogo de permissão de Bluetooth (se ainda não determinado).
  /// Aguarda até 30 s pelo primeiro estado não-unknown.
  Future<BluetoothAdapterState> getAdapterState() {
    return FlutterBluePlus.adapterState
        .where((s) => s != BluetoothAdapterState.unknown)
        .first
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () => BluetoothAdapterState.unauthorized,
        );
  }

  // ─── Scan ───────────────────────────────────────────────────────────────────

  /// BLE não tem "dispositivos pareados" como Classic BT.
  /// Retorna dispositivos BLE já conectados ao sistema operacional.
  Future<List<BluetoothDeviceInfo>> getBondedDevices() async {
    return FlutterBluePlus.connectedDevices
        .map((d) => BluetoothDeviceInfo(
              name: d.platformName.isNotEmpty ? d.platformName : d.remoteId.str,
              address: d.remoteId.str,
            ))
        .toList();
  }

  /// Inicia scan BLE por 15 segundos. Emite dispositivos via [devicesStream].
  Future<void> startScan() async {
    if (_isScanning.value) return;
    _isScanning.value = true;
    _found.clear();

    // Dispositivos já conectados surgem instantaneamente
    final connected = await getBondedDevices();
    _found.addAll(connected);
    if (_found.isNotEmpty) {
      _devicesController.add(List.unmodifiable(_found));
    }

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      bool changed = false;
      for (final result in results) {
        final advName = result.advertisementData.advName;
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : advName.isNotEmpty
                ? advName
                : result.device.remoteId.str;
        final info = BluetoothDeviceInfo(
          name: name,
          address: result.device.remoteId.str,
          rssi: result.rssi,
          serviceUuids: result.advertisementData.serviceUuids,
        );
        if (!_found.any((d) => d.address == info.address)) {
          _found.add(info);
          changed = true;
        }
      }
      if (changed) _devicesController.add(List.unmodifiable(_found));
    });

    FlutterBluePlus.startScan(timeout: const Duration(seconds: 15))
        .then((_) => _isScanning.value = false)
        .catchError((_) => _isScanning.value = false);
  }

  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
    _scanSub?.cancel();
    _scanSub = null;
    _isScanning.value = false;
  }

  // ─── Conexão ────────────────────────────────────────────────────────────────

  /// Conecta ao dispositivo BLE e retorna o transporte OBD pronto para uso.
  Future<ObdTransport> connectToDevice(String address) async {
    await _activeTransport?.close();
    final device = BluetoothDevice.fromId(address);
    final transport = BleObdTransport(device);
    await transport.connect();
    _activeTransport = transport;
    return transport;
  }

  Future<void> disconnect() async {
    try { await _activeTransport?.close(); } catch (_) {}
    _activeTransport = null;
  }

  bool get isConnected => _activeTransport != null;

  void dispose() {
    stopScan();
    disconnect();
    _devicesController.close();
    _isScanning.dispose();
  }
}
