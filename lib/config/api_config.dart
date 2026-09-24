class ApiConfig {
  /// URL base del backend Django.
  ///
  /// Este es solo el valor por defecto de fábrica (se usa en una instalación
  /// nueva, sin nada guardado todavía). Una vez abierta la app, la URL real
  /// en uso se puede cambiar en cualquier momento desde
  /// ⚙️ Configuración → se guarda y sobrescribe este valor.
  ///
  /// - Túnel público (Cloudflare, recomendado — funciona desde cualquier red):
  ///   `https://<subdominio>.trycloudflare.com/api/v1/operador`
  /// - Emulador Android: usa 10.0.2.2 para llegar al `localhost` del host.
  /// - Dispositivo físico por USB: usa 127.0.0.1 + `adb reverse tcp:8000 tcp:8000`.
  /// - Dispositivo físico por WiFi (misma red que el PC): la IP LAN del PC.
  /// - Producción: reemplaza por el dominio real (https://api.krane.cl).
  static const String baseUrl =
      'https://bangkok-charles-secret-mysql.trycloudflare.com/api/v1/operador';
}
