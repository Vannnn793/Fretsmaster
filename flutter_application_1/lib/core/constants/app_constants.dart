class AppConstants {
  // API URLs
  static const String defaultBaseUrl = 'http://10.0.2.2:8000/api'; // Android Emulator
  static const String fallbackLocalUrl = 'http://localhost:8000/api'; // Web/Desktop/iOS
  
  // Storage Keys
  static const String keyApiBaseUrl = 'fretmaster_api_base_url';
  static const String keyAuthToken = 'fretmaster_auth_token';
  static const String keyUserData = 'fretmaster_user_data';
  static const String keyDetectionThreshold = 'fretmaster_detection_threshold';
  static const String keyFrameThrottleMs = 'fretmaster_frame_throttle_ms';
  
  // Model Assets
  static const String modelHandLandmarkPath = 'assets/models/hand_landmark.tflite';
  static const String modelTflitePath = 'assets/models/chord_model.tflite';
  static const String modelLegacyVisionPath = 'assets/models/fretmaster_model.tflite';
  static const String modelLabelsPath = 'assets/models/labels.txt';
  static const String modelNormParamsPath = 'assets/models/normalization_params.json';
  
  // Detection Timing & Thresholds
  static const int defaultThrottleMs = 65; // ~15-20 FPS inference to keep UI 60 FPS
  static const double defaultConfidenceThreshold = 0.65;
  static const int temporalWindowSize = 5; // Moving average window
  
  // Supported Chords List (10 Open & Essential Chords)
  static const List<String> supportedChords = [
    'A', 'Am', 'B', 'C', 'D', 'Dm', 'E', 'Em', 'F', 'G'
  ];
}
