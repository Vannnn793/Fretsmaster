import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chord_guide.dart';
import '../../domain/entities/fretboard_context.dart';

/// FingerGuideOverlay: Menampilkan titik panduan jari pada senar dan fret target
/// sesuai orientasi FretboardAnchor aktif.
class FingerGuideOverlay extends StatelessWidget {
  final ChordGuide chordGuide;
  final FretboardAnchor anchor;

  const FingerGuideOverlay({
    super.key,
    required this.chordGuide,
    this.anchor = const FretboardAnchor(),
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FingerDotsPainter(
          chordGuide: chordGuide,
          anchor: anchor,
        ),
      ),
    );
  }
}

class _FingerDotsPainter extends CustomPainter {
  final ChordGuide chordGuide;
  final FretboardAnchor anchor;

  _FingerDotsPainter({
    required this.chordGuide,
    this.anchor = const FretboardAnchor(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width * anchor.width;
    final height = size.height * anchor.height;
    final cx = size.width * anchor.centerX;
    final cy = size.height * anchor.centerY;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(anchor.angleRad);

    final left = -width / 2;
    final top = -height / 2;

    final dotPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final glowPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // chordGuide.frets: array 6 angka [senar 6, 5, 4, 3, 2, 1]
    // chordGuide.fingers: nomor jari [1..4]
    for (int stringIdx = 0; stringIdx < 6; stringIdx++) {
      final fret = chordGuide.frets[stringIdx];
      final finger = chordGuide.fingers[stringIdx];

      if (fret > 0 && fret <= 5) {
        final col = anchor.mirrorStrings ? stringIdx : (5 - stringIdx);
        final x = left + 16 + ((width - 32) / 5) * col;
        final y = top + (height / 5) * (fret - 0.5);

        canvas.drawCircle(Offset(x, y), 16, glowPaint);
        canvas.drawCircle(Offset(x, y), 12, dotPaint);

        textPainter.text = TextSpan(
          text: finger > 0 ? '$finger' : '•',
          style: const TextStyle(
            color: Color(0xFF1A1200),
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, y - textPainter.height / 2),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FingerDotsPainter oldDelegate) {
    return oldDelegate.chordGuide != chordGuide || oldDelegate.anchor != anchor;
  }
}
