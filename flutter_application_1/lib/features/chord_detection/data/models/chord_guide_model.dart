import '../../domain/entities/chord_guide.dart';

class ChordGuideModel extends ChordGuide {
  const ChordGuideModel({
    super.id,
    required super.name,
    required super.fullName,
    required super.notes,
    required super.frets,
    required super.fingers,
    required super.difficulty,
    required super.tip,
    required super.strum,
  });

  factory ChordGuideModel.fromJson(Map<String, dynamic> json) {
    return ChordGuideModel(
      id: json['id'] is int ? json['id'] : (json['id'] != null ? int.tryParse(json['id'].toString()) : null),
      name: json['name'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      frets: (json['frets'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [-1, -1, -1, -1, -1, -1],
      fingers: (json['fingers'] as List<dynamic>?)?.map((e) => (e as num).toInt()).toList() ?? [0, 0, 0, 0, 0, 0],
      difficulty: json['difficulty'] as String? ?? 'Mudah',
      tip: json['tip'] as String? ?? '',
      strum: json['strum'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'full_name': fullName,
      'notes': notes,
      'frets': frets,
      'fingers': fingers,
      'difficulty': difficulty,
      'tip': tip,
      'strum': strum,
    };
  }
}
