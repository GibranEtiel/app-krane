import '../models/faena.dart';
import 'api_client.dart';

class FaenaService {
  final ApiClient client;

  FaenaService(this.client);

  Future<List<Faena>> misFaenas() async {
    final response = await client.dio.get('/mis-faenas/');
    return (response.data as List)
        .map((e) => Faena.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<FaenaDetalle> detalleFaena(int id) async {
    final response = await client.dio.get('/faenas/$id/');
    return FaenaDetalle.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> actualizarEstado(int id, String nuevoEstado) async {
    await client.dio.patch(
      '/faenas/$id/estado/',
      data: {'estado_terreno': nuevoEstado},
    );
  }
}
