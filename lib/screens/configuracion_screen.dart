import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_client.dart';
import '../services/auth_service.dart';

/// Permite cambiar la URL del backend sin recompilar la app — pensada para
/// cuando se prueba/demuestra en una red distinta (por ejemplo, el hotspot
/// del celular) y no se sabe la IP de antemano.
class ConfiguracionScreen extends StatefulWidget {
  const ConfiguracionScreen({super.key});

  @override
  State<ConfiguracionScreen> createState() => _ConfiguracionScreenState();
}

class _ConfiguracionScreenState extends State<ConfiguracionScreen> {
  late final TextEditingController _urlCtrl;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _urlCtrl = TextEditingController(text: context.read<AuthService>().baseUrl);
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    var url = _urlCtrl.text.trim();
    if (url.isEmpty) return;
    if (url.endsWith('/')) url = url.substring(0, url.length - 1);

    final auth = context.read<AuthService>();
    final apiClient = context.read<ApiClient>();

    setState(() => _guardando = true);
    await auth.actualizarServidor(url);
    apiClient.actualizarBaseUrl(url);
    setState(() => _guardando = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Servidor actualizado.')),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración del servidor')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dirección del backend (Django). Cambia esto si cambiaste de red '
              'WiFi o de hotspot y la app no logra conectarse.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL base de la API',
                hintText: 'http://192.168.1.50:8000/api/v1/operador',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ejemplo: http://<IP del computador>:8000/api/v1/operador',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _guardando ? null : _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _guardando
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
