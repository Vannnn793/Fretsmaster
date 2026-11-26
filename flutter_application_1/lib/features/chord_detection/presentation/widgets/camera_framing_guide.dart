import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/fretboard_context.dart';

/// CameraFramingGuide: Panduan visual fretboard 1–5 terorientasi di layar kamera.
/// Mendukung translasi, rotasi, skala, dan mirror agar selaras 1:1 dengan FretboardAnalyzer.
class CameraFramingGuide extends StatelessWidget {
  final List<FretboardFingertip> detectedFingertips;
  final FretboardAnchor anchor;
  final bool isCalibrating;

  const CameraFramingGuide({
    super.key,
    this.detectedFingertips = const [],
    this.anchor = const FretboardAnchor(),
    this.isCalibrating = false,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: Size.infinite,
        painter: _FramingGuidePainter(
          detectedFingertips: detectedFingertips,
          anchor: anchor,
          isCalibrating: isCalibrating,
        ),
      ),
    );
  }
}

class _FramingGuidePainter extends CustomPainter {
  final List<FretboardFingertip> detectedFingertips;
  final FretboardAnchor anchor;
  final bool isCalibrating;

  _FramingGuidePainter({
    this.detectedFingertips = const [],
    this.anchor = const FretboardAnchor(),
    this.isCalibrating = false,
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
    final rect = Rect.fromLTWH(left, top, width, height);

    // Border kotak fokus luar
    final borderPaint = Paint()
      ..color = isCalibrating
          ? AppColors.primary.withValues(alpha: 0.85)
          : AppColors.primary.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCalibrating ? 2.5 : 1.8;

    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16));
    canvas.drawRRect(rrect, borderPaint);

    // Nut Bar di sisi atas kotak (penanda batas Fret 0 / Kepala Gitar)
    final nutPaint = Paint()
      ..color = AppColors.primaryLight.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(left + 14, top + 2),
      Offset(left + width - 14, top + 2),
      nutPaint,
    );

    // Corner Accents (Gaya viewfinder panggung modern)
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    const cornerLen = 26.0;
    // Top-Left
    canvas.drawLine(Offset(left, top + cornerLen), Offset(left, top), cornerPaint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLen, top), cornerPaint);
    // Top-Right
    canvas.drawLine(Offset(left + width - cornerLen, top), Offset(left + width, top), cornerPaint);
    canvas.drawLine(Offset(left + width, top), Offset(left + width, top + cornerLen), cornerPaint);
    // Bottom-Left
    canvas.drawLine(Offset(left, top + height - cornerLen), Offset(left, top + height), cornerPaint);
    canvas.drawLine(Offset(left, top + height), Offset(left + cornerLen, top + height), cornerPaint);
    // Bottom-Right
    canvas.drawLine(Offset(left + width - cornerLen, top + height), Offset(left + width, top + height), cornerPaint);
    canvas.drawLine(Offset(left + width, top + height), Offset(left + width, top + height - cornerLen), cornerPaint);

    // Garis 5 Fret (Fret 1 hingga Fret 5)
    final fretPaint = Paint()
      ..color = AppColors.fretWire.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 1; i <= 4; i++) {
      final y = top + (height / 5) * i;
      canvas.drawLine(Offset(left + 8, y), Offset(left + width - 8, y), fretPaint);
    }

    // Garis 6 Senar Gitar
    final stringPaint = Paint()
      ..color = AppColors.guitarString.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke;

    for (int s = 0; s < 6; s++) {
      final stringNum = anchor.mirrorStrings ? (s + 1) : (6 - s); // 6=Bass, 1=Treble
      final x = left + 16 + ((width - 32) / 5) * s;
      stringPaint.strokeWidth = 1.0 + (stringNum - 1) * 0.35;
      canvas.drawLine(Offset(x, top + 8), Offset(x, top + height - 8), stringPaint);
    }

    // Label Penunjuk Fret
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int f = 1; f <= 5; f++) {
      final y = top + (height / 5) * (f - 0.5) - 7;
      textPainter.text = TextSpan(
        text: f == 1 ? 'NUT / F1' : 'FRET $f',
        style: TextStyle(
          color: AppColors.primaryLight.withValues(alpha: 0.65),
          fontSize: 9.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.9,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(left + 8, y));
    }

    // Visualisasi Titik Kontak Fretboard Jari yang Terdeteksi (Fretboard Active Touch Points)
    for (final finger in detectedFingertips) {
      if (finger.fret >= 1 && finger.fret <= 5 && finger.string >= 1 && finger.string <= 6) {
        final stringPos = anchor.mirrorStrings
            ? (finger.string - 1)
            : (6 - finger.string);
        final dotX = left + 16 + ((width - 32) / 5) * stringPos;
        final dotY = top + (height / 5) * (finger.fret - 0.5);

        Color fingerColor;
        switch (finger.fingerId) {
          case 8:
            fingerColor = const Color(0xFF00E5FF);
            break;
          case 12:
            fingerColor = AppColors.primary;
            break;
          case 16:
            fingerColor = const Color(0xFFE040FB);
            break;
          case 20:
            fingerColor = const Color(0xFFFF5252);
            break;
          default:
            fingerColor = AppColors.primary;
        }

        final glowPaint = Paint()
          ..color = fingerColor.withValues(alpha: 0.45)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawCircle(Offset(dotX, dotY), 14, glowPaint);

        final dotPaint = Paint()
          ..color = fingerColor
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(dotX, dotY), 9, dotPaint);

        final fNum = finger.fingerId == 8
            ? '1'
            : (finger.fingerId == 12 ? '2' : (finger.fingerId == 16 ? '3' : '4'));
        textPainter.text = TextSpan(
          text: fNum,
          style: const TextStyle(
            color: Color(0xFF101010),
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(dotX - textPainter.width / 2, dotY - textPainter.height / 2),
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _FramingGuidePainter oldDelegate) {
    return oldDelegate.detectedFingertips != detectedFingertips ||
        oldDelegate.anchor != anchor ||
        oldDelegate.isCalibrating != isCalibrating;
  }
}
