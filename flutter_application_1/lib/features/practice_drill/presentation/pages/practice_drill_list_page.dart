import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/practice_drill.dart';
import '../bloc/practice_drill_bloc.dart';
import '../bloc/practice_drill_event.dart';
import '../bloc/practice_drill_state.dart';
import 'practice_drill_session_page.dart';
import 'practice_history_page.dart';

class PracticeDrillListPage extends StatefulWidget {
  const PracticeDrillListPage({super.key});

  @override
  State<PracticeDrillListPage> createState() => _PracticeDrillListPageState();
}

class _PracticeDrillListPageState extends State<PracticeDrillListPage> {
  @override
  void initState() {
    super.initState();
    context.read<PracticeDrillBloc>().add(const LoadDrillsAndHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Latihan Transisi Akord'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Sesi Latihan',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PracticeHistoryPage()),
              );
            },
          ),
        ],
      ),
      body: BlocBuilder<PracticeDrillBloc, PracticeDrillState>(
        builder: (context, state) {
          if (state is PracticeDrillLoading) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (state is PracticeDrillError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(state.message, style: const TextStyle(color: AppColors.error)),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => context.read<PracticeDrillBloc>().add(const LoadDrillsAndHistory()),
                    child: const Text('Muat Ulang'),
                  ),
                ],
              ),
            );
          }

          if (state is PracticeDrillOverviewLoaded) {
            final drills = state.drills;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: drills.length,
              itemBuilder: (context, index) {
                final drill = drills[index];
                return _DrillCard(drill: drill);
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _DrillCard extends StatelessWidget {
  final PracticeDrill drill;

  const _DrillCard({required this.drill});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  drill.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  drill.difficulty,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            drill.description,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 14),

          // Chord sequence pills
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: drill.chords.map((chord) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  chord,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primaryLight,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.speed_rounded, size: 18, color: AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Target: ${drill.targetBpm} BPM',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded, size: 18),
                label: const Text('Mulai Latihan'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PracticeDrillSessionPage(drill: drill),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
