import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/documento.dart';
import '../services/documento_service.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  late Future<List<DocumentoOperador>> _futureDocumentos;
  final _formatoFecha = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  void _cargar() {
    _futureDocumentos = context.read<DocumentoService>().misDocumentos();
  }

  Future<void> _refrescar() async {
    setState(_cargar);
    await _futureDocumentos;
  }

  Future<void> _abrirFormularioSubida() async {
    final subido = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FormularioSubirDocumento(),
    );
    if (subido == true) _refrescar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Documentos')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirFormularioSubida,
        icon: const Icon(Icons.upload_file),
        label: const Text('Subir Documento'),
      ),
      body: RefreshIndicator(
        onRefresh: _refrescar,
        child: FutureBuilder<List<DocumentoOperador>>(
          future: _futureDocumentos,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _mensajeVacio(
                icono: Icons.wifi_off,
                texto: 'No se pudo cargar tus documentos.\nDesliza hacia abajo para reintentar.',
              );
            }
            final documentos = snapshot.data ?? [];
            if (documentos.isEmpty) {
              return _mensajeVacio(
                icono: Icons.folder_open,
                texto: 'Aún no has subido ningún documento.\nToca "Subir Documento" para empezar.',
              );
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
              itemCount: documentos.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) =>
                  _DocumentoCard(documento: documentos[index], formatoFecha: _formatoFecha),
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

class _DocumentoCard extends StatelessWidget {
  final DocumentoOperador documento;
  final DateFormat formatoFecha;

  const _DocumentoCard({required this.documento, required this.formatoFecha});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade300)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    tipoDocumentoLabel[documento.tipoDocumento] ?? documento.tipoDocumento,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                _EstadoDocumentoBadge(documento: documento),
              ],
            ),
            const SizedBox(height: 8),
            if (documento.fechaVencimiento != null)
              Row(children: [
                Icon(
                  Icons.event,
                  size: 15,
                  color: documento.estaVencido
                      ? Colors.red
                      : (documento.estaPorVencer ? Colors.orange.shade800 : Colors.grey),
                ),
                const SizedBox(width: 6),
                Text(
                  'Vence: ${formatoFecha.format(documento.fechaVencimiento!)}',
                  style: TextStyle(
                    color: documento.estaVencido
                        ? Colors.red
                        : (documento.estaPorVencer ? Colors.orange.shade800 : Colors.black87),
                    fontWeight:
                        (documento.estaVencido || documento.estaPorVencer) ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ]),
            if (documento.estado == 'rechazado' && documento.motivoRechazo.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Motivo del rechazo: ${documento.motivoRechazo}', style: const TextStyle(color: Colors.red, fontSize: 13)),
            ],
            const SizedBox(height: 4),
            Text('Subido el ${formatoFecha.format(documento.subidoEn)}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _EstadoDocumentoBadge extends StatelessWidget {
  final DocumentoOperador documento;

  const _EstadoDocumentoBadge({required this.documento});

  @override
  Widget build(BuildContext context) {
    Color color;
    String texto;
    if (documento.estado == 'aprobado' && documento.estaVencido) {
      color = Colors.red.shade700;
      texto = 'Vencido';
    } else if (documento.estado == 'aprobado' && documento.estaPorVencer) {
      color = Colors.orange.shade800;
      texto = 'Por vencer';
    } else if (documento.estado == 'aprobado') {
      color = Colors.green.shade700;
      texto = 'Aprobado';
    } else if (documento.estado == 'rechazado') {
      color = Colors.red.shade700;
      texto = 'Rechazado';
    } else {
      color = Colors.grey.shade600;
      texto = 'Pendiente';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(texto, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12)),
    );
  }
}

class _FormularioSubirDocumento extends StatefulWidget {
  const _FormularioSubirDocumento();

  @override
  State<_FormularioSubirDocumento> createState() => _FormularioSubirDocumentoState();
}

class _FormularioSubirDocumentoState extends State<_FormularioSubirDocumento> {
  String _tipoSeleccionado = tiposDocumento.first;
  File? _archivo;
  DateTime? _fechaVencimiento;
  bool _subiendo = false;
  String? _error;

  Future<void> _elegirImagen(ImageSource fuente) async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: fuente, imageQuality: 85);
    if (xfile != null) setState(() => _archivo = File(xfile.path));
  }

  Future<void> _elegirFecha() async {
    final ahora = DateTime.now();
    final fecha = await showDatePicker(
      context: context,
      initialDate: ahora,
      firstDate: ahora.subtract(const Duration(days: 1)),
      lastDate: DateTime(ahora.year + 10),
    );
    if (fecha != null) setState(() => _fechaVencimiento = fecha);
  }

  Future<void> _subir() async {
    if (_archivo == null) {
      setState(() => _error = 'Debes adjuntar una foto del documento.');
      return;
    }
    final documentoService = context.read<DocumentoService>();
    setState(() {
      _subiendo = true;
      _error = null;
    });
    try {
      await documentoService.subirDocumento(
        tipoDocumento: _tipoSeleccionado,
        archivo: _archivo!,
        fechaVencimiento: _fechaVencimiento,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No se pudo subir el documento. Revisa tu conexión.');
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subir Documento', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _tipoSeleccionado,
            decoration: const InputDecoration(labelText: 'Tipo de documento', border: OutlineInputBorder()),
            items: tiposDocumento
                .map((t) => DropdownMenuItem(value: t, child: Text(tipoDocumentoLabel[t] ?? t)))
                .toList(),
            onChanged: (v) => setState(() => _tipoSeleccionado = v!),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _elegirFecha,
            icon: const Icon(Icons.event),
            label: Text(
              _fechaVencimiento == null
                  ? 'Fecha de vencimiento (opcional)'
                  : 'Vence: ${DateFormat('dd/MM/yyyy').format(_fechaVencimiento!)}',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirImagen(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Cámara'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _elegirImagen(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Galería'),
                ),
              ),
            ],
          ),
          if (_archivo != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(_archivo!, height: 140, width: double.infinity, fit: BoxFit.cover),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _subiendo ? null : _subir,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF57C00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _subiendo
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Subir'),
            ),
          ),
        ],
      ),
    );
  }
}
