import 'dart:collection';

/// Temporal Smoother: Menerapkan sliding window moving average pada probabilitas kelas
/// untuk mencegah flickering/kedipan deteksi antar frame berdekatan.
class TemporalSmoother {
  final int windowSize;
  final Queue<Map<String, double>> _history = Queue();

  TemporalSmoother({this.windowSize = 5});

  /// Menambahkan vektor probabilitas frame baru dan mengembalikan probabilitas tersaring.
  Map<String, double> smoothProbabilities(Map<String, double> currentProbabilities) {
    _history.addLast(Map<String, double>.from(currentProbabilities));
    if (_history.length > windowSize) {
      _history.removeFirst();
    }

    final aggregated = <String, double>{};
    for (final frameProb in _history) {
      frameProb.forEach((chord, prob) {
        aggregated[chord] = (aggregated[chord] ?? 0.0) + prob;
      });
    }

    final count = _history.length;
    final smoothed = <String, double>{};
    aggregated.forEach((chord, sum) {
      smoothed[chord] = sum / count;
    });

    return smoothed;
  }

  /// Mendapatkan chord dengan probabilitas moving average tertinggi beserta confidence-nya.
  MapEntry<String, double>? getTopSmoothedChord(Map<String, double> currentProbabilities) {
    final smoothed = smoothProbabilities(currentProbabilities);
    if (smoothed.isEmpty) return null;

    MapEntry<String, double>? top;
    for (final entry in smoothed.entries) {
      if (top == null || entry.value > top.value) {
        top = entry;
      }
    }
    return top;
  }

  /// Membersihkan riwayat window ketika kamera di-pause atau tangan hilang.
  void clear() {
    _history.clear();
  }
}
