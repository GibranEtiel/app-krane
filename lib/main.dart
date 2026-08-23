import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'screens/faenas_screen.dart';
import 'screens/login_screen.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/faena_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CL', null);
  runApp(const KraneOperadorApp());
}

class KraneOperadorApp extends StatelessWidget {
  const KraneOperadorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService()..cargarSesion(),
      child: Consumer<AuthService>(
        builder: (context, auth, _) {
          return MultiProvider(
            providers: [
              Provider<ApiClient>(create: (_) => ApiClient(auth)),
              ProxyProvider<ApiClient, FaenaService>(
                update: (_, apiClient, _) => FaenaService(apiClient),
              ),
            ],
            child: MaterialApp(
              title: 'KraneChile Operador',
              debugShowCheckedModeBanner: false,
              locale: const Locale('es', 'CL'),
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              supportedLocales: const [Locale('es', 'CL')],
              theme: ThemeData(
                colorSchemeSeed: const Color(0xFFF57C00),
                useMaterial3: true,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                ),
              ),
              home: auth.isLoading
                  ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                  : (auth.isAuthenticated ? const FaenasScreen() : const LoginScreen()),
            ),
          );
        },
      ),
    );
  }
}
