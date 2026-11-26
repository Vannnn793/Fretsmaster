import 'dart:typed_data';
import 'package:camera/camera.dart';

/// Konverter in-memory frame kamera YUV_420_888 menjadi tensor Float32List [1, 224, 224, 3].
///
/// Mode preprocessing:
/// - [PreprocessMode.mobilenet]: range [-1.0, 1.0] → untuk MobileNetV2 (default baru)
/// - [PreprocessMode.normalized]: range [0.0, 1.0]  → untuk model CNN lama
enum PreprocessMode { mobilenet, normalized }

class FrameConverter {
  FrameConverter._();

  static const int inputSize = 224;
  static const int _pixelCount = inputSize * inputSize;

  /// Mengubah frame YUV420 menjadi float32 tensor.
  /// [mode] menentukan range normalisasi:
  ///   MobileNetV2 → [-1.0, 1.0]  (default, dipakai untuk chord_model.tflite baru)
  ///   Normalized  → [0.0,  1.0]  (model CNN lama)
  static Float32List? yuv420ToFloat32Tensor(
    CameraImage image,
    int sensorRotation, {
    PreprocessMode mode = PreprocessMode.mobilenet,
  }) {
    if (image.planes.length < 3) return null;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final int srcW = image.width;
    final int srcH = image.height;
    final bool swap = sensorRotation == 90 || sensorRotation == 270;
    final int dstW = swap ? srcH : srcW;
    final int dstH = swap ? srcW : srcH;

    final Uint8List yBytes = yPlane.bytes;
    final Uint8List uBytes = uPlane.bytes;
    final Uint8List vBytes = vPlane.bytes;

    final int yRowStride = yPlane.bytesPerRow;
    final int uvRowStride = uPlane.bytesPerRow;
    final int uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final Float32List out = Float32List(_pixelCount * 3);
    final double scaleX = dstW / inputSize;
    final double scaleY = dstH / inputSize;

    int outIdx = 0;

    for (int ty = 0; ty < inputSize; ty++) {
      final double fy = (ty + 0.5) * scaleY - 0.5;
      for (int tx = 0; tx < inputSize; tx++) {
        final double fx = (tx + 0.5) * scaleX - 0.5;

        double rowF, colF;
        switch (sensorRotation) {
          case 90:
            rowF = (srcH - 1) - fx;
            colF = fy;
            break;
          case 180:
            rowF = (srcH - 1) - fy;
            colF = (srcW - 1) - fx;
            break;
          case 270:
            rowF = fx;
            colF = (srcW - 1) - fy;
            break;
          default:
            rowF = fy;
            colF = fx;
        }

        final int row = rowF.round().clamp(0, srcH - 1);
        final int col = colF.round().clamp(0, srcW - 1);

        final int yIndex = row * yRowStride + col;
        final int uvIndex = (row >> 1) * uvRowStride + (col >> 1) * uvPixelStride;

        final double yVal = yBytes[yIndex].toDouble();
        final double uVal = uBytes[uvIndex].toDouble();
        final double vVal = vBytes[uvIndex].toDouble();

        // Standard BT.601 YUV -> RGB [0, 255]
        final double r = (yVal + 1.402 * (vVal - 128)).clamp(0.0, 255.0);
        final double g = (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128)).clamp(0.0, 255.0);
        final double b = (yVal + 1.772 * (uVal - 128)).clamp(0.0, 255.0);

        if (mode == PreprocessMode.mobilenet) {
          // MobileNetV2: (pixel / 127.5) - 1.0  → range [-1.0, 1.0]
          out[outIdx++] = r / 127.5 - 1.0;
          out[outIdx++] = g / 127.5 - 1.0;
          out[outIdx++] = b / 127.5 - 1.0;
        } else {
          // Normalized: pixel / 255.0  → range [0.0, 1.0]
          out[outIdx++] = r / 255.0;
          out[outIdx++] = g / 255.0;
          out[outIdx++] = b / 255.0;
        }
      }
    }
    return out;
  }
}
