import 'dart:math' as math;
import '../entities/hand_joint.dart';

/// Hasil evaluasi aturan geometris penjarian gitar
class ChordGeometricEvaluation {
  final Map<String, double> ruleScores;
  final String primaryChord;
  final double primaryScore;
  final String diagnosticHint;

  const ChordGeometricEvaluation({
    required this.ruleScores,
    required this.primaryChord,
    required this.primaryScore,
    required this.diagnosticHint,
  });
}

/// Mesin Aturan Geometris Penjarian Gitar (Hybrid AI + Geometric Safety Guard)
///
/// Modul ini menganalisis relasi spasial 21 titik sendi MediaPipe Hands
/// berdasarkan biomekanika anatomis penjarian 9 chord gitar standar:
/// A, Am, B, C, D, E, Em, F, G.
class ChordGeometricRuleEngine {
  const ChordGeometricRuleEngine();

  /// Evaluasi geometri 21 sendi tangan dan menghasilkan skor kecocokan [0.0 - 1.0] untuk tiap chord
  ChordGeometricEvaluation evaluate(List<HandJoint> landmarks) {
    if (landmarks.length < 21) {
      return const ChordGeometricEvaluation(
        ruleScores: {},
        primaryChord: '---',
        primaryScore: 0.0,
        diagnosticHint: 'Titik sendi tangan tidak lengkap.',
      );
    }

    // 1. Normalisasi Koordinat terhadap Pergelangan Tangan (Wrist / index 0)
    final wrist = landmarks[0];
    final normPoints = <List<double>>[];
    for (final j in landmarks) {
      normPoints.add([j.x - wrist.x, j.y - wrist.y, j.z - wrist.z]);
    }

    // 2. Skala referensi telapak tangan: Wrist (0) ke Middle MCP (9)
    final mcp9 = normPoints[9];
    double scale = math.sqrt(mcp9[0] * mcp9[0] + mcp9[1] * mcp9[1] + mcp9[2] * mcp9[2]);
    if (scale < 1e-4) {
      double maxDist = 0.0;
      for (final p in normPoints) {
        final d = math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
        if (d > maxDist) maxDist = d;
      }
      scale = maxDist;
    }
    if (scale < 1e-4) scale = 1.0;

    // Koordinat ternormalisasi per titik
    List<double> pt(int idx) {
      final p = normPoints[idx];
      return [p[0] / scale, p[1] / scale, p[2] / scale];
    }

    // Titik Ujung Jari (Tips)
    final idxTip = pt(8);   // Telunjuk
    final midTip = pt(12);  // Tengah
    final rngTip = pt(16);  // Manis
    final pnkTip = pt(20);  // Kelingking

    // Jarak Euclidean antar titik
    double dist(List<double> a, List<double> b) {
      final dx = a[0] - b[0];
      final dy = a[1] - b[1];
      final dz = a[2] - b[2];
      return math.sqrt(dx * dx + dy * dy + dz * dz);
    }

    // Metrik Jarak Antar Ujung Jari
    final dIdxMid = dist(idxTip, midTip);
    final dMidRng = dist(midTip, rngTip);
    final dIdxRng = dist(idxTip, rngTip);
    final dRngPnk = dist(rngTip, pnkTip);
    final dMidPnk = dist(midTip, pnkTip);

    // Rasio Ekstensi Jari (MCP ke TIP dibanding panjang kelengkungan jari)
    double extensionRatio(int mcpIdx, int pipIdx, int dipIdx, int tipIdx) {
      final mcp = pt(mcpIdx);
      final pip = pt(pipIdx);
      final dip = pt(dipIdx);
      final tip = pt(tipIdx);
      final direct = dist(mcp, tip);
      final total = dist(mcp, pip) + dist(pip, dip) + dist(dip, tip);
      if (total < 1e-4) return 1.0;
      return direct / total;
    }

    final extIdx = extensionRatio(5, 6, 7, 8);

    final scores = <String, double>{};
    final hints = <String, String>{};

    // Inisialisasi skor default
    for (final c in ['A', 'Am', 'B', 'C', 'D', 'Dm', 'E', 'Em', 'F', 'G']) {
      scores[c] = 0.08;
    }

    // -------------------------------------------------------------
    // ATURAN 1: CHORD G (Bentangan Lebar: Jari Tengah vs Manis/Kelingking)
    // -------------------------------------------------------------
    final spanG = math.max(dMidPnk, dMidRng);
    if (spanG > 0.46) {
      final scoreG = ((spanG - 0.44) / 0.40).clamp(0.0, 1.0);
      scores['G'] = scoreG;
      hints['G'] = 'Bentangan jari senar 6 dan senar 1 cocok dengan akord G.';
    } else {
      scores['G'] = (spanG / 0.60).clamp(0.0, 0.40);
    }

    // -------------------------------------------------------------
    // ATURAN 2: CHORD C (Formasi Tangga Diagonal Fret 1-2-3: S2-S4-S5)
    // -------------------------------------------------------------
    // Ciri khas biomekanika C Mayor:
    // - Telunjuk di Fret 1 Senar 2, Tengah di Fret 2 Senar 4, Manis di Fret 3 Senar 5.
    // - Bentangan jari manis ke telunjuk lebar diagonal (dIdxRng > 0.35)
    // - Jari manis melangkah jauh ke senar 5 (senar atas/bass):
    //   posisi horizontal x jari manis bergerak ke kiri (arah senar 5 & 6),
    //   bukan berada di senar treble 1 & 2 seperti pada akord D!
    final isLadderDiagonal = dIdxTipIsFret1(idxTip, midTip, rngTip);
    // Bedakan tegas dari D: pada D, formasi membentuk segitiga rapat di senar 1, 2, 3
    final isDFormTriangle = (dIdxMid < 0.38 && dMidRng < 0.34 && rngTip[1] > midTip[1] && idxTip[0] > rngTip[0]);

    if (dMidRng > 0.22 && dIdxRng > 0.32 && !isDFormTriangle) {
      double scoreC = ((dMidRng - 0.18) / 0.26).clamp(0.0, 1.0);
      if (isLadderDiagonal) scoreC = math.min(1.0, scoreC + 0.20);
      // Pembeda mutlak dari Am:
      // Pada Am, jari manis berada di fret 2 senar 3 (dekat jari tengah).
      // Pada C, jari manis berada di fret 3 senar 5 (jarak Euclidean ke tengah lebih besar dan menjangkau senar atas).
      if (dMidRng > 0.28 && dIdxRng > 0.40) {
        scoreC = math.min(1.0, scoreC + 0.15);
      }
      scores['C'] = scoreC;
      hints['C'] = 'Formasi diagonal tangga (fret 1-2-3) mengonfirmasi akord C.';
    } else {
      scores['C'] = (dMidRng / 0.45).clamp(0.0, 0.25);
    }

    // -------------------------------------------------------------
    // ATURAN 3: CHORD A (Klaster 3 Jari Rapat di Fret 2)
    // -------------------------------------------------------------
    final maxClusterDist = math.max(dIdxMid, math.max(dMidRng, dIdxRng));
    if (maxClusterDist < 0.38) {
      final scoreA = ((0.42 - maxClusterDist) / 0.22).clamp(0.0, 1.0);
      scores['A'] = scoreA;
      hints['A'] = 'Tiga jari berjejer rapat di fret 2 mengonfirmasi akord A.';
    } else {
      scores['A'] = ((0.48 - maxClusterDist) / 0.48).clamp(0.0, 0.25);
    }

    // -------------------------------------------------------------
    // ATURAN 4: CHORD E vs AM vs EM (Penyelesaian Ambiguitas Akurat)
    // -------------------------------------------------------------
    // Keduanya (E dan Am) memiliki:
    // - Jari Tengah & Manis bersanding di Fret 2 (dMidRng < 0.28)
    // - Jari Telunjuk di Fret 1 (dIdxMid sekitar 0.20 - 0.40)
    // - Jari Manis di fret yang sama dengan Jari Tengah (bukan melangkah ke Fret 3 seperti C)
    //
    // PEMBEDA UTAMA (Tinggi Senar / Posisi Vertikal Relatif):
    // - Pada E Mayor: Jari Tengah menekan senar 5 (atas), Ring senar 4.
    // - Pada Am: Seluruh blok digeser turun ke senar 4, 3, dan Telunjuk di senar 2 (bawah).
    //   Pembeda dari C: Pada Am, jari manis dan jari tengah sama-sama di Fret 2 (dMidRng rapat < 0.28, dIdxRng < 0.32).
    //   Jika dIdxRng besar (> 0.38) atau dMidRng melebar (> 0.28), itu adalah Chord C!
    final isMidRngFret2Pair = dMidRng < 0.28 && (rngTip[1] - midTip[1]).abs() < 0.14 && dIdxRng < 0.34;

    if (isMidRngFret2Pair) {
      final hasFret1Index = dIdxMid > 0.16 && dIdxMid < 0.48;

      if (!hasFret1Index || extIdx > 0.78) {
        // Telunjuk terbuka/tidak menekan -> E Minor (Em)
        scores['Em'] = 0.90;
        scores['E'] = 0.25;
        scores['Am'] = 0.20;
        hints['Em'] = 'Hanya jari tengah dan manis di fret 2 (akord Em).';
      } else {
        // Telunjuk aktif di Fret 1: Bedakan E Mayor vs A Minor
        // Bandingkan tinggi jari telunjuk dan tengah terhadap sumbu vertikal
        // Pada E, middle finger berada tinggi di senar 5 (jarak vertikal ke telunjuk lebih besar)
        final verticalOffset = (idxTip[1] - midTip[1]).abs();

        if (verticalOffset < 0.08 || idxTip[0] > midTip[0]) {
          // Telunjuk berada di senar 3 dekat tengah (E Mayor)
          scores['E'] = 0.88;
          scores['Am'] = 0.45;
          hints['E'] = 'Formasi senar 3, 4, 5 mengonfirmasi akord E mayor.';
        } else {
          // Telunjuk berada di senar 2 bawah (A Minor)
          scores['Am'] = 0.88;
          scores['E'] = 0.45;
          hints['Am'] = 'Formasi senar 2, 3, 4 mengonfirmasi akord Am.';
        }
      }
    }

    // -------------------------------------------------------------
    // ATURAN 5: CHORD D & DM (Segitiga di Senar Bawah: Senar 1, 2, 3)
    // -------------------------------------------------------------
    // Pada D Mayor: Telunjuk dan Tengah keduanya berada di Fret 2 (senar 3 dan 1),
    //               ketinggian vertikal telunjuk dan tengah hampir sejajar (diff < 0.12).
    // Pada D Minor: Telunjuk berada di Fret 1 senar 1 (jauh lebih maju ke Fret 1,
    //               sehingga ketinggian vertikal telunjuk terhadap jari tengah > 0.20).
    final dTriangleMax = math.max(dIdxMid, math.max(dMidRng, dIdxRng));
    if (dTriangleMax < 0.52 && dMidRng < 0.38) {
      final isIndexFret1 = (idxTip[1] - midTip[1]) > 0.15 || dIdxRng > 0.28;
      if (isIndexFret1) {
        final scoreDm = ((0.56 - dTriangleMax) / 0.20).clamp(0.0, 0.95);
        scores['Dm'] = scoreDm;
        hints['Dm'] = 'Telunjuk di fret 1 senar 1 mengonfirmasi akord Dm.';
      } else {
        final scoreD = ((0.52 - dTriangleMax) / 0.20).clamp(0.0, 0.95);
        scores['D'] = scoreD;
        hints['D'] = 'Formasi segitiga di senar bawah mengonfirmasi akord D.';
      }
    }

    // -------------------------------------------------------------
    // ATURAN 6: CHORD F (Barre Chord Fret 1 + Jari Manis & Kelingking Fret 3)
    // -------------------------------------------------------------
    // Ciri khas F:
    // - Telunjuk membentang lurus sebagai barre di Fret 1
    // - Jari Manis (16) dan Kelingking (20) berdampingan di Fret 3 (dRngPnk rapat < 0.30)
    // - Jari Telunjuk ke Jari Manis terpisah 2 fret (dIdxRng > 0.35)
    // - Jari Tengah di Fret 2 berjarak wajar ke Jari Manis Fret 3 (dMidRng < 0.50)
    if (dRngPnk < 0.30 && dIdxRng > 0.35 && dMidRng < 0.50) {
      final scoreF = ((0.32 - dRngPnk) / 0.20 + (dIdxRng - 0.30) / 0.50).clamp(0.0, 1.0);
      scores['F'] = scoreF;
      hints['F'] = 'Barre fret 1 dan jari manis-kelingking di fret 3 mengonfirmasi akord F.';
    }

    // -------------------------------------------------------------
    // ATURAN 7: CHORD B (Barre Fret 2 + Klaster 3 Jari di Fret 4)
    // -------------------------------------------------------------
    // Ciri khas B:
    // - Telunjuk di Fret 2, trio (Tengah 12, Manis 16, Kelingking 20) di Fret 4
    // - Jarak telunjuk ke trio besar (2 fret: dIdxMid > 0.26)
    // - Trio jari (Tengah, Manis, Kelingking) berjarak rapat (dRngPnk < 0.24, dMidRng < 0.26)
    if (dIdxMid > 0.26 && dRngPnk < 0.26 && dMidRng < 0.26) {
      final trioCloseness = math.max(dRngPnk, dMidRng);
      final scoreB = ((0.32 - trioCloseness) / 0.20).clamp(0.0, 1.0);
      scores['B'] = scoreB;
      hints['B'] = 'Telunjuk di fret 2 dan klaster jari di fret 4 mengonfirmasi akord B.';
    }

    // Cari skor geometris tertinggi
    String topChord = '---';
    double maxScore = 0.0;
    for (final entry in scores.entries) {
      if (entry.value > maxScore) {
        maxScore = entry.value;
        topChord = entry.key;
      }
    }

    return ChordGeometricEvaluation(
      ruleScores: scores,
      primaryChord: topChord,
      primaryScore: maxScore,
      diagnosticHint: hints[topChord] ?? 'Posisikan jari sesuai bentuk akord.',
    );
  }

  /// Memeriksa apakah formasi jari telunjuk, tengah, dan manis membentuk formasi tangga diagonal
  bool dIdxTipIsFret1(List<double> idx, List<double> mid, List<double> rng) {
    final dIdxWrist = math.sqrt(idx[0] * idx[0] + idx[1] * idx[1]);
    final dMidWrist = math.sqrt(mid[0] * mid[0] + mid[1] * mid[1]);
    final dRngWrist = math.sqrt(rng[0] * rng[0] + rng[1] * rng[1]);

    return (dRngWrist > dMidWrist && dMidWrist > dIdxWrist * 0.9);
  }

  /// Menggabungkan probabilitas model AI (MLP) dengan skor aturan geometri (Ensemble Bayesian Fusion)
  /// Menggabungkan probabilitas model AI (MLP), aturan geometri biomekanika, dan verifikasi fisik fretboard (Tri-Modal Fusion)
  Map<String, double> fuseWithMlProbabilities(
    Map<String, double> mlProbabilities,
    Map<String, double> ruleScores, {
    Map<String, double>? fretboardScores,
    double mlWeight = 0.45,
    double ruleWeight = 0.25,
    double fretboardWeight = 0.30,
  }) {
    final fused = <String, double>{};
    double sum = 0.0;

    for (final chord in mlProbabilities.keys) {
      final pMl = mlProbabilities[chord] ?? 0.0;
      final pRule = ruleScores[chord] ?? 0.08;
      final pFret = fretboardScores != null ? (fretboardScores[chord] ?? 0.10) : 0.0;

      final penalty = (pRule < 0.08) ? 0.40 : 1.0;

      double val;
      if (fretboardScores != null && fretboardScores.isNotEmpty) {
        val = (mlWeight * pMl + ruleWeight * pRule + fretboardWeight * pFret) * penalty;
      } else {
        // Fallback backward-compatible jika fretboardScores belum disediakan
        val = (0.60 * pMl + 0.40 * pRule) * penalty;
      }

      fused[chord] = val;
      sum += val;
    }

    // Normalisasi probabilitas agar total = 1.0
    if (sum > 1e-6) {
      for (final key in fused.keys) {
        fused[key] = fused[key]! / sum;
      }
    }

    return fused;
  }
}
