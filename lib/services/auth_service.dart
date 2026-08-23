import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';

/// Maneja el login, el almacenamiento seguro de los tokens JWT y la sesión
/// del operador en la app.
class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Dio _authDio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

  static const _kAccessKey = 'krane_access_token';
  static const _kRefreshKey = 'krane_refresh_token';
  static const _kNombreKey = 'krane_operador_nombre';

  String? accessToken;
  String? refreshToken;
  String? nombreOperador;
  bool isLoading = true;

  bool get isAuthenticated => accessToken != null;

  /// Se llama una vez al iniciar la app para restaurar la sesión guardada.
  Future<void> cargarSesion() async {
    accessToken = await _storage.read(key: _kAccessKey);
    refreshToken = await _storage.read(key: _kRefreshKey);
    nombreOperador = await _storage.read(key: _kNombreKey);
    isLoading = false;
    notifyListeners();
  }

  /// Intenta iniciar sesión. Retorna null si fue exitoso, o un mensaje de
  /// error legible para mostrar en la UI.
  Future<String?> login(String username, String password) async {
    try {
      final response = await _authDio.post('/login/', data: {
        'username': username,
        'password': password,
      });

      final data = response.data as Map<String, dynamic>;
      accessToken = data['access'] as String;
      refreshToken = data['refresh'] as String;
      nombreOperador = (data['usuario']?['nombre'] as String?) ?? username;

      await _storage.write(key: _kAccessKey, value: accessToken);
      await _storage.write(key: _kRefreshKey, value: refreshToken);
      await _storage.write(key: _kNombreKey, value: nombreOperador);

      notifyListeners();
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final detail = e.response?.data is Map
            ? (e.response?.data['detail'] as String?)
            : null;
        return detail ?? 'Usuario o contraseña incorrectos.';
      }
      return 'No se pudo conectar al servidor. Intenta nuevamente.';
    }
  }

  /// Intenta renovar el access token usando el refresh token guardado.
  /// Retorna false si el refresh token también expiró (hay que reloguear).
  Future<bool> refrescarToken() async {
    if (refreshToken == null) return false;
    try {
      final response = await _authDio.post('/token/refresh/', data: {
        'refresh': refreshToken,
      });
      accessToken = (response.data as Map<String, dynamic>)['access'] as String;
      await _storage.write(key: _kAccessKey, value: accessToken);
      notifyListeners();
      return true;
    } on DioException {
      await logout();
      return false;
    }
  }

  Future<void> logout() async {
    accessToken = null;
    refreshToken = null;
    nombreOperador = null;
    await _storage.deleteAll();
    notifyListeners();
  }
}
