import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:geolocator/geolocator.dart';

import '../config/api_config.dart';

/// Envía la ubicación del operador al backend cada 15 segundos mientras la
/// faena está "En Traslado", corriendo como servicio en primer plano de
/// Android (con notificación persistente). A diferencia de un Timer dentro
/// de la pantalla de la faena, este sigue vivo aunque el operador minimice
/// la app o navegue a otra pantalla — solo se detiene cuando se llama a
/// [detener], o cuando el backend avisa que la faena ya no está en traslado.
///
/// Corre en un isolate aparte: no tiene acceso al Provider/FaenaService de
/// la UI, así que lee el token y la URL del backend directamente de
/// flutter_secure_storage (mismas claves que usa AuthService) y arma su
/// propio cliente Dio.
class UbicacionBackgroundService {
  static const _channelId = 'krane_seguimiento_ubicacion';
  static const _notificationId = 990;

  static Future<void> inicializar() async {
    final service = FlutterBackgroundService();

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: _channelId,
        initialNotificationTitle: 'KraneChile Operador',
        initialNotificationContent: 'Compartiendo tu ubicación con el cliente…',
        foregroundServiceNotificationId: _notificationId,
      ),
      iosConfiguration: IosConfiguration(
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  /// Arranca (o re-apunta) el envío periódico de ubicación para [faenaId].
  static Future<void> iniciar(int faenaId) async {
    final service = FlutterBackgroundService();
    final yaCorriendo = await service.isRunning();
    if (!yaCorriendo) {
      await service.startService();
    }
    service.invoke('iniciarSeguimiento', {'faenaId': faenaId});
  }

  /// Corta el envío de ubicación (ej: al marcar "En Faena" o al cancelar).
  static void detener() {
    FlutterBackgroundService().invoke('detenerSeguimiento');
  }

  @pragma('vm:entry-point')
  static bool _onIosBackground(ServiceInstance service) {
    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((_) => service.setAsForegroundService());
      service.on('setAsBackground').listen((_) => service.setAsBackgroundService());
    }

    Timer? timer;
    const storage = FlutterSecureStorage();

    Future<void> enviarUbicacion(int faenaId) async {
      try {
        final token = await storage.read(key: 'krane_access_token');
        final baseUrl = await storage.read(key: 'krane_base_url') ?? ApiConfig.baseUrl;
        if (token == null) return;

        final posicion = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
        );

        final dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          headers: {'Authorization': 'Bearer $token'},
        ));
        await dio.patch('/faenas/$faenaId/ubicacion/', data: {
          'operador_lat': posicion.latitude,
          'operador_lng': posicion.longitude,
        });
      } on DioException catch (e) {
        // 404: el backend ya no acepta ubicación para esta faena (salió de
        // "En Traslado" desde otro dispositivo/el dashboard admin).
        // 401: el token venció; este isolate no puede refrescarlo, así que
        // se detiene en vez de reintentar para siempre.
        final codigo = e.response?.statusCode;
        if (codigo == 404 || codigo == 401) {
          timer?.cancel();
          service.stopSelf();
        }
      } catch (_) {
        // Sin señal GPS o sin red: se reintenta en el próximo ciclo de 15s.
      }
    }

    service.on('iniciarSeguimiento').listen((event) {
      final faenaId = event?['faenaId'] as int?;
      if (faenaId == null) return;
      timer?.cancel();
      enviarUbicacion(faenaId);
      timer = Timer.periodic(const Duration(seconds: 15), (_) => enviarUbicacion(faenaId));
    });

    service.on('detenerSeguimiento').listen((_) {
      timer?.cancel();
      service.stopSelf();
    });

    service.on('stop').listen((_) {
      timer?.cancel();
      service.stopSelf();
    });
  }
}
