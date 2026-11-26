import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chord_guide.dart';

/// ChordDiagramView: Diagram akord gitar visual interaktif
class ChordDiagramView extends StatelessWidget {
  final ChordGuide chordGuide;
  final double width;
  final double height;

  const ChordDiagramView({
    super.key,
    required this.chordGuide,
    this.width = 180,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(
            chordGuide.name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
            ),
          ),
          Text(
            chordGuide.fullName,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              size: Size.infinite,
              painter: _DiagramPainter(chordGuide: chordGuide),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiagramPainter extends CustomPainter {
  final ChordGuide chordGuide;

  _DiagramPainter({required this.chordGuide});

  @override
  void paint(Canvas canvas, Size size) {
    final fretCount = 4;
    final stringCount = 6;
    final topOffset = 24.0;
    final bottomOffset = 12.0;
    final gridWidth = size.width - 32;
    final gridHeight = size.height - topOffset - bottomOffset;
    final leftOffset = 16.0;

    // Nut gitar (garis atas tebal)
    final nutPaint = Paint()
      ..color = AppColors.primaryLight
      ..strokeWidth = 3.5;
    canvas.drawLine(
      Offset(leftOffset, topOffset),
      Offset(leftOffset + gridWidth, topOffset),
      nutPaint,
    );

    // Garis fret
    final fretPaint = Paint()
      ..color = AppColors.surfaceBorder
      ..strokeWidth = 1.2;
    for (int f = 1; f <= fretCount; f++) {
      final y = topOffset + (gridHeight / fretCount) * f;
      canvas.drawLine(
        Offset(leftOffset, y),
        Offset(leftOffset + gridWidth, y),
        fretPaint,
      );
    }

    // Garis senar
    final stringPaint = Paint()
      ..color = AppColors.guitarString.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;
    for (int s = 0; s < stringCount; s++) {
      final x = leftOffset + (gridWidth / (stringCount - 1)) * s;
      canvas.drawLine(
        Offset(x, topOffset),
        Offset(x, topOffset + gridHeight),
        stringPaint,
      );
    }

    // Tanda di atas nut (x untuk mati, o untuk lepas)
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int s = 0; s < 6; s++) {
      final fret = chordGuide.frets[s];
      final x = leftOffset + (gridWidth / 5) * s;
      String marker = '';
      Color markerColor = AppColors.textMuted;

      if (fret == -1) {
        marker = '×';
        markerColor = AppColors.error;
      } else if (fret == 0) {
        marker = '○';
        markerColor = AppColors.success;
      }

      if (marker.isNotEmpty) {
        textPainter.text = TextSpan(
          text: marker,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: markerColor),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x - textPainter.width / 2, topOffset - 18));
      }
    }

    // Titik jari (frets > 0)
    final dotPaint = Paint()..color = AppColors.primary;
    for (int s = 0; s < 6; s++) {
      final fret = chordGuide.frets[s];
      final finger = chordGuide.fingers[s];
      if (fret > 0 && fret <= fretCount) {
        final x = leftOffset + (gridWidth / 5) * s;
        final y = topOffset + (gridHeight / fretCount) * (fret - 0.5);

        canvas.drawCircle(Offset(x, y), 9.0, dotPaint);

        if (finger > 0) {
          textPainter.text = TextSpan(
            text: '$finger',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF1A1200),
            ),
          );
          textPainter.layout();
          textPainter.paint(
            canvas,
            Offset(x - textPainter.width / 2, y - textPainter.height / 2),
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DiagramPainter oldDelegate) =>
      oldDelegate.chordGuide != chordGuide;
}
