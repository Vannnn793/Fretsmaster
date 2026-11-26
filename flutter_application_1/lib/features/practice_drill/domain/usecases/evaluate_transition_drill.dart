import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';

class TransitionEvaluationResult {
  final String expectedChord;
  final String detectedChord;
  final bool isSuccessful;
  final double transitionTimeMs;
  final double accuracyScore;

  TransitionEvaluationResult({
    required this.expectedChord,
    required this.detectedChord,
    required this.isSuccessful,
    required this.transitionTimeMs,
    required this.accuracyScore,
  });
}

class EvaluateTransitionParams {
  final String targetChord;
  final String detectedChord;
  final double confidence;
  final double transitionDurationMs;
  final int targetBpm;

  EvaluateTransitionParams({
    required this.targetChord,
    required this.detectedChord,
    required this.confidence,
    required this.transitionDurationMs,
    required this.targetBpm,
  });
}

/// Evaluasi perpindahan chord dalam drill transisi berdasarkan ketepatan beat & deteksi
class EvaluateTransitionDrill implements UseCase<TransitionEvaluationResult, EvaluateTransitionParams> {
  @override
  Future<Either<Failure, TransitionEvaluationResult>> call(EvaluateTransitionParams params) async {
    final isMatched = params.targetChord.toLowerCase() == params.detectedChord.toLowerCase();

    // Hitung waktu ideal satu ketukan (beat) dalam milidetik: (60 / BPM) * 1000
    final idealBeatMs = (60.0 / params.targetBpm) * 1000.0;
    
    // Skor akurasi timing (semakin mendekati beat tempo, semakin tinggi)
    final timeDiff = (params.transitionDurationMs - idealBeatMs).abs();
    final timingScore = (1.0 - (timeDiff / (idealBeatMs * 1.5))).clamp(0.0, 1.0);
    
    final overallAccuracy = isMatched ? (0.6 * params.confidence + 0.4 * timingScore) * 100.0 : 0.0;

    return Right(
      TransitionEvaluationResult(
        expectedChord: params.targetChord,
        detectedChord: params.detectedChord,
        isSuccessful: isMatched,
        transitionTimeMs: params.transitionDurationMs,
        accuracyScore: overallAccuracy,
      ),
    );
  }
}
