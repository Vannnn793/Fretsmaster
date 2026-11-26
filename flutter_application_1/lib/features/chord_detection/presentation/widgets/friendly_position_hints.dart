import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chord_detection_result.dart';

/// FriendlyPositionHints: Petunjuk ramah pemula ketika tangan belum pas di kamera
/// atau kepercayaan prediksi AI masih rendah.
class FriendlyPositionHints extends StatelessWidget {
  final ChordDetectionResult? detectionResult;
  final bool isTargetMatched;

  const FriendlyPositionHints({
    super.key,
    required this.detectionResult,
    required this.isTargetMatched,
  });

  @override
  Widget build(BuildContext context) {
    if (detectionResult == null) {
      return const SizedBox.shrink();
    }

    final isDetected = detectionResult!.isChord;
    final hint = detectionResult!.positionHint;
    final confidence = (detectionResult!.confidence * 100).toInt();

    Color cardBorder;
    Color iconColor;
    IconData icon;

    if (isTargetMatched) {
      cardBorder = AppColors.success;
      iconColor = AppColors.success;
      icon = Icons.check_circle_rounded;
    } else if (isDetected) {
      cardBorder = AppColors.primary;
      iconColor = AppColors.primary;
      icon = Icons.music_note_rounded;
    } else {
      cardBorder = AppColors.surfaceBorder;
      iconColor = AppColors.warning;
      icon = Icons.info_outline_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: cardBorder.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTargetMatched
                          ? 'CHORD COCOK & SEMPURNA!'
                          : (isDetected ? 'TERDETEKSI: ${detectionResult!.chordName}' : 'PANDUAN POSISI'),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: isTargetMatched
                            ? AppColors.success
                            : (isDetected ? AppColors.primary : AppColors.textPrimary),
                        letterSpacing: 0.6,
                      ),
                    ),
                    if (isDetected)
                      Text(
                        '$confidence% Akurat',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
