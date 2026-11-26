import '../../domain/entities/practice_drill.dart';

class PracticeDrillModel extends PracticeDrill {
  const PracticeDrillModel({
    required super.id,
    required super.title,
    required super.description,
    required super.chords,
    required super.targetBpm,
    required super.difficulty,
  });

  factory PracticeDrillModel.fromJson(Map<String, dynamic> json) {
    return PracticeDrillModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      chords: (json['chords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      targetBpm: json['target_bpm'] is int ? json['target_bpm'] : int.tryParse(json['target_bpm']?.toString() ?? '60') ?? 60,
      difficulty: json['difficulty'] as String? ?? 'Pemula',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'chords': chords,
      'target_bpm': targetBpm,
      'difficulty': difficulty,
    };
  }
}
