// Smoke test: verifica que la app arranca y muestra la pantalla de carga
// inicial mientras se restaura la sesión guardada.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:krane_operador_app/main.dart';

void main() {
  testWidgets('La app arranca sin errores', (WidgetTester tester) async {
    await tester.pumpWidget(const KraneOperadorApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
