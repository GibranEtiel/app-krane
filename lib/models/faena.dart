class Faena {
  final int id;
  final String estado;
  final String estadoTerreno;
  final String comuna;
  final String direccionServicio;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final List<String> equipos;

  Faena({
    required this.id,
    required this.estado,
    required this.estadoTerreno,
    required this.comuna,
    required this.direccionServicio,
    required this.fechaInicio,
    required this.fechaFin,
    required this.equipos,
  });

  factory Faena.fromJson(Map<String, dynamic> json) {
    return Faena(
      id: json['id'] as int,
      estado: json['estado'] as String,
      estadoTerreno: json['estado_terreno'] as String,
      comuna: json['comuna'] as String,
      direccionServicio: json['direccion_servicio'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      equipos: (json['equipos'] as List).map((e) => e.toString()).toList(),
    );
  }
}

class ItemFaena {
  final int id;
  final String nombreEquipo;
  final String tipoItem;
  final int cantidad;

  ItemFaena({
    required this.id,
    required this.nombreEquipo,
    required this.tipoItem,
    required this.cantidad,
  });

  factory ItemFaena.fromJson(Map<String, dynamic> json) {
    return ItemFaena(
      id: json['id'] as int,
      nombreEquipo: json['nombre_equipo'] as String,
      tipoItem: json['tipo_item'] as String,
      cantidad: json['cantidad'] as int,
    );
  }
}

class ClienteFaena {
  final String nombre;
  final String telefono;
  final String email;

  ClienteFaena({required this.nombre, required this.telefono, required this.email});

  factory ClienteFaena.fromJson(Map<String, dynamic> json) {
    return ClienteFaena(
      nombre: json['nombre'] as String,
      telefono: (json['telefono'] as String?) ?? '',
      email: (json['email'] as String?) ?? '',
    );
  }
}

class FaenaDetalle extends Faena {
  final String observaciones;
  final List<ItemFaena> items;
  final ClienteFaena cliente;

  FaenaDetalle({
    required super.id,
    required super.estado,
    required super.estadoTerreno,
    required super.comuna,
    required super.direccionServicio,
    required super.fechaInicio,
    required super.fechaFin,
    required this.observaciones,
    required this.items,
    required this.cliente,
  }) : super(equipos: items.map((i) => i.nombreEquipo).toList());

  factory FaenaDetalle.fromJson(Map<String, dynamic> json) {
    return FaenaDetalle(
      id: json['id'] as int,
      estado: json['estado'] as String,
      estadoTerreno: json['estado_terreno'] as String,
      comuna: json['comuna'] as String,
      direccionServicio: json['direccion_servicio'] as String,
      fechaInicio: DateTime.parse(json['fecha_inicio'] as String),
      fechaFin: DateTime.parse(json['fecha_fin'] as String),
      observaciones: (json['observaciones'] as String?) ?? '',
      items: (json['items'] as List)
          .map((e) => ItemFaena.fromJson(e as Map<String, dynamic>))
          .toList(),
      cliente: ClienteFaena.fromJson(json['cliente'] as Map<String, dynamic>),
    );
  }
}

/// Estados de terreno en el orden en que ocurren durante una faena.
const List<String> estadoTerrenoOrden = [
  'sin_iniciar',
  'en_traslado',
  'en_faena',
  'completada',
];

const Map<String, String> estadoTerrenoLabel = {
  'sin_iniciar': 'Sin Iniciar',
  'en_traslado': 'En Traslado',
  'en_faena': 'En Faena',
  'completada': 'Completada',
};
