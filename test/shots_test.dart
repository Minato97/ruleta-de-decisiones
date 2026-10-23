// SHOTS=1 flutter test test/shots_test.dart  -> store/screenshot_N.png
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ruleta_decisiones/logic.dart';
import 'package:ruleta_decisiones/main.dart';

Future<void> _font(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future.value(ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

void main() {
  final enabled = Platform.environment['SHOTS'] == '1';
  testWidgets('capturas', skip: !enabled, (tester) async {
    final sdk =
        Platform.environment['FLUTTER_ROOT'] ??
        File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    final fonts = '$sdk/bin/cache/artifacts/material_fonts';
    await _font('Roboto', '$fonts/roboto-regular.ttf');
    await _font('Roboto', '$fonts/roboto-bold.ttf');
    await _font('MaterialIcons', '$fonts/materialicons-regular.otf');

    tester.view.devicePixelRatio = 2.625;
    tester.view.physicalSize = const Size(1080, 2160);
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    final history = [
      SpinRecord(DateTime(2026, 10, 22, 21, 5), 'Tacos', '¿Qué comemos?'),
      SpinRecord(DateTime(2026, 10, 22, 19, 40), 'Sí', 'Sí o no'),
      SpinRecord(DateTime(2026, 10, 21, 18, 12), 'Cine', 'Plan de hoy'),
      SpinRecord(DateTime(2026, 10, 21, 13, 2), 'Persona 2', '¿Quién empieza?'),
      SpinRecord(DateTime(2026, 10, 20, 20, 30), '4', 'Dado'),
    ];

    Widget app(Widget body, String title, int tab) => RepaintBoundary(
      key: key,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: const Color(0xFF8B5CF6),
          useMaterial3: true,
          fontFamily: 'Roboto',
        ),
        home: Scaffold(
          appBar: AppBar(title: Text(title)),
          body: body,
          bottomNavigationBar: NavigationBar(
            selectedIndex: tab,
            destinations: const [
              NavigationDestination(icon: Icon(Icons.casino), label: 'Ruleta'),
              NavigationDestination(
                icon: Icon(Icons.history),
                label: 'Historial',
              ),
            ],
          ),
        ),
      ),
    );

    Future<void> save(String name) async {
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage(pixelRatio: 2.625);
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        File('store/$name').writeAsBytesSync(data!.buffer.asUint8List());
      });
    }

    // 1: ruleta inicial
    await tester.pumpWidget(app(WheelPage(onResult: (_) {}), 'Ruleta', 0));
    await tester.pumpAndSettle();
    await save('screenshot_1.png');

    // 2: otro preset
    await tester.drag(find.byType(ListView).at(1), const Offset(-300, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plan de hoy'));
    await tester.pumpAndSettle();
    await save('screenshot_2.png');

    // 3: tras girar, con el resultado
    await tester.tap(find.text('GIRAR'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
    await tester.tap(find.text('Cerrar'));
    await tester.pumpAndSettle();
    await save('screenshot_3.png');

    // 4: historial
    await tester.pumpWidget(
      app(HistoryPage(history: history, onClear: () {}), 'Historial', 1),
    );
    await tester.pumpAndSettle();
    await save('screenshot_4.png');
  });
}
