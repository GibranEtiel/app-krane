import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/faena.dart';
import '../services/faena_service.dart';
import '../services/ubicacion_background_service.dart';
import '../widgets/estado_badge.dart';

class FaenaDetailScreen extends StatefulWidget {
  final int faenaId;

  const FaenaDetailScreen({super.key, required this.faenaId});

  @override
  State<FaenaDetailScreen> createState() => _FaenaDetailScreenState();
}

class _FaenaDetailScreenState extends State<FaenaDetailScreen> {
  late Future<FaenaDetalle> _futureDetalle;
  bool _actualizando = false;
  bool _siguiendoUbicacion = false;
  final _formatoFecha = DateFormat('EEEE dd/MM/yyyy · HH:mm', 'es_CL');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureDetalle = context.read<FaenaService>().detalleFaena(widget.faenaId);
    _futureDetalle
        .then((faena) => _sincronizarSeguimiento(faena.estadoTerreno))
        .catchError((_) {});
  }

  /// Mantiene el envío de ubicación encendido solo mientras la faena está
  /// "En Traslado" (única condición que el backend acepta).
  void _sincronizarSeguimiento(String estadoTerreno) {
    if (estadoTerreno == 'en_traslado') {
      _iniciarSeguimiento();
    } else {
      _detenerSeguimiento();
    }
  }

  /// El envío ahora corre en un servicio en primer plano (ver
  /// UbicacionBackgroundService) que sigue vivo aunque el operador minimice
  /// la app o salga de esta pantalla — antes se cortaba porque dependía de
  /// un Timer atado al ciclo de vida de este widget.
  Future<void> _iniciarSeguimiento() async {
    if (_siguiendoUbicacion) return;

    var permiso = await Geolocator.checkPermission();
    if (permiso == LocationPermission.denied) {
      permiso = await Geolocator.requestPermission();
    }
    if (permiso == LocationPermission.denied || permiso == LocationPermission.deniedForever) {
      return;
    }

    // Compartir la ubicación con la app minimizada requiere el permiso
    // "Permitir todo el tiempo". Desde Android 11, el sistema no deja pedirlo
    // en el mismo diálogo que el permiso normal: hay que guiar al operador a
    // Ajustes para activarlo aparte.
    if (permiso != LocationPermission.always && mounted) {
      final irAAjustes = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Ubicación en segundo plano'),
          content: const Text(
            'Para que el cliente pueda seguir la grúa aunque minimices la app, '
            'activa "Permitir todo el tiempo" en el permiso de ubicación.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Ahora no'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ir a Ajustes'),
            ),
          ],
        ),
      );
      if (irAAjustes == true) {
        await Geolocator.openAppSettings();
      }
    }

    await UbicacionBackgroundService.iniciar(widget.faenaId);
    _siguiendoUbicacion = true;
  }

  void _detenerSeguimiento() {
    if (!_siguiendoUbicacion) return;
    UbicacionBackgroundService.detener();
    _siguiendoUbicacion = false;
  }

  Future<void> _avanzarEstado(FaenaDetalle actual) async {
    final indiceActual = estadoTerrenoOrden.indexOf(actual.estadoTerreno);
    if (indiceActual == -1 || indiceActual >= estadoTerrenoOrden.length - 1) return;
    final siguienteEstado = estadoTerrenoOrden[indiceActual + 1];

    setState(() => _actualizando = true);
    try {
      await context.read<FaenaService>().actualizarEstado(widget.faenaId, siguienteEstado);
      if (!mounted) return;
      _sincronizarSeguimiento(siguienteEstado);
      setState(_cargar);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el estado. Revisa tu conexión.')),
      );
    } finally {
      if (mounted) setState(() => _actualizando = false);
    }
  }

  Future<void> _llamar(String telefono) async {
    final uri = Uri(scheme: 'tel', path: telefono);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _copiarLinkSeguimiento(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copiado')),
    );
  }

  Future<void> _compartirPorWhatsApp(String url) async {
    final mensaje = Uri.encodeComponent(
      'Puedes seguir en vivo la llegada de la grúa aquí: $url',
    );
    final uri = Uri.parse('https://wa.me/?text=$mensaje');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirMapa(String direccion, String comuna) async {
    final query = Uri.encodeComponent('$direccion, $comuna, Chile');
    final uri = Uri.parse('geo:0,0?q=$query');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Faena #${widget.faenaId}')),
      body: FutureBuilder<FaenaDetalle>(
        future: _futureDetalle,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('No se pudo cargar la faena.'));
          }
          final faena = snapshot.data!;
          final esUltimoEstado = faena.estadoTerreno == estadoTerrenoOrden.last;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estado en terreno', style: TextStyle(color: Colors.grey, fontSize: 13)),
                  EstadoTerrenoBadge(estadoTerreno: faena.estadoTerreno),
                ],
              ),
              const SizedBox(height: 20),

              _seccion('Fecha y hora', [
                Text(_formatoFecha.format(faena.fechaInicio)),
                Text('Término estimado: ${_formatoFecha.format(faena.fechaFin)}', style: const TextStyle(color: Colors.grey)),
              ]),

              _seccion('Ubicación', [
                Text('${faena.direccionServicio}, ${faena.comuna}'),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _abrirMapa(faena.direccionServicio, faena.comuna),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Abrir en Mapas'),
                ),
              ]),

              _seccion('Maquinaria', [
                for (final item in faena.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• ${item.cantidad}x ${item.nombreEquipo}'),
                  ),
              ]),

              if (faena.observaciones.isNotEmpty)
                _seccion('Observaciones técnicas', [Text(faena.observaciones)]),

              _seccion('Seguimiento en vivo para el cliente', [
                Text(
                  faena.estadoTerreno == 'en_traslado'
                      ? 'Se está compartiendo tu ubicación. Envíale este link al cliente para que vea la grúa en el mapa:'
                      : 'Este link se activa solo mientras marques "En Traslado". Puedes compartirlo antes igual.',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 8),
                SelectableText(faena.trackingUrl, style: const TextStyle(fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _copiarLinkSeguimiento(faena.trackingUrl),
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copiar'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _compartirPorWhatsApp(faena.trackingUrl),
                        icon: const Icon(Icons.share_outlined, size: 18),
                        label: const Text('WhatsApp'),
                      ),
                    ),
                  ],
                ),
              ]),

              _seccion('Contacto del cliente', [
                Text(faena.cliente.nombre),
                if (faena.cliente.telefono.isNotEmpty) Text(faena.cliente.telefono, style: const TextStyle(color: Colors.grey)),
                if (faena.cliente.email.isNotEmpty) Text(faena.cliente.email, style: const TextStyle(color: Colors.grey)),
                if (faena.cliente.telefono.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _llamar(faena.cliente.telefono),
                    icon: const Icon(Icons.call_outlined),
                    label: const Text('Llamar al cliente'),
                  ),
                ],
              ]),

              const SizedBox(height: 12),
              if (!esUltimoEstado)
                ElevatedButton.icon(
                  onPressed: _actualizando ? null : () => _avanzarEstado(faena),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D6EFD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _actualizando
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.arrow_forward),
                  label: Text(
                    'Marcar como "${estadoTerrenoLabel[estadoTerrenoOrden[estadoTerrenoOrden.indexOf(faena.estadoTerreno) + 1]]}"',
                  ),
                )
              else
                const Center(child: Text('Faena completada ✅', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600))),
            ],
          );
        },
      ),
    );
  }

  Widget _seccion(String titulo, List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titulo, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          ...children,
        ],
      ),
    );
  }
}
