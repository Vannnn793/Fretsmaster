import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:fretmaster/features/chord_detection/domain/entities/fretboard_context.dart';
import 'package:fretmaster/features/chord_detection/domain/entities/hand_joint.dart';
import 'package:fretmaster/features/chord_detection/domain/services/fretboard_analyzer.dart';

void main() {
  late FretboardAnalyzer analyzer;

  setUp(() {
    analyzer = const FretboardAnalyzer();
  });

  // Helper untuk membuat 21 dummy joints dengan koordinat kustom untuk ujung jari
  List<HandJoint> createLandmarksWithTips({
    required double idxX, required double idxY,
    required double midX, required double midY,
    required double rngX, required double rngY,
    required double pnkX, required double pnkY,
  }) {
    final joints = List.generate(21, (i) => HandJoint(id: i, x: 0.5, y: 0.5, z: 0.0));
    joints[8] = HandJoint(id: 8, x: idxX, y: idxY, z: 0.0);   // Telunjuk
    joints[12] = HandJoint(id: 12, x: midX, y: midY, z: 0.0); // Tengah
    joints[16] = HandJoint(id: 16, x: rngX, y: rngY, z: 0.0); // Manis
    joints[20] = HandJoint(id: 20, x: pnkX, y: pnkY, z: 0.0); // Kelingking
    return joints;
  }

  group('FretboardAnalyzer Tests', () {
    test('Mengembalikan konteks kosong jika landmarks kurang dari 21', () {
      final ctx = analyzer.analyze(const []);
      expect(ctx.activeFingers.isEmpty, true);
      expect(ctx.primaryChord, '---');
      expect(ctx.primaryScore, 0.0);
    });

    test('Mendeteksi Fretboard Context untuk Chord C (Tlk F1 S2, Tgh F2 S4, Mns F3 S5)', () {
      // Guide: Left=0.14, Width=0.72. Top=0.18, Height=0.60
      // Fret 1 center: y = 0.18 + 0.60 * 0.10 = 0.24
      // Fret 2 center: y = 0.18 + 0.60 * 0.30 = 0.36
      // Fret 3 center: y = 0.18 + 0.60 * 0.50 = 0.48
      // Senar 2 center (kanan): relX = 1 - (2 - 1)/5 = 0.80 -> x = 0.14 + 0.72 * 0.80 = 0.716
      // Senar 4 center: relX = 1 - (4 - 1)/5 = 0.40 -> x = 0.14 + 0.72 * 0.40 = 0.428
      // Senar 5 center: relX = 1 - (5 - 1)/5 = 0.20 -> x = 0.14 + 0.72 * 0.20 = 0.284

      final landmarks = createLandmarksWithTips(
        idxX: 0.71, idxY: 0.24, // Fret 1, Senar 2
        midX: 0.43, midY: 0.36, // Fret 2, Senar 4
        rngX: 0.28, rngY: 0.48, // Fret 3, Senar 5
        pnkX: 0.80, pnkY: 0.60, // Kelingking relaks
      );

      final ctx = analyzer.analyze(landmarks);

      expect(ctx.activeFingers.length, 4);
      expect(ctx.chordScores.containsKey('C'), true);
      expect(ctx.chordScores['C']!, greaterThan(0.70));
      // Pastikan skor C jauh lebih tinggi daripada Am karena jari manis di Fret 3
      expect(ctx.chordScores['C']!, greaterThan(ctx.chordScores['Am']!));
      expect(ctx.primaryChord, 'C');
    });

    test('Mendeteksi Fretboard Context untuk Chord Am (Tlk F1 S2, Tgh F2 S4, Mns F2 S3)', () {
      // Fret 1: y = 0.24
      // Fret 2: y = 0.36
      // Senar 2: x = 0.716
      // Senar 4: x = 0.428
      // Senar 3: relX = 1 - (3 - 1)/5 = 0.60 -> x = 0.14 + 0.72 * 0.60 = 0.572

      final landmarks = createLandmarksWithTips(
        idxX: 0.71, idxY: 0.24, // Fret 1, Senar 2
        midX: 0.43, midY: 0.36, // Fret 2, Senar 4
        rngX: 0.57, rngY: 0.36, // Fret 2, Senar 3
        pnkX: 0.80, pnkY: 0.60,
      );

      final ctx = analyzer.analyze(landmarks);

      expect(ctx.chordScores['Am']!, greaterThan(0.70));
      expect(ctx.chordScores['Am']!, greaterThan(ctx.chordScores['C']!));
      expect(ctx.primaryChord, 'Am');
    });

    test('Mendeteksi Fretboard Context untuk Chord E (Tlk F1 S3, Tgh F2 S5, Mns F2 S4)', () {
      // Fret 1: y = 0.24
      // Fret 2: y = 0.36
      // Senar 3: x = 0.572
      // Senar 5: x = 0.284
      // Senar 4: x = 0.428

      final landmarks = createLandmarksWithTips(
        idxX: 0.57, idxY: 0.24, // Fret 1, Senar 3
        midX: 0.28, midY: 0.36, // Fret 2, Senar 5
        rngX: 0.43, rngY: 0.36, // Fret 2, Senar 4
        pnkX: 0.80, pnkY: 0.60,
      );

      final ctx = analyzer.analyze(landmarks);

      expect(ctx.chordScores['E']!, greaterThan(0.70));
      // Memastikan E tidak tertukar dengan Am
      expect(ctx.chordScores['E']!, greaterThan(ctx.chordScores['Am']!));
      expect(ctx.primaryChord, 'E');
    });

    test('Mendeteksi Fretboard Context untuk Chord Dm (Tlk F1 S1, Tgh F2 S3, Mns F3 S2)', () {
      // Guide: Senar 1: relX = 1 - 0 = 1.0 -> x = 0.14 + 0.72 * 1.0 = 0.86
      // Senar 3: x = 0.572
      // Senar 2: x = 0.716
      // Fret 1: y = 0.24
      // Fret 2: y = 0.36
      // Fret 3: y = 0.48
      final landmarks = createLandmarksWithTips(
        idxX: 0.85, idxY: 0.24, // Fret 1, Senar 1
        midX: 0.57, midY: 0.36, // Fret 2, Senar 3
        rngX: 0.71, rngY: 0.48, // Fret 3, Senar 2
        pnkX: 0.40, pnkY: 0.60,
      );

      final ctx = analyzer.analyze(landmarks);

      expect(ctx.chordScores['Dm']!, greaterThan(0.60));
      expect(ctx.primaryChord, 'Dm');
    });

    test('Memastikan ringkasan diagnostik fretboard memuat info fret dan senar', () {
      final landmarks = createLandmarksWithTips(
        idxX: 0.71, idxY: 0.24,
        midX: 0.43, midY: 0.36,
        rngX: 0.28, rngY: 0.48,
        pnkX: 0.80, pnkY: 0.60,
      );

      final ctx = analyzer.analyze(landmarks);
      expect(ctx.fretboardSummary.contains('Fretboard:'), true);
      expect(ctx.fretboardSummary.contains('Tlk F'), true);
    });

    test('Mendukung FretboardAnchor horizontal (-90 derajat) untuk deteksi Chord C', () {
      final horizontalAnchor = FretboardAnchor.horizontal();
      // Helper proyeksi titik lokal (fret, string) ke koordinat layar untuk verifikasi rotasi -90 deg
      (double, double) screenPointFor(int fret, int string) {
        final relY = (fret - 0.5) / 5.0; // 0..1 sepanjang fret
        final relX = 1.0 - (string - 1) / 5.0; // 0..1 sepanjang senar 6..1
        final localX = (relX - 0.5) * horizontalAnchor.width;
        final localY = (relY - 0.5) * horizontalAnchor.height;
        final cosA = math.cos(horizontalAnchor.angleRad);
        final sinA = math.sin(horizontalAnchor.angleRad);
        return (
          horizontalAnchor.centerX + (localX * cosA - localY * sinA),
          horizontalAnchor.centerY + (localX * sinA + localY * cosA),
        );
      }

      final (ix, iy) = screenPointFor(1, 2); // Telunjuk F1 S2
      final (mx, my) = screenPointFor(2, 4); // Tengah F2 S4
      final (rx, ry) = screenPointFor(3, 5); // Manis F3 S5
      final (px, py) = screenPointFor(4, 1); // Kelingking relaks

      final landmarks = createLandmarksWithTips(
        idxX: ix, idxY: iy,
        midX: mx, midY: my,
        rngX: rx, rngY: ry,
        pnkX: px, pnkY: py,
      );

      final ctx = analyzer.analyze(landmarks, anchor: horizontalAnchor);
      expect(ctx.primaryChord, 'C');
      expect(ctx.chordScores['C']!, greaterThan(0.75));
      expect(ctx.chordScores['C']!, greaterThan(ctx.chordScores['Am']!));
    });

    test('Mendukung mirrorStrings untuk kamera depan (selfie)', () {
      final mirrorAnchor = FretboardAnchor.vertical(mirrorStrings: true);
      // Pada mode mirror, Senar 2 berada di sisi kiri (relX = 0.20 -> x = 0.14 + 0.72 * 0.20 = 0.284)
      // Senar 4 di relX = 0.60 -> x = 0.572, Senar 5 di relX = 0.80 -> x = 0.716
      final landmarks = createLandmarksWithTips(
        idxX: 0.284, idxY: 0.24, // F1, S2 mirrored
        midX: 0.572, midY: 0.36, // F2, S4 mirrored
        rngX: 0.716, rngY: 0.48, // F3, S5 mirrored
        pnkX: 0.200, pnkY: 0.60,
      );

      final ctx = analyzer.analyze(landmarks, anchor: mirrorAnchor);
      expect(ctx.primaryChord, 'C');
      expect(ctx.chordScores['C']!, greaterThan(0.75));
    });

    test('estimateAnchorFromHand menyesuaikan sudut anchor mengikuti sumbu MCP tangan', () {
      final joints = List.generate(21, (i) => HandJoint(id: i, x: 0.5, y: 0.5, z: 0.0));
      // Sumbu MCP 5 -> 17 horizontal ke kanan (mengindikasikan leher gitar datar -90 deg)
      joints[5] = const HandJoint(id: 5, x: 0.35, y: 0.50, z: 0.0);
      joints[17] = const HandJoint(id: 17, x: 0.55, y: 0.50, z: 0.0);
      joints[8] = const HandJoint(id: 8, x: 0.36, y: 0.44, z: 0.0);
      joints[12] = const HandJoint(id: 12, x: 0.44, y: 0.48, z: 0.0);
      joints[16] = const HandJoint(id: 16, x: 0.52, y: 0.52, z: 0.0);

      final updated = analyzer.estimateAnchorFromHand(
        joints,
        currentAnchor: const FretboardAnchor(angleRad: 0.0),
        smoothingAlpha: 1.0,
      );

      expect(updated.angleRad, closeTo(-math.pi / 2, 0.05));
    });
  });
}
