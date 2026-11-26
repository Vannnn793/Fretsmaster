/// Frame Throttler: Membatasi laju inferensi kamera ke frame rate terkontrol
/// (misal ~15 FPS) sehingga CPU/GPU mobile tidak jenuh dan rendering kamera UI tetap 60 FPS.
class FrameThrottler {
  final int throttleIntervalMs;
  DateTime _lastExecutionTime = DateTime.fromMillisecondsSinceEpoch(0);
  bool _isProcessing = false;

  FrameThrottler({this.throttleIntervalMs = 65});

  bool get isProcessing => _isProcessing;

  /// Memeriksa apakah frame saat ini boleh diproses.
  bool shouldProcess() {
    if (_isProcessing) return false;
    final now = DateTime.now();
    if (now.difference(_lastExecutionTime).inMilliseconds >= throttleIntervalMs) {
      return true;
    }
    return false;
  }

  /// Menandai frame sedang dieksekusi.
  void startProcessing() {
    _isProcessing = true;
  }

  /// Menandai pemrosesan frame selesai.
  void finishProcessing() {
    _lastExecutionTime = DateTime.now();
    _isProcessing = false;
  }

  /// Reset kondisi throttler.
  void reset() {
    _isProcessing = false;
    _lastExecutionTime = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
