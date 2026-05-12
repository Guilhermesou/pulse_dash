import 'dart:typed_data';

/// Interface de transporte serial para o ELM327.
///
/// Abstrai o meio físico (BLE, Wi-Fi, etc.) do protocolo OBD-II,
/// permitindo que o [Elm327Service] funcione em qualquer conectividade.
abstract class ObdTransport {
  /// Stream de bytes recebidos do adaptador.
  Stream<Uint8List> get inputStream;

  /// Envia bytes para o adaptador.
  Future<void> write(Uint8List bytes);

  /// Fecha a conexão e libera recursos.
  Future<void> close();
}
