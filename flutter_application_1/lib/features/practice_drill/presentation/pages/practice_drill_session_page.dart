import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/practice_drill.dart';
import '../bloc/practice_drill_bloc.dart';
import '../bloc/practice_drill_event.dart';
import '../bloc/practice_drill_state.dart';
import '../widgets/drill_progress_ui.dart';

class PracticeDrillSessionPage extends StatefulWidget {
  final PracticeDrill drill;

  const PracticeDrillSessionPage({super.key, required this.drill});

  @override
  State<PracticeDrillSessionPage> createState() => _PracticeDrillSessionPageState();
}

class _PracticeDrillSessionPageState extends State<PracticeDrillSessionPage> {
  @override
  void initState() {
    super.initState();
    context.read<PracticeDrillBloc>().add(StartDrillSession(widget.drill));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.drill.title),
        backgroundColor: Colors.transparent,
      ),
      body: BlocConsumer<PracticeDrillBloc, PracticeDrillState>(
        listener: (context, state) {
          if (state is DrillSessionCompleted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppColors.surface,
                title: const Row(
                  children: [
                    Icon(Icons.emoji_events_rounded, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text('Latihan Selesai!'),
                  ],
                ),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Akurasi: ${state.savedLog.accuracy.toInt()}%'),
                    const SizedBox(height: 6),
                    Text('Tempo: ${state.savedLog.bpm} BPM'),
                    const SizedBox(height: 6),
                    Text('Durasi: ${state.savedLog.durationSeconds} detik'),
                    const SizedBox(height: 8),
                    Text(
                      state.savedLog.notes ?? '',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    ),
                  ],
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    child: const Text('Kembali ke Menu'),
                  ),
                ],
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is DrillSessionActive) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Spacer(),
                    DrillProgressUI(
                      currentChord: state.currentTargetChord,
                      nextChord: state.nextChord,
                      currentBeat: state.currentBeat,
                      bpm: state.drill.targetBpm,
                      accuracy: state.currentAccuracyPercent,
                      elapsedSeconds: state.elapsedSeconds,
                      completedTransitions: state.completedTransitions,
                    ),
                    const Spacer(),

                    // Tombol simulasi deteksi transisi chord / tap saat chord berpindah
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.touch_app_rounded, color: AppColors.primary),
                            label: Text(
                              'Tap: Transisi ke ${state.currentTargetChord}',
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              context.read<PracticeDrillBloc>().add(
                                    RecordChordTransition(
                                      detectedChord: state.currentTargetChord,
                                      confidence: 0.95,
                                    ),
                                  );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Tombol Selesaikan Latihan
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.surfaceElevated,
                          foregroundColor: AppColors.textPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Selesaikan & Simpan Sesi'),
                        onPressed: () {
                          context.read<PracticeDrillBloc>().add(const FinishDrillSession());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        },
      ),
    );
  }
}
