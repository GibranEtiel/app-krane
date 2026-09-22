import 'dart:io';

import 'package:dio/dio.dart';
import 'package:intl/intl.dart';

import '../models/documento.dart';
import 'api_client.dart';

class DocumentoService {
  final ApiClient client;

  DocumentoService(this.client);

  final _formatoFechaApi = DateFormat('yyyy-MM-dd');

  Future<List<DocumentoOperador>> misDocumentos() async {
    final response = await client.dio.get('/documentos/');
    return (response.data as List)
        .map((e) => DocumentoOperador.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> subirDocumento({
    required String tipoDocumento,
    required File archivo,
    DateTime? fechaVencimiento,
  }) async {
    final formData = FormData.fromMap({
      'tipo_documento': tipoDocumento,
      'archivo': await MultipartFile.fromFile(
        archivo.path,
        filename: archivo.path.split(Platform.pathSeparator).last,
      ),
      if (fechaVencimiento != null)
        'fecha_vencimiento': _formatoFechaApi.format(fechaVencimiento),
    });
    await client.dio.post('/documentos/', data: formData);
  }
}
