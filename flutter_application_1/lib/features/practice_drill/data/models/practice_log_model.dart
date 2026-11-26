import '../../domain/entities/practice_log.dart';

class PracticeLogModel extends PracticeLog {
  const PracticeLogModel({
    super.id,
    super.drillId,
    super.drillTitle,
    super.chordName,
    required super.accuracy,
    required super.bpm,
    required super.durationSeconds,
    super.notes,
    required super.createdAt,
  });

  factory PracticeLogModel.fromJson(Map<String, dynamic> json) {
    String? drillTitle;
    if (json['drill'] is Map<String, dynamic>) {
      drillTitle = json['drill']['title'] as String?;
    }

    return PracticeLogModel(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      drillId: json['drill_id'] is int ? json['drill_id'] : (json['drill_id'] != null ? int.tryParse(json['drill_id'].toString()) : null),
      drillTitle: drillTitle,
      chordName: json['chord_name'] as String?,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      bpm: json['bpm'] is int ? json['bpm'] : (int.tryParse(json['bpm']?.toString() ?? '60') ?? 60),
      durationSeconds: json['duration_seconds'] is int
          ? json['duration_seconds']
          : (int.tryParse(json['duration_seconds']?.toString() ?? '0') ?? 0),
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (drillId != null) 'drill_id': drillId,
      if (chordName != null) 'chord_name': chordName,
      'accuracy': accuracy,
      'bpm': bpm,
      'duration_seconds': durationSeconds,
      if (notes != null) 'notes': notes,
    };
  }
}
