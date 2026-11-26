import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chord_guide.dart';
import '../widgets/chord_diagram_view.dart';
import 'chord_scanner_page.dart';

class ChordDetailPage extends StatelessWidget {
  final ChordGuide chordGuide;

  const ChordDetailPage({super.key, required this.chordGuide});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${chordGuide.fullName} (${chordGuide.name})'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: ChordDiagramView(
                chordGuide: chordGuide,
                width: 240,
                height: 300,
              ),
            ),
            const SizedBox(height: 24),
            _buildDetailCard(
              title: 'Nada Penyusun (Notes)',
              content: chordGuide.notes,
              icon: Icons.music_note_rounded,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              title: 'Tingkat Kesulitan',
              content: chordGuide.difficulty,
              icon: Icons.speed_rounded,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              title: 'Cara Petik (Strumming)',
              content: chordGuide.strum,
              icon: Icons.waves_rounded,
            ),
            const SizedBox(height: 12),
            _buildDetailCard(
              title: 'Tips Penjarian FretMaster',
              content: chordGuide.tip,
              icon: Icons.lightbulb_outline_rounded,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.videocam_rounded),
              label: Text('Mulai Deteksi Kamera untuk Chord ${chordGuide.name}'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChordScannerPage(initialTargetChord: chordGuide),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required String content,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
