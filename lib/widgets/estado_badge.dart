import 'package:flutter/material.dart';

import '../models/faena.dart';

class EstadoTerrenoBadge extends StatelessWidget {
  final String estadoTerreno;

  const EstadoTerrenoBadge({super.key, required this.estadoTerreno});

  Color _color() {
    switch (estadoTerreno) {
      case 'en_traslado':
        return Colors.blue.shade700;
      case 'en_faena':
        return Colors.orange.shade800;
      case 'completada':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        estadoTerrenoLabel[estadoTerreno] ?? estadoTerreno,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }
}
