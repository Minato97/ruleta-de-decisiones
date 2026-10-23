import 'dart:math';

import 'package:flutter/material.dart';

const wheelColors = <Color>[
  Color(0xFFEF4444),
  Color(0xFFF59E0B),
  Color(0xFF10B981),
  Color(0xFF3B82F6),
  Color(0xFF8B5CF6),
  Color(0xFFEC4899),
  Color(0xFF14B8A6),
  Color(0xFFF97316),
];

class Preset {
  const Preset(this.name, this.icon, this.options);

  final String name;
  final IconData icon;
  final List<String> options;
}

const presets = <Preset>[
  Preset('¿Qué comemos?', Icons.restaurant, [
    'Tacos',
    'Pizza',
    'Sushi',
    'Hamburguesas',
    'Ensalada',
    'Pasta',
  ]),
  Preset('Sí o no', Icons.help_outline, ['Sí', 'No']),
  Preset('¿Quién empieza?', Icons.groups, [
    'Persona 1',
    'Persona 2',
    'Persona 3',
  ]),
  Preset('Plan de hoy', Icons.today, [
    'Cine',
    'Caminar',
    'Leer',
    'Videojuegos',
    'Cocinar',
    'Descansar',
  ]),
  Preset('Dado', Icons.casino, ['1', '2', '3', '4', '5', '6']),
];

/// Ángulo de reposo (radianes) que deja el sector [index] bajo la flecha
/// superior. [jitter] va de -0.4 a 0.4 y mueve el punto dentro del sector.
double restAngle({
  required int index,
  required int count,
  required double jitter,
  required int turns,
}) {
  final sector = 2 * pi / count;
  final center = (index + 0.5 + jitter * 0.4) * sector;
  return -pi / 2 - center + 2 * pi * turns;
}

/// Sector que queda bajo la flecha superior para un ángulo de giro dado.
int sectorAt(double rotation, int count) {
  final sector = 2 * pi / count;
  var a = (-pi / 2 - rotation) % (2 * pi);
  if (a < 0) a += 2 * pi;
  return (a / sector).floor() % count;
}

class SpinRecord {
  const SpinRecord(this.when, this.result, this.wheel);

  final DateTime when;
  final String result;
  final String wheel;

  String toLine() => '${when.toIso8601String()}|$result|$wheel';

  static SpinRecord? parse(String s) {
    final p = s.split('|');
    if (p.length < 3) return null;
    final d = DateTime.tryParse(p[0]);
    if (d == null) return null;
    return SpinRecord(d, p[1], p.sublist(2).join('|'));
  }
}
