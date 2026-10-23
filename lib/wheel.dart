import 'dart:math';

import 'package:flutter/material.dart';

import 'logic.dart';

class WheelPainter extends CustomPainter {
  WheelPainter(this.options, this.rotation, this.textColor, [this.fontFamily]);

  final List<String> options;
  final double rotation;
  final Color textColor;
  final String? fontFamily;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = min(size.width, size.height) / 2 - 6;
    final n = options.length;
    if (n == 0) return;
    final sector = 2 * pi / n;

    canvas.drawCircle(
      center,
      radius + 6,
      Paint()
        ..color = Colors.black12
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final rect = Rect.fromCircle(center: Offset.zero, radius: radius);
    for (var i = 0; i < n; i++) {
      final paint = Paint()..color = wheelColors[i % wheelColors.length];
      canvas.drawArc(rect, i * sector, sector, true, paint);
      canvas.drawArc(
        rect,
        i * sector,
        sector,
        true,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = Colors.white,
      );
      // Texto a lo largo del radio
      canvas.save();
      canvas.rotate(i * sector + sector / 2);
      final label = options[i].length > 14
          ? '${options[i].substring(0, 13)}…'
          : options[i];
      final tp = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            fontFamily: fontFamily,
            color: Colors.white,
            fontSize: n > 10 ? 13 : 17,
            fontWeight: FontWeight.w700,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: radius * 0.62);
      tp.paint(canvas, Offset(radius * 0.30, -tp.height / 2));
      canvas.restore();
    }
    canvas.restore();

    // Centro
    canvas.drawCircle(center, 26, Paint()..color = Colors.white);
    canvas.drawCircle(
      center,
      26,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..color = textColor.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(WheelPainter old) =>
      old.rotation != rotation || old.options != options;
}

class PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2 - 16, 0)
      ..lineTo(size.width / 2 + 16, 0)
      ..lineTo(size.width / 2, 34)
      ..close();
    canvas.drawShadow(path, Colors.black, 4, true);
    canvas.drawPath(path, Paint()..color = const Color(0xFF111827));
  }

  @override
  bool shouldRepaint(PointerPainter old) => false;
}
