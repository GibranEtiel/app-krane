import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/faena.dart';
import '../services/auth_service.dart';
import '../services/faena_service.dart';
import '../widgets/estado_badge.dart';
import 'faena_detail_screen.dart';

class FaenasScreen extends StatefulWidget {
  const FaenasScreen({super.key});

  @override
  State<FaenasScreen> createState() => _FaenasScreenState();
}

class _FaenasScreenState extends State<FaenasScreen> {
  late Future<List<Faena>> _futureFaenas;
  final _formatoFecha = DateFormat('EEE dd/MM · HH:mm', 'es_CL');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    final service = context.read<FaenaService>();
    _futureFaenas = service.misFaenas();
  }

  Future<void> _refrescar() async {
    setState(_cargar);
    await _futureFaenas;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Faenas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthService>().logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<Faena>>(
          future: _futureFaenas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _mensajeVacio(
                icono: Icons.wifi_off,
                texto: 'No se pudo cargar la hoja de ruta.\nDesliza hacia abajo para reintentar.',
              );
            }
            final faenas = snapshot.data ?? [];
            if (faenas.isEmpty) {
              return _mensajeVacio(
                icono: Icons.event_available,
                texto: 'No tienes faenas asignadas por ahora.',
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: faenas.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _FaenaCard(
                faena: faenas[index],
                formatoFecha: _formatoFecha,
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FaenaDetailScreen(faenaId: faenas[index].id),
                  ));
                  _refrescar();
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _mensajeVacio({required IconData icono, required String texto}) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icono, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text(texto, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FaenaCard extends StatelessWidget {
  final Faena faena;
  final DateFormat formatoFecha;
  final VoidCallback onTap;

  const _FaenaCard({required this.faena, required this.formatoFecha, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Faena #${faena.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  EstadoTerrenoBadge(estadoTerreno: faena.estadoTerreno),
                ],
              ),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.calendar_today, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Text(formatoFecha.format(faena.fechaInicio), style: const TextStyle(color: Colors.black87)),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.place_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('${faena.direccionServicio}, ${faena.comuna}', overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 4),
              Row(children: [
                const Icon(Icons.precision_manufacturing_outlined, size: 15, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(child: Text(faena.equipos.join(', '), overflow: TextOverflow.ellipsis)),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
