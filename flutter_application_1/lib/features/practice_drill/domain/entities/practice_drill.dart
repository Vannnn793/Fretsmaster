import 'package:equatable/equatable.dart';

class PracticeDrill extends Equatable {
  final int id;
  final String title;
  final String description;
  final List<String> chords;
  final int targetBpm;
  final String difficulty;

  const PracticeDrill({
    required this.id,
    required this.title,
    required this.description,
    required this.chords,
    required this.targetBpm,
    required this.difficulty,
  });

  @override
  List<Object?> get props => [id, title, description, chords, targetBpm, difficulty];
}
