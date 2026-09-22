const List<String> tiposDocumento = [
  'licencia_conducir',
  'permiso_circulacion',
  'revision_tecnica',
  'soap',
];

const Map<String, String> tipoDocumentoLabel = {
  'licencia_conducir': 'Licencia de Conducir',
  'permiso_circulacion': 'Permiso de Circulación',
  'revision_tecnica': 'Revisión Técnica',
  'soap': 'SOAP',
};

class DocumentoOperador {
  final int id;
  final String tipoDocumento;
  final String archivoUrl;
  final DateTime? fechaVencimiento;
  final String estado;
  final String motivoRechazo;
  final DateTime subidoEn;
  final bool estaVencido;
  final bool estaPorVencer;

  DocumentoOperador({
    required this.id,
    required this.tipoDocumento,
    required this.archivoUrl,
    required this.fechaVencimiento,
    required this.estado,
    required this.motivoRechazo,
    required this.subidoEn,
    required this.estaVencido,
    required this.estaPorVencer,
  });

  factory DocumentoOperador.fromJson(Map<String, dynamic> json) {
    return DocumentoOperador(
      id: json['id'] as int,
      tipoDocumento: json['tipo_documento'] as String,
      archivoUrl: json['archivo'] as String,
      fechaVencimiento: json['fecha_vencimiento'] != null
          ? DateTime.parse(json['fecha_vencimiento'] as String)
          : null,
      estado: json['estado'] as String,
      motivoRechazo: (json['motivo_rechazo'] as String?) ?? '',
      subidoEn: DateTime.parse(json['subido_en'] as String),
      estaVencido: json['esta_vencido'] as bool,
      estaPorVencer: json['esta_por_vencer'] as bool,
    );
  }
}
