import 'package:flutter/material.dart';
import '../../domain/photo.dart';

class TimelineNodePainter extends CustomPainter {
  final List<int> years;
  final int? selectedYear;
  final Map<int, List<Photo>> photosByYear;
  final Color primaryColor;
  final int Function(int) getNodeSize;
  final double Function(int, int) getLineThickness;
  final int birthYear;

  const TimelineNodePainter({
    required this.years,
    required this.selectedYear,
    required this.photosByYear,
    required this.primaryColor,
    required this.getNodeSize,
    required this.getLineThickness,
    required this.birthYear,
  });

  static const double nodeSpacing = 80.0;
  static const double axisY = 70.0;

  @override
  void paint(Canvas canvas, Size size) {
    _drawLines(canvas);
    _drawNodes(canvas);
  }

  void _drawLines(Canvas canvas) {
    for (int i = 0; i < years.length - 1; i++) {
      final y1 = years[i];
      final y2 = years[i + 1];
      final x1 = i * nodeSpacing;
      final x2 = (i + 1) * nodeSpacing;

      final hasContent1 = photosByYear[y1]?.isNotEmpty ?? false;
      final hasContent2 = photosByYear[y2]?.isNotEmpty ?? false;
      final isDense = hasContent1 || hasContent2;

      final paint = Paint()
        ..color = isDense
            ? primaryColor.withOpacity(0.35)
            : Colors.grey.shade300
        ..strokeWidth = isDense ? 3.5 : 2.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(x1, axisY), Offset(x2, axisY), paint);
    }
  }

  void _drawNodes(Canvas canvas) {
    for (int i = 0; i < years.length; i++) {
      final year = years[i];
      final x = i * nodeSpacing;
      final isBirth = year == birthYear;
      final isSelected = year == selectedYear;
      final photos = photosByYear[year] ?? [];
      final count = photos.length;

      if (isBirth) {
        _drawBirthNode(canvas, Offset(x, axisY), isSelected);
      } else if (count >= 4) {
        _drawLargeNode(canvas, Offset(x, axisY), isSelected);
      } else if (count > 0) {
        _drawMediumNode(canvas, Offset(x, axisY), isSelected);
      } else {
        _drawEmptyNode(canvas, Offset(x, axisY), isSelected);
      }
    }
  }

  void _drawBirthNode(Canvas canvas, Offset center, bool isSelected) {
    final fillPaint = Paint()
      ..color = const Color(0xFFFAEEDA)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = const Color(0xFFEF9F27)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 18, fillPaint);
    canvas.drawCircle(center, 18, borderPaint);

    final tp = TextPainter(
      text: const TextSpan(
        text: '✦',
        style: TextStyle(fontSize: 16, color: Color(0xFFBA7517)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  void _drawLargeNode(Canvas canvas, Offset center, bool isSelected) {
    final fillPaint = Paint()
      ..color = isSelected ? primaryColor : primaryColor.withOpacity(0.15)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = primaryColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 16, fillPaint);
    canvas.drawCircle(center, 16, borderPaint);

    if (isSelected) {
      final glowPaint = Paint()
        ..color = primaryColor.withOpacity(0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 22, glowPaint);
    }
  }

  void _drawMediumNode(Canvas canvas, Offset center, bool isSelected) {
    final fillPaint = Paint()
      ..color = isSelected ? primaryColor : Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isSelected ? primaryColor : Colors.grey.shade500
      ..strokeWidth = isSelected ? 3 : 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 11, fillPaint);
    canvas.drawCircle(center, 11, borderPaint);
  }

  void _drawEmptyNode(Canvas canvas, Offset center, bool isSelected) {
    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = isSelected ? primaryColor : Colors.grey.shade400
      ..strokeWidth = isSelected ? 2.5 : 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 7, fillPaint);
    canvas.drawCircle(center, 7, borderPaint);
  }

  @override
  bool shouldRepaint(covariant TimelineNodePainter old) =>
      old.selectedYear != selectedYear ||
      old.years != years ||
      old.photosByYear != photosByYear;
}