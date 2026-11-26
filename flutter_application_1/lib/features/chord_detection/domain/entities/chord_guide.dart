import 'package:equatable/equatable.dart';

class ChordGuide extends Equatable {
  final int? id;
  final String name;
  final String fullName;
  final String notes;
  final List<int> frets;     // 6 int dari senar 6 (E) ke senar 1 (e)
  final List<int> fingers;   // 6 int: 0=lepas, 1=telunjuk, 2=tengah, 3=manis, 4=kelingking
  final String difficulty;
  final String tip;
  final String strum;

  const ChordGuide({
    this.id,
    required this.name,
    required this.fullName,
    required this.notes,
    required this.frets,
    required this.fingers,
    required this.difficulty,
    required this.tip,
    required this.strum,
  });

  int get minFret => frets.where((f) => f > 0).fold(99, (a, b) => a < b ? a : b);
  int get maxFret => frets.where((f) => f > 0).fold(0, (a, b) => a > b ? a : b);

  @override
  List<Object?> get props => [
        id,
        name,
        fullName,
        notes,
        frets,
        fingers,
        difficulty,
        tip,
        strum,
      ];
}
