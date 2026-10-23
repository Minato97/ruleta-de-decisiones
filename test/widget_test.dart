import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ruleta_decisiones/logic.dart';

void main() {
  test('el ángulo de reposo deja el sector elegido bajo la flecha', () {
    for (final n in [2, 3, 6, 8, 12]) {
      for (var i = 0; i < n; i++) {
        for (final j in [-1.0, -0.3, 0.0, 0.5, 1.0]) {
          final a = restAngle(index: i, count: n, jitter: j, turns: 5);
          expect(sectorAt(a, n), i, reason: 'n=$n i=$i j=$j');
        }
      }
    }
  });

  test('sectorAt es periódico', () {
    expect(sectorAt(0.3, 6), sectorAt(0.3 + 2 * pi, 6));
  });

  test('registro de giro se serializa', () {
    final r = SpinRecord(DateTime(2026, 10, 23, 12), 'Tacos', '¿Qué comemos?');
    final back = SpinRecord.parse(r.toLine())!;
    expect(back.result, 'Tacos');
    expect(back.wheel, '¿Qué comemos?');
  });
}
