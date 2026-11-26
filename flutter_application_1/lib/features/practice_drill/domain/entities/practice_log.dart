import 'package:equatable/equatable.dart';

class PracticeLog extends Equatable {
  final int? id;
  final int? drillId;
  final String? drillTitle;
  final String? chordName;
  final double accuracy;
  final int bpm;
  final int durationSeconds;
  final String? notes;
  final DateTime createdAt;

  const PracticeLog({
    this.id,
    this.drillId,
    this.drillTitle,
    this.chordName,
    required this.accuracy,
    required this.bpm,
    required this.durationSeconds,
    this.notes,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        drillId,
        drillTitle,
        chordName,
        accuracy,
        bpm,
        durationSeconds,
        notes,
        createdAt,
      ];
}
