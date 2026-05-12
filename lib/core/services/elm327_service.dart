import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'obd_transport.dart';

/// Comandos AT para inicialização do ELM327.
class Elm327Commands {
  static const reset = 'ATZ';        // Reset do adaptador
  static const echoOff = 'ATE0';     // Desliga echo
  static const linefeedOff = 'ATL0'; // Desliga linefeed
  static const spacesOff = 'ATS0';   // Desliga espaços na resposta
  static const headersOff = 'ATH0';  // Desliga headers
  static const autoProtocol = 'ATSP0'; // Protocolo automático
  static const setTimeout = 'ATST FF'; // Timeout máximo de resposta (255 × 4ms = 1.02s)
  static const readVoltage = 'ATRV';   // Tensão da bateria
  static const describeProt = 'ATDP';  // Descreve protocolo detectado
}

/// PIDs OBD-II Mode 01 mais comuns.
class ObdPids {
  // PID 00: Bitmask de PIDs suportados (01-20)
  static const supportedPids = '0100';
  
  // Dados live (Mode 01)
  static const engineLoad     = '0104'; // Carga do motor (%)
  static const coolantTemp    = '0105'; // Temperatura do líquido de arrefecimento (°C)
  static const intakeManifold = '010B'; // Pressão absoluta MAP (kPa)
  static const rpm            = '010C'; // Rotação do motor (RPM)
  static const speed          = '010D'; // Velocidade do veículo (km/h)
  static const mafFlow        = '0110'; // Fluxo de ar MAF (g/s)
  static const throttlePos    = '0111'; // Posição da borboleta (%)

  // DTCs (Mode 03 / 04)
  static const readDTCs  = '03';   // Lê códigos de erro
  static const clearDTCs = '04';   // Limpa códigos de erro
}

/// Resultado de um PID suportado.
class SupportedPid {
  final String pidCode;
  final String name;
  final bool supported;

  const SupportedPid({
    required this.pidCode,
    required this.name,
    required this.supported,
  });
}

/// Serviço de comunicação com o adaptador ELM327 via RFCOMM serial.
///
/// Envia comandos AT e OBD-II, recebe e parseia respostas hexadecimais.
class Elm327Service {
  ObdTransport? _transport;
  final _responseBuffer = StringBuffer();
  Completer<String>? _pendingResponse;
  StreamSubscription? _inputSub;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  bool get isConnected => _transport != null;

  // ─── Conexão e inicialização ────────────────────────────────────────────────

  /// Recebe um transporte já conectado e inicia o listener de dados.
  void attach(ObdTransport transport) {
    _transport = transport;
    _isInitialized = false;

    _inputSub?.cancel();
    _inputSub = _transport!.inputStream.listen(
      _onDataReceived,
      onError: (e) {
        debugPrint('[ELM327] Erro no stream: $e');
      },
      onDone: () {
        debugPrint('[ELM327] Conexão encerrada.');
        _isInitialized = false;
        _transport = null;
      },
    );
  }

  /// Inicializa o ELM327 com a sequência de comandos AT padrão.
  /// Retorna a versão do firmware detectada.
  Future<String> initialize() async {
    if (_transport == null) {
      throw StateError('Conexão Bluetooth não estabelecida');
    }

    // Reset — responde com "ELM327 v1.5" ou similar
    final version = await sendCommand(Elm327Commands.reset, timeout: const Duration(seconds: 5));
    
    // Configurações do adaptador
    await sendCommand(Elm327Commands.echoOff);
    await sendCommand(Elm327Commands.linefeedOff);
    await sendCommand(Elm327Commands.spacesOff);
    await sendCommand(Elm327Commands.headersOff);
    await sendCommand(Elm327Commands.autoProtocol);
    // Timeout máximo: evita "NO DATA" prematuro durante detecção do protocolo CAN
    await sendCommand(Elm327Commands.setTimeout);

    _isInitialized = true;
    return version;
  }

  /// Desconecta e limpa recursos.
  void detach() {
    _inputSub?.cancel();
    _inputSub = null;
    _pendingResponse?.completeError(
      StateError('Conexão encerrada durante comando'),
    );
    _pendingResponse = null;
    _responseBuffer.clear();
    _isInitialized = false;
    _transport = null;
  }

  // ─── Envio de comandos ──────────────────────────────────────────────────────

  /// Envia um comando AT ou OBD-II e aguarda a resposta.
  ///
  /// O ELM327 delimita respostas com `>` (prompt).
  Future<String> sendCommand(
    String command, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_transport == null) {
      throw StateError('ELM327 desconectado');
    }

    // Aguarda comando anterior finalizar
    if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
      await _pendingResponse!.future.timeout(timeout, onTimeout: () => '');
    }

    _responseBuffer.clear();
    _pendingResponse = Completer<String>();

    // Envia o comando com CR (\r) como terminador
    final bytes = Uint8List.fromList(utf8.encode('$command\r'));
    await _transport!.write(bytes);

    try {
      final response = await _pendingResponse!.future.timeout(
        timeout,
        onTimeout: () => _responseBuffer.toString(),
      );
      return _cleanResponse(response);
    } catch (e) {
      return '';
    }
  }

  // ─── Leitura de PIDs ────────────────────────────────────────────────────────

  /// Lê um PID OBD-II e retorna os bytes de dados brutos (sem header).
  Future<List<int>> readPidRaw(String pid) async {
    final response = await sendCommand(pid);
    return _parseHexResponse(response, pid);
  }

  /// Lê RPM (PID 010C) — retorna valor em RPM.
  Future<double> readRpm() async {
    final bytes = await readPidRaw(ObdPids.rpm);
    if (bytes.length < 2) return 0;
    // Fórmula SAE J1979: ((A * 256) + B) / 4
    return ((bytes[0] * 256) + bytes[1]) / 4.0;
  }

  /// Lê velocidade (PID 010D) — retorna em km/h.
  Future<double> readSpeed() async {
    final bytes = await readPidRaw(ObdPids.speed);
    if (bytes.isEmpty) return 0;
    // Fórmula: A (direto)
    return bytes[0].toDouble();
  }

  /// Lê temperatura do líquido (PID 0105) — retorna em °C.
  Future<double> readCoolantTemp() async {
    final bytes = await readPidRaw(ObdPids.coolantTemp);
    if (bytes.isEmpty) return 0;
    // Fórmula: A - 40
    return bytes[0] - 40.0;
  }

  /// Lê pressão MAP (PID 010B) — retorna em kPa.
  /// Para calcular boost: (MAP / 100) - 1.0 ≈ bar relativos.
  Future<double> readIntakeManifoldPressure() async {
    final bytes = await readPidRaw(ObdPids.intakeManifold);
    if (bytes.isEmpty) return 101; // Pressão atmosférica padrão
    // Fórmula: A (kPa absoluto)
    return bytes[0].toDouble();
  }

  /// Calcula boost em bar relativo a partir da MAP.
  Future<double> readBoost() async {
    final mapKpa = await readIntakeManifoldPressure();
    // Converte para bar relativo: (kPa / 100) - 1.013
    return (mapKpa / 100.0) - 1.013;
  }

  /// Lê carga do motor (PID 0104) — retorna em %.
  Future<double> readEngineLoad() async {
    final bytes = await readPidRaw(ObdPids.engineLoad);
    if (bytes.isEmpty) return 0;
    // Fórmula: (A / 255) * 100
    return (bytes[0] / 255.0) * 100.0;
  }

  /// Lê fluxo MAF (PID 0110) — retorna em g/s.
  Future<double> readMafFlow() async {
    final bytes = await readPidRaw(ObdPids.mafFlow);
    if (bytes.length < 2) return 0;
    // Fórmula: ((A * 256) + B) / 100
    return ((bytes[0] * 256) + bytes[1]) / 100.0;
  }

  /// Lê posição da borboleta (PID 0111) — retorna em %.
  Future<double> readThrottlePosition() async {
    final bytes = await readPidRaw(ObdPids.throttlePos);
    if (bytes.isEmpty) return 0;
    // Fórmula: (A / 255) * 100
    return (bytes[0] / 255.0) * 100.0;
  }

  /// Estima consumo instantâneo (L/h) a partir do MAF.
  /// Fórmula simplificada para gasolina: MAF(g/s) / (14.7 * 0.74) * 3.6
  Future<double> readFuelConsumption() async {
    final maf = await readMafFlow();
    if (maf <= 0) return 0;
    // Relação ar/combustível estequiométrica gasolina = 14.7
    // Densidade gasolina ≈ 0.74 kg/L
    return (maf / (14.7 * 0.74)) * 3.6;
  }

  /// Lê tensão da bateria via comando AT (ATRV).
  Future<double> readBatteryVoltage() async {
    final response = await sendCommand(Elm327Commands.readVoltage);
    // Resposta ex: "12.6V" ou "14.2V"
    final cleaned = response.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0;
  }

  // ─── DTCs ───────────────────────────────────────────────────────────────────

  /// Lê códigos de erro (Mode 03).
  /// Retorna lista de strings tipo "P0301", "C0100", etc.
  Future<List<String>> readDtcCodes() async {
    final response = await sendCommand(ObdPids.readDTCs, timeout: const Duration(seconds: 5));
    
    if (response.isEmpty || response.contains('NO DATA') || response.contains('ERROR')) {
      return [];
    }

    return _parseDtcResponse(response);
  }

  /// Limpa códigos de erro (Mode 04).
  Future<bool> clearDtcCodes() async {
    final response = await sendCommand(ObdPids.clearDTCs, timeout: const Duration(seconds: 5));
    // Resposta positiva: "44" (0x44 = Mode 04 + 0x40)
    return response.contains('44');
  }

  // ─── Detecção de PIDs suportados ────────────────────────────────────────────

  /// Detecta quais PIDs são suportados pela ECU (PID 0100).
  Future<List<SupportedPid>> detectSupportedPids() async {
    final bytes = await readPidRaw(ObdPids.supportedPids);
    if (bytes.length < 4) return [];

    // 4 bytes = 32 bits, cada bit indica um PID (01-20)
    final bitmask = (bytes[0] << 24) | (bytes[1] << 16) | (bytes[2] << 8) | bytes[3];

    final pidMap = <int, String>{
      0x04: 'Carga do Motor',
      0x05: 'Temperatura do Motor',
      0x0B: 'Pressão MAP',
      0x0C: 'RPM',
      0x0D: 'Velocidade',
      0x10: 'Fluxo MAF',
      0x11: 'Posição Borboleta',
    };

    final results = <SupportedPid>[];
    for (final entry in pidMap.entries) {
      final pidNum = entry.key;
      // Bit 31 = PID 01, Bit 30 = PID 02, etc.
      final bitPos = 32 - pidNum;
      final supported = bitPos >= 0 && ((bitmask >> bitPos) & 1) == 1;
      results.add(SupportedPid(
        pidCode: pidNum.toRadixString(16).padLeft(2, '0').toUpperCase(),
        name: entry.value,
        supported: supported,
      ));
    }

    return results;
  }

  // ─── Parsing interno ────────────────────────────────────────────────────────

  void _onDataReceived(Uint8List data) {
    final chunk = utf8.decode(data, allowMalformed: true);
    _responseBuffer.write(chunk);

    // O ELM327 termina cada resposta com '>'
    if (chunk.contains('>')) {
      if (_pendingResponse != null && !_pendingResponse!.isCompleted) {
        _pendingResponse!.complete(_responseBuffer.toString());
      }
    }
  }

  /// Remove ruído da resposta: prompts, espaços, CRs, etc.
  String _cleanResponse(String raw) {
    return raw
        .replaceAll('>', '')
        .replaceAll('\r', '')
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'SEARCHING\.\.\.'), '')
        .replaceAll(RegExp(r'BUS INIT:.*'), '')
        .trim();
  }

  /// Extrai bytes de dados de uma resposta OBD-II.
  ///
  /// Exemplo: comando "010C", resposta "41 0C 1A F8"
  /// → retorna [0x1A, 0xF8] (bytes de dados, sem header 41 0C).
  List<int> _parseHexResponse(String response, String command) {
    if (response.isEmpty ||
        response.contains('NO DATA') ||
        response.contains('ERROR') ||
        response.contains('UNABLE') ||
        response.contains('?')) {
      return [];
    }

    // Remove espaços e junta tudo
    final hex = response.replaceAll(' ', '').toUpperCase();

    // O mode retornado é mode + 0x40 (ex: 01 → 41)
    final modeStr = command.substring(0, 2);
    final mode = int.tryParse(modeStr, radix: 16);
    if (mode == null) return [];

    final responseMode = (mode + 0x40).toRadixString(16).toUpperCase();
    final pidStr = command.length > 2 ? command.substring(2).toUpperCase() : '';
    final headerStr = '$responseMode$pidStr';

    final headerIdx = hex.indexOf(headerStr);
    if (headerIdx < 0) return [];

    // Pula o header para extrair os dados
    final dataStart = headerIdx + headerStr.length;
    final dataHex = hex.substring(dataStart);

    final bytes = <int>[];
    for (int i = 0; i + 1 < dataHex.length; i += 2) {
      final b = int.tryParse(dataHex.substring(i, i + 2), radix: 16);
      if (b != null) {
        bytes.add(b);
      } else {
        break; // Para no primeiro não-hex (ex: prompt residual)
      }
    }
    return bytes;
  }

  /// Decodifica resposta de DTCs (Mode 03).
  List<String> _parseDtcResponse(String response) {
    final hex = response.replaceAll(' ', '').toUpperCase();

    // Pula header "43" (Mode 03 + 0x40)
    final idx = hex.indexOf('43');
    if (idx < 0) return [];

    final dataHex = hex.substring(idx + 2);
    final codes = <String>[];

    // Cada DTC = 2 bytes (4 hex chars)
    for (int i = 0; i + 3 < dataHex.length; i += 4) {
      final high = int.tryParse(dataHex.substring(i, i + 2), radix: 16) ?? 0;
      final low = int.tryParse(dataHex.substring(i + 2, i + 4), radix: 16) ?? 0;

      if (high == 0 && low == 0) continue; // Padding

      // Decodifica tipo do DTC a partir dos 2 bits mais altos
      const types = ['P', 'C', 'B', 'U'];
      final type = types[(high >> 6) & 0x03];
      final digit1 = (high >> 4) & 0x03;
      final digit2 = high & 0x0F;
      final digit3 = (low >> 4) & 0x0F;
      final digit4 = low & 0x0F;

      final code = '$type$digit1${digit2.toRadixString(16).toUpperCase()}'
          '${digit3.toRadixString(16).toUpperCase()}'
          '${digit4.toRadixString(16).toUpperCase()}';
      codes.add(code);
    }

    return codes;
  }
}
