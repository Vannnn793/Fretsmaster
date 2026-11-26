import 'dart:math' as math;
import '../entities/fretboard_context.dart';
import '../entities/hand_joint.dart';

/// FretboardAnalyzer: Menganalisis posisi jari relatif terhadap grid fisik leher gitar (fretboard).
/// Mendukung proyeksi 2D terorientasi (FretboardAnchor: translasi, rotasi, skala, mirror)
/// serta kalibrasi otomatis dari sumbu telapak tangan (auto-track neck).
class FretboardAnalyzer {
  // Batas default kotak panduan Fretboard (untuk kompatibilitas mundur)
  final double guideLeft;
  final double guideTop;
  final double guideWidth;
  final double guideHeight;

  const FretboardAnalyzer({
    this.guideLeft = 0.14,
    this.guideTop = 0.18,
    this.guideWidth = 0.72,
    this.guideHeight = 0.60,
  });

  FretboardAnchor get defaultAnchor => FretboardAnchor(
        centerX: guideLeft + guideWidth / 2.0,
        centerY: guideTop + guideHeight / 2.0,
        width: guideWidth,
        height: guideHeight,
      );

  /// Evaluasi posisi sendi tangan terhadap koordinat fisik fretboard terorientasi
  FretboardDetectionContext analyze(
    List<HandJoint> joints, {
    FretboardAnchor? anchor,
  }) {
    final activeAnchor = anchor ?? defaultAnchor;
    if (joints.length < 21) {
      return FretboardDetectionContext.empty(anchor: activeAnchor);
    }

    // Identifikasi 4 ujung jari penekan senar
    final idxJoint = joints[8];  // Telunjuk
    final midJoint = joints[12]; // Tengah
    final rngJoint = joints[16]; // Manis
    final pnkJoint = joints[20]; // Kelingking

    // 1. Proyeksikan setiap ujung jari ke grid Fret (1–5) dan Senar (1–6)
    final idxFingertip = _mapToFretboard('Telunjuk', 8, idxJoint.x, idxJoint.y, activeAnchor);
    final midFingertip = _mapToFretboard('Tengah', 12, midJoint.x, midJoint.y, activeAnchor);
    final rngFingertip = _mapToFretboard('Manis', 16, rngJoint.x, rngJoint.y, activeAnchor);
    final pnkFingertip = _mapToFretboard('Kelingking', 20, pnkJoint.x, pnkJoint.y, activeAnchor);

    final activeFingers = <FretboardFingertip>[
      idxFingertip,
      midFingertip,
      rngFingertip,
      pnkFingertip,
    ];

    // 2. Evaluasi kesesuaian posisi jari pada fretboard terhadap masing-masing akord target
    final scores = <String, double>{};
    for (final chord in _chordFretboardTemplates.keys) {
      scores[chord] = _computeChordMatchScore(chord, activeFingers);
    }

    // 3. Tentukan akord teratas berdasarkan fretboard
    String topChord = '---';
    double maxScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        topChord = entry.key;
      }
    }

    // 4. Susun ringkasan diagnostik posisi jari di fretboard
    final summary = 'Fretboard: Tlk F${idxFingertip.fret}S${idxFingertip.string} • '
        'Tgh F${midFingertip.fret}S${midFingertip.string} • '
        'Mns F${rngFingertip.fret}S${rngFingertip.string} '
        '(Pola $topChord: ${(maxScore * 100).toInt()}%)';

    return FretboardDetectionContext(
      activeFingers: activeFingers,
      chordScores: scores,
      primaryChord: topChord,
      primaryScore: maxScore,
      fretboardSummary: summary,
      anchor: activeAnchor,
    );
  }

  /// Estimasi jangkar fretboard secara otomatis dari sumbu anatomis telapak tangan.
  /// Vektor Index MCP (5) -> Pinky MCP (17) sejajar dengan arah panjang leher gitar (fret 1 -> 5).
  FretboardAnchor estimateAnchorFromHand(
    List<HandJoint> joints, {
    FretboardAnchor? currentAnchor,
    double smoothingAlpha = 0.14,
  }) {
    final base = currentAnchor ?? defaultAnchor;
    if (joints.length < 21) return base;

    final idxMcp = joints[5];
    final pnkMcp = joints[17];
    final idxTip = joints[8];
    final midTip = joints[12];
    final rngTip = joints[16];

    final nx = pnkMcp.x - idxMcp.x;
    final ny = pnkMcp.y - idxMcp.y;
    final neckSpan = math.sqrt(nx * nx + ny * ny);
    if (neckSpan < 0.03) return base;

    // Pada mode vertikal (angle=0), arah Fret 1 -> Fret 5 mengarah ke +Y (sudut +pi/2)
    final targetAngle = math.atan2(ny, nx) - (math.pi / 2.0);
    final angleDiff = _normalizeAngle(targetAngle - base.angleRad);
    final smoothedAngle = _normalizeAngle(base.angleRad + smoothingAlpha * angleDiff);

    // Estimasi pusat fretboard dari rata-rata ujung jari penekan senar
    final tipCenterX = (idxTip.x + midTip.x + rngTip.x) / 3.0;
    final tipCenterY = (idxTip.y + midTip.y + rngTip.y) / 3.0;

    // Ujung jari rata-rata berada di sekitar Fret 2 (sedikit di atas pusat Fret 3),
    // sehingga kita geser pusat kotak +0.10 * height sepanjang sumbu leher.
    final axisX = math.cos(smoothedAngle + math.pi / 2.0);
    final axisY = math.sin(smoothedAngle + math.pi / 2.0);
    final targetCenterX = (tipCenterX + axisX * base.height * 0.10).clamp(0.18, 0.82);
    final targetCenterY = (tipCenterY + axisY * base.height * 0.10).clamp(0.18, 0.82);

    final smoothedCenterX = base.centerX + smoothingAlpha * (targetCenterX - base.centerX);
    final smoothedCenterY = base.centerY + smoothingAlpha * (targetCenterY - base.centerY);

    return base.copyWith(
      centerX: smoothedCenterX,
      centerY: smoothedCenterY,
      angleRad: smoothedAngle,
    );
  }

  double _normalizeAngle(double rad) {
    var a = rad;
    while (a > math.pi) {
      a -= 2.0 * math.pi;
    }
    while (a < -math.pi) {
      a += 2.0 * math.pi;
    }
    return a;
  }

  /// Memetakan koordinat layar (0.0..1.0) ke koordinat lokal FretboardAnchor
  /// lalu mengonversinya menjadi Fret (1..5) dan Senar (1..6) kontinu & diskret.
  FretboardFingertip _mapToFretboard(
    String name,
    int id,
    double x,
    double y,
    FretboardAnchor anchor,
  ) {
    final dx = x - anchor.centerX;
    final dy = y - anchor.centerY;

    // Rotasi balik (-angleRad) dari koordinat layar ke ruang lokal fretboard
    final cosA = math.cos(-anchor.angleRad);
    final sinA = math.sin(-anchor.angleRad);
    final localX = dx * cosA - dy * sinA;
    final localY = dx * sinA + dy * cosA;

    final safeWidth = math.max(0.05, anchor.width);
    final safeHeight = math.max(0.05, anchor.height);

    var relX = (localX / safeWidth) + 0.5;
    final relY = (localY / safeHeight) + 0.5;

    if (anchor.mirrorStrings) {
      relX = 1.0 - relX;
    }

    // Estimasi Fret kontinu (0.5 .. 5.5) dan diskret (1 .. 5)
    final fretFloat = (relY.clamp(0.0, 1.0) * 5.0 + 0.5).clamp(0.5, 5.5);
    final fret = fretFloat.clamp(1.0, 5.0).round();

    // Estimasi Senar kontinu (1.0 .. 6.0) dan diskret (1 .. 6)
    final stringFloat = ((1.0 - relX.clamp(0.0, 1.0)) * 5.0 + 1.0).clamp(1.0, 6.0);
    final string = stringFloat.clamp(1.0, 6.0).round();

    final inBounds = (relX >= -0.05 && relX <= 1.05 && relY >= -0.05 && relY <= 1.05);
    final conf = inBounds ? 0.95 : 0.40;

    return FretboardFingertip(
      fingerName: name,
      fingerId: id,
      fret: fret,
      string: string,
      fretFloat: fretFloat,
      stringFloat: stringFloat,
      x: x,
      y: y,
      confidence: conf,
    );
  }

  /// Menghitung skor kecocokan fretboard untuk akord tertentu:
  /// Kombinasi posisi absolut pada anchor (65%) + geometri relatif antar jari (35%).
  double _computeChordMatchScore(String chord, List<FretboardFingertip> fingers) {
    final template = _chordFretboardTemplates[chord];
    if (template == null) return 0.10;

    final idx = fingers.firstWhere((f) => f.fingerId == 8);
    final mid = fingers.firstWhere((f) => f.fingerId == 12);
    final rng = fingers.firstWhere((f) => f.fingerId == 16);
    final pnk = fingers.firstWhere((f) => f.fingerId == 20);

    final pairs = <(FretboardFingertip, _FretStringTarget)>[];
    if (template.indexTarget != null) pairs.add((idx, template.indexTarget!));
    if (template.middleTarget != null) pairs.add((mid, template.middleTarget!));
    if (template.ringTarget != null) pairs.add((rng, template.ringTarget!));
    if (template.pinkyTarget != null) pairs.add((pnk, template.pinkyTarget!));

    if (pairs.isEmpty) return 0.10;

    double absTotal = 0.0;
    for (final (finger, target) in pairs) {
      absTotal += _targetSimilarity(finger, target);
    }
    final absScore = absTotal / pairs.length;

    if (pairs.length < 2) {
      return absScore.clamp(0.0, 1.0);
    }

    // Evaluasi jarak relatif antar pasangan jari (tahan terhadap pergeseran ringan anchor)
    double relTotal = 0.0;
    int relCount = 0;
    for (int i = 0; i < pairs.length; i++) {
      for (int j = i + 1; j < pairs.length; j++) {
        final (fA, tA) = pairs[i];
        final (fB, tB) = pairs[j];

        final actualDFret = fB.fretFloat - fA.fretFloat;
        final targetDFret = (tB.fret - tA.fret).toDouble();
        final actualDString = fB.stringFloat - fA.stringFloat;
        final targetDString = (tB.string - tA.string).toDouble();

        final errFret = actualDFret - targetDFret;
        final errString = actualDString - targetDString;
        final pairSim = math.exp(-(errFret * errFret / 0.55 + errString * errString / 0.85));

        relTotal += pairSim;
        relCount++;
      }
    }

    final relScore = relCount > 0 ? (relTotal / relCount) : absScore;
    return (0.65 * absScore + 0.35 * relScore).clamp(0.0, 1.0);
  }

  /// Kemiripan posisi kontinu jari terhadap target fisik fret & senar (Gaussian decay presisi)
  double _targetSimilarity(FretboardFingertip finger, _FretStringTarget target) {
    final dFret = (finger.fretFloat - target.fret).abs();
    final dString = (finger.stringFloat - target.string).abs();

    // Pembagi ketat (0.60 untuk fret, 0.90 untuk senar) agar chord berdekatan (C vs Am, D vs C) terpisah tajam
    final score = math.exp(-(dFret * dFret / 0.60 + dString * dString / 0.90));
    return score.clamp(0.0, 1.0);
  }

  /// Definisi template fisik posisi fret dan senar untuk 10 open & essential chords
  static final Map<String, _ChordTemplate> _chordFretboardTemplates = {
    // C Mayor: Telunjuk F1 S2, Tengah F2 S4, Manis F3 S5
    'C': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 1, string: 2),
      middleTarget: _FretStringTarget(fret: 2, string: 4),
      ringTarget: _FretStringTarget(fret: 3, string: 5),
    ),

    // A Minor: Telunjuk F1 S2, Tengah F2 S4, Manis F2 S3
    'Am': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 1, string: 2),
      middleTarget: _FretStringTarget(fret: 2, string: 4),
      ringTarget: _FretStringTarget(fret: 2, string: 3),
    ),

    // E Mayor: Telunjuk F1 S3, Tengah F2 S5, Manis F2 S4
    'E': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 1, string: 3),
      middleTarget: _FretStringTarget(fret: 2, string: 5),
      ringTarget: _FretStringTarget(fret: 2, string: 4),
    ),

    // E Minor: Tengah F2 S5, Manis F2 S4
    'Em': const _ChordTemplate(
      middleTarget: _FretStringTarget(fret: 2, string: 5),
      ringTarget: _FretStringTarget(fret: 2, string: 4),
    ),

    // A Mayor: Telunjuk F2 S4, Tengah F2 S3, Manis F2 S2
    'A': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 2, string: 4),
      middleTarget: _FretStringTarget(fret: 2, string: 3),
      ringTarget: _FretStringTarget(fret: 2, string: 2),
    ),

    // G Mayor: Telunjuk F2 S5, Tengah F3 S6, Manis F3 S1
    'G': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 2, string: 5),
      middleTarget: _FretStringTarget(fret: 3, string: 6),
      ringTarget: _FretStringTarget(fret: 3, string: 1),
    ),

    // D Mayor: Telunjuk F2 S3, Tengah F2 S1, Manis F3 S2
    'D': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 2, string: 3),
      middleTarget: _FretStringTarget(fret: 2, string: 1),
      ringTarget: _FretStringTarget(fret: 3, string: 2),
    ),

    // D Minor: Telunjuk F1 S1, Tengah F2 S3, Manis F3 S2
    'Dm': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 1, string: 1),
      middleTarget: _FretStringTarget(fret: 2, string: 3),
      ringTarget: _FretStringTarget(fret: 3, string: 2),
    ),

    // F Mayor: Telunjuk Barre F1, Tengah F2 S3, Manis F3 S5, Kelingking F3 S4
    'F': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 1, string: 2),
      middleTarget: _FretStringTarget(fret: 2, string: 3),
      ringTarget: _FretStringTarget(fret: 3, string: 5),
      pinkyTarget: _FretStringTarget(fret: 3, string: 4),
    ),

    // B Mayor: Telunjuk Barre F2, Tengah F4 S4, Manis F4 S3, Kelingking F4 S2
    'B': const _ChordTemplate(
      indexTarget: _FretStringTarget(fret: 2, string: 5),
      middleTarget: _FretStringTarget(fret: 4, string: 4),
      ringTarget: _FretStringTarget(fret: 4, string: 3),
      pinkyTarget: _FretStringTarget(fret: 4, string: 2),
    ),
  };
}

class _FretStringTarget {
  final int fret;   // 1..5
  final int string; // 1..6

  const _FretStringTarget({required this.fret, required this.string});
}

class _ChordTemplate {
  final _FretStringTarget? indexTarget;
  final _FretStringTarget? middleTarget;
  final _FretStringTarget? ringTarget;
  final _FretStringTarget? pinkyTarget;

  const _ChordTemplate({
    this.indexTarget,
    this.middleTarget,
    this.ringTarget,
    this.pinkyTarget,
  });
}
