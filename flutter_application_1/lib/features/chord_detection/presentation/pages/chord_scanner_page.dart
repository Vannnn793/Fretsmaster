import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chord_guide.dart';
import '../../domain/entities/fretboard_context.dart';
import '../bloc/chord_detection_bloc.dart';
import '../bloc/chord_detection_event.dart';
import '../bloc/chord_detection_state.dart';
import '../widgets/camera_framing_guide.dart';
import '../widgets/finger_guide_overlay.dart';
import '../widgets/friendly_position_hints.dart';

class ChordScannerPage extends StatefulWidget {
  final ChordGuide? initialTargetChord;

  const ChordScannerPage({super.key, this.initialTargetChord});

  @override
  State<ChordScannerPage> createState() => _ChordScannerPageState();
}

class _ChordScannerPageState extends State<ChordScannerPage>
    with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  bool _cameraInitialized = false;
  bool _isTorchOn = false;
  bool _showAnchorControls = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    context.read<ChordDetectionBloc>().add(const InitializeChordDetection());
    if (widget.initialTargetChord != null) {
      context.read<ChordDetectionBloc>().add(SetTargetChordGuide(widget.initialTargetChord));
    }
    _initCamera();
  }

  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      setState(() {
        _errorMessage = 'Izin kamera dibutuhkan untuk memindai posisi jari pada gitar.';
      });
      return;
    }

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'Tidak ada sensor kamera yang terdeteksi di perangkat.';
        });
        return;
      }

      await _startCamera(_cameras[_cameraIndex]);
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal mengakses kamera: $e';
      });
    }
  }

  Future<void> _startCamera(CameraDescription camera) async {
    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    _cameraController = controller;

    try {
      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _cameraInitialized = true;
        _errorMessage = null;
      });

      await controller.startImageStream((CameraImage image) {
        if (!mounted) return;
        context.read<ChordDetectionBloc>().add(
              ProcessCameraFrame(
                image: image,
                sensorOrientation: camera.sensorOrientation,
              ),
            );
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Gagal menginisialisasi streaming kamera: $e';
        });
      }
    }
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    final nextCamera = _cameras[_cameraIndex];
    final isFront = nextCamera.lensDirection == CameraLensDirection.front;

    final bloc = context.read<ChordDetectionBloc>();
    final currentState = bloc.state;
    if (currentState is ChordDetectionReady) {
      bloc.add(UpdateFretboardAnchor(
        currentState.fretboardAnchor.copyWith(mirrorStrings: isFront),
      ));
    }

    await _cameraController?.stopImageStream();
    await _cameraController?.dispose();
    _cameraController = null;
    setState(() => _cameraInitialized = false);
    await _startCamera(nextCamera);
  }

  Future<void> _toggleTorch() async {
    if (_cameraController == null) return;
    try {
      final newMode = _isTorchOn ? FlashMode.off : FlashMode.torch;
      await _cameraController!.setFlashMode(newMode);
      setState(() => _isTorchOn = !_isTorchOn);
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _cameraController?.dispose();
    } else if (state == AppLifecycleState.resumed) {
      if (_cameras.isNotEmpty) {
        _startCamera(_cameras[_cameraIndex]);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocConsumer<ChordDetectionBloc, ChordDetectionState>(
          listener: (context, state) {
            if (state is ChordDetectionFailureState) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage),
                  backgroundColor: AppColors.error,
                ),
              );
            }
          },
          builder: (context, state) {
            final readyState = state is ChordDetectionReady ? state : null;
            final latestResult = readyState?.latestResult;
            final targetChord = readyState?.targetChord;
            final isMatched = readyState?.isTargetMatched ?? false;
            final activeAnchor = readyState?.fretboardAnchor ?? const FretboardAnchor();

            final detectedChord = latestResult?.chordName ?? '---';
            final isChordValid = latestResult?.isChord ?? false;
            final confidenceVal = latestResult?.confidence ?? 0.0;
            final confidencePercent = (confidenceVal * 100).toInt().clamp(0, 100);

            return Stack(
              children: [
                // 1. Kamera Preview (dengan drag-to-anchor saat kalibrasi aktif)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onPanUpdate: _showAnchorControls
                        ? (details) {
                            final size = MediaQuery.of(context).size;
                            final newCx = (activeAnchor.centerX + details.delta.dx / size.width)
                                .clamp(0.15, 0.85);
                            final newCy = (activeAnchor.centerY + details.delta.dy / size.height)
                                .clamp(0.18, 0.82);
                            context.read<ChordDetectionBloc>().add(
                                  UpdateFretboardAnchor(
                                    activeAnchor.copyWith(
                                      centerX: newCx,
                                      centerY: newCy,
                                      autoTrackNeck: false,
                                    ),
                                  ),
                                );
                          }
                        : null,
                    child: _cameraInitialized && _cameraController != null
                        ? ClipRRect(
                            child: AspectRatio(
                              aspectRatio: _cameraController!.value.aspectRatio,
                              child: CameraPreview(_cameraController!),
                            ),
                          )
                        : Center(
                            child: _errorMessage != null
                                ? Padding(
                                    padding: const EdgeInsets.all(24.0),
                                    child: Text(
                                      _errorMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: AppColors.error),
                                    ),
                                  )
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      CircularProgressIndicator(color: AppColors.primary),
                                      SizedBox(height: 16),
                                      Text(
                                        'Membuka kamera & mengaktifkan AI FretMaster...',
                                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                      ),
                                    ],
                                  ),
                          ),
                  ),
                ),

                // 2. Camera Framing Guide (Fretboard Fret 1–5 Overlay + Active Finger Touch Points)
                Positioned.fill(
                  child: CameraFramingGuide(
                    detectedFingertips: latestResult?.fretboardContext?.activeFingers ?? const [],
                    anchor: activeAnchor,
                    isCalibrating: _showAnchorControls,
                  ),
                ),

                // 3. Finger Guide Overlay (Jika ada target chord yang dipilih)
                if (targetChord != null)
                  Positioned.fill(
                    child: FingerGuideOverlay(
                      chordGuide: targetChord,
                      anchor: activeAnchor,
                    ),
                  ),

                // 4. Header Atas: Back button, Target Chord Pill, Controls
                Positioned(
                  top: 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.surface.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: isMatched ? AppColors.success : AppColors.surfaceBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isMatched ? Icons.check_circle : Icons.music_note,
                                color: isMatched ? AppColors.success : AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  targetChord != null
                                      ? 'Target: ${targetChord.name} (${targetChord.fullName})'
                                      : 'Mode Bebas (Semua Akord)',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CircleIconButton(
                        icon: Icons.tune_rounded,
                        iconColor: _showAnchorControls ? AppColors.primary : AppColors.textPrimary,
                        onTap: () => setState(() => _showAnchorControls = !_showAnchorControls),
                      ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: _isTorchOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                        iconColor: _isTorchOn ? AppColors.primary : AppColors.textPrimary,
                        onTap: _toggleTorch,
                      ),
                      const SizedBox(width: 8),
                      _CircleIconButton(
                        icon: Icons.flip_camera_ios_rounded,
                        onTap: _switchCamera,
                      ),
                    ],
                  ),
                ),

                // 5. PROMINENT REAL-TIME CHORD HUD (TAMPILAN UTAMA STATUS CHORD)
                Positioned(
                  top: 72,
                  left: 20,
                  right: 20,
                  child: _RealTimeChordHUD(
                    detectedChord: detectedChord,
                    isChordValid: isChordValid,
                    confidencePercent: confidencePercent,
                    confidenceFraction: confidenceVal,
                    targetChord: targetChord,
                    isMatched: isMatched,
                    rawProbabilities: latestResult?.rawProbabilities ?? {},
                    inferenceTimeMs: latestResult?.inferenceTimeMs ?? 0.0,
                    fretboardSummary: latestResult?.fretboardContext?.fretboardSummary,
                  ),
                ),

                // 6. Friendly Position Hints Card atau Panel Kalibrasi Anchor Fretboard di Bawah
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: _showAnchorControls
                      ? _FretboardAnchorPanel(
                          anchor: activeAnchor,
                          onAnchorChanged: (updated) {
                            context.read<ChordDetectionBloc>().add(UpdateFretboardAnchor(updated));
                          },
                          onClose: () => setState(() => _showAnchorControls = false),
                        )
                      : FriendlyPositionHints(
                          detectionResult: latestResult,
                          isTargetMatched: isMatched,
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Panel Kalibrasi Jangkar Fretboard (Orientasi, Auto-Track Leher, Mirror, & Geser)
class _FretboardAnchorPanel extends StatelessWidget {
  final FretboardAnchor anchor;
  final ValueChanged<FretboardAnchor> onAnchorChanged;
  final VoidCallback onClose;

  const _FretboardAnchorPanel({
    required this.anchor,
    required this.onAnchorChanged,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isVertical = anchor.angleRad.abs() < 0.20;
    final isAngled = (anchor.angleRad + math.pi / 5.2).abs() < 0.25;
    final isHorizontal = (anchor.angleRad + math.pi / 2).abs() < 0.25;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.65), width: 1.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.straighten_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Jangkar Fretboard (Geser kotak di layar)',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _AnchorChip(
                label: 'Vertikal 0°',
                selected: isVertical && !anchor.autoTrackNeck,
                onTap: () => onAnchorChanged(
                  FretboardAnchor.vertical(mirrorStrings: anchor.mirrorStrings),
                ),
              ),
              _AnchorChip(
                label: 'Miring -35°',
                selected: isAngled && !anchor.autoTrackNeck,
                onTap: () => onAnchorChanged(
                  FretboardAnchor.angled(mirrorStrings: anchor.mirrorStrings),
                ),
              ),
              _AnchorChip(
                label: 'Datar -90°',
                selected: isHorizontal && !anchor.autoTrackNeck,
                onTap: () => onAnchorChanged(
                  FretboardAnchor.horizontal(mirrorStrings: anchor.mirrorStrings),
                ),
              ),
              _AnchorChip(
                label: 'Auto-Track Leher',
                selected: anchor.autoTrackNeck,
                onTap: () => onAnchorChanged(
                  anchor.copyWith(autoTrackNeck: !anchor.autoTrackNeck),
                ),
              ),
              _AnchorChip(
                label: 'Mirror Senar',
                selected: anchor.mirrorStrings,
                onTap: () => onAnchorChanged(
                  anchor.copyWith(mirrorStrings: !anchor.mirrorStrings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnchorChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AnchorChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.surfaceBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? const Color(0xFF1A1200) : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// HUD Utama Real-Time yang menampilkan chord apa yang sedang ditekan
class _RealTimeChordHUD extends StatelessWidget {
  final String detectedChord;
  final bool isChordValid;
  final int confidencePercent;
  final double confidenceFraction;
  final ChordGuide? targetChord;
  final bool isMatched;
  final Map<String, double> rawProbabilities;
  final double inferenceTimeMs;
  final String? fretboardSummary;

  const _RealTimeChordHUD({
    required this.detectedChord,
    required this.isChordValid,
    required this.confidencePercent,
    required this.confidenceFraction,
    required this.targetChord,
    required this.isMatched,
    required this.rawProbabilities,
    required this.inferenceTimeMs,
    this.fretboardSummary,
  });

  @override
  Widget build(BuildContext context) {
    Color cardBorder;
    Color accentColor;
    String statusTitle;

    if (isMatched) {
      cardBorder = AppColors.success;
      accentColor = AppColors.success;
      statusTitle = 'AKORD COCOK DENGAN TARGET!';
    } else if (isChordValid) {
      cardBorder = AppColors.primary;
      accentColor = AppColors.primary;
      statusTitle = targetChord != null
          ? 'SEDANG MENEKAN: $detectedChord (Target: ${targetChord!.name})'
          : 'AKORD TERDETEKSI';
    } else {
      cardBorder = AppColors.surfaceBorder;
      accentColor = AppColors.warning;
      statusTitle = 'MENYESUAIKAN PENJARIAN...';
    }

    // Ambil 3 kandidat probabilitas tertinggi
    final sortedEntries = rawProbabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCandidates = sortedEntries.take(3).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 2.0),
        boxShadow: [
          BoxShadow(
            color: cardBorder.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Baris Atas: Label Status & Indikator Live
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: accentColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    statusTitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Text(
                '${inferenceTimeMs.toInt()} ms',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Teks Utama Besar: Nama Chord yang Sedang Ditekan
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CHORD YANG DITEKAN:',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isChordValid ? detectedChord : '---',
                    style: TextStyle(
                      fontSize: 42,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                      color: isMatched
                          ? AppColors.success
                          : (isChordValid ? AppColors.primary : AppColors.textPrimary),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
              // Gauge Persentase Akurasi
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  children: [
                    Text(
                      '$confidencePercent%',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                      ),
                    ),
                    const Text(
                      'Keyakinan AI',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Bar Meter Keyakinan
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confidenceFraction.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.surfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(accentColor),
            ),
          ),

          // Baris Bawah: Breakdown Probabilitas Chord Teratas
          if (topCandidates.isNotEmpty && isChordValid) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: topCandidates.map((entry) {
                final pct = (entry.value * 100).toInt();
                final isTop = entry.key == detectedChord;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isTop ? accentColor.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${entry.key}: $pct%',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: isTop ? FontWeight.w800 : FontWeight.w500,
                      color: isTop ? accentColor : AppColors.textMuted,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          // Indikator Posisi Jari pada Fretboard Fisik
          if (fretboardSummary != null && isChordValid) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.grid_on_rounded,
                    size: 13,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fretboardSummary!,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleIconButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.85),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
    );
  }
}
