import 'package:dio/dio.dart';

import '../config/api_config.dart';
import 'auth_service.dart';

/// Cliente HTTP compartido: agrega el JWT a cada request y, si el backend
/// responde 401 por token expirado, intenta refrescarlo una vez y reintenta.
class ApiClient {
  final AuthService authService;
  late final Dio dio;

  ApiClient(this.authService) {
    dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (authService.accessToken != null) {
          options.headers['Authorization'] = 'Bearer ${authService.accessToken}';
        }
        handler.next(options);
      },
      onError: (DioException error, handler) async {
        final esNoAutorizado = error.response?.statusCode == 401;
        final yaReintentado = error.requestOptions.extra['reintentado'] == true;

        if (esNoAutorizado && !yaReintentado) {
          final renovado = await authService.refrescarToken();
          if (renovado) {
            final opts = error.requestOptions;
            opts.headers['Authorization'] = 'Bearer ${authService.accessToken}';
            opts.extra['reintentado'] = true;
            try {
              final respuesta = await dio.fetch(opts);
              return handler.resolve(respuesta);
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
        }
        handler.next(error);
      },
    ));
  }
}
