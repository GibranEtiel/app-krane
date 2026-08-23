class ApiConfig {
  /// URL base del backend Django.
  ///
  /// - Emulador Android: usa 10.0.2.2 para llegar al `localhost` del host.
  /// - Dispositivo físico por USB: usa 127.0.0.1 + `adb reverse tcp:8000 tcp:8000`.
  /// - Dispositivo físico por WiFi: usa la IP LAN de tu PC (ej. 192.168.1.89).
  /// - Producción: reemplaza por el dominio real (https://api.krane.cl).
  static const String baseUrl = 'http://127.0.0.1:8000/api/v1/operador';
}
