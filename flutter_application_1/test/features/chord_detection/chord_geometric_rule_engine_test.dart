import 'package:flutter_test/flutter_test.dart';
import 'package:fretmaster/features/chord_detection/data/datasources/tflite_mlp_vision_data_source.dart';
import 'package:fretmaster/features/chord_detection/domain/services/chord_geometric_rule_engine.dart';

void main() {
  late ChordGeometricRuleEngine ruleEngine;
  late TfliteMlpVisionDataSourceImpl dataSourceHelper;

  setUp(() {
    ruleEngine = const ChordGeometricRuleEngine();
    dataSourceHelper = TfliteMlpVisionDataSourceImpl();
  });

  group('ChordGeometricRuleEngine Tests', () {
    test('Mengembalikan status kosong jika landmarks kurang dari 21 titik', () {
      final eval = ruleEngine.evaluate(const []);
      expect(eval.primaryChord, '---');
      expect(eval.primaryScore, 0.0);
      expect(eval.ruleScores.isEmpty, true);
    });

    test('Mengevaluasi template chord C dan menghasilkan skor C tinggi', () {
      final cLandmarks = dataSourceHelper.generateChordLandmarks('C');
      final eval = ruleEngine.evaluate(cLandmarks);

      expect(eval.ruleScores.containsKey('C'), true);
      expect(eval.ruleScores['C']!, greaterThanOrEqualTo(0.50));
      expect(eval.diagnosticHint.isNotEmpty, true);
    });

    test('Mengevaluasi template chord G dan menghasilkan skor G tinggi karena span lebar', () {
      final gLandmarks = dataSourceHelper.generateChordLandmarks('G');
      final eval = ruleEngine.evaluate(gLandmarks);

      expect(eval.ruleScores.containsKey('G'), true);
      expect(eval.ruleScores['G']!, greaterThanOrEqualTo(0.40));
    });

    test('Mengevaluasi template chord A dan menghasilkan skor A tinggi karena klaster 3 jari', () {
      final aLandmarks = dataSourceHelper.generateChordLandmarks('A');
      final eval = ruleEngine.evaluate(aLandmarks);

      expect(eval.ruleScores.containsKey('A'), true);
      expect(eval.ruleScores['A']!, greaterThanOrEqualTo(0.50));
    });

    test('Mengevaluasi template chord D dan menghasilkan skor D tinggi', () {
      final dLandmarks = dataSourceHelper.generateChordLandmarks('D');
      final eval = ruleEngine.evaluate(dLandmarks);

      expect(eval.ruleScores.containsKey('D'), true);
      expect(eval.ruleScores['D']!, greaterThanOrEqualTo(0.50));
    });

    test('Mengevaluasi template chord Dm dan menghasilkan skor Dm tinggi', () {
      final dmLandmarks = dataSourceHelper.generateChordLandmarks('Dm');
      final eval = ruleEngine.evaluate(dmLandmarks);

      expect(eval.ruleScores.containsKey('Dm'), true);
      expect(eval.ruleScores['Dm']!, greaterThanOrEqualTo(0.50));
    });

    test('Mengevaluasi template chord F dan menghasilkan skor F tinggi', () {
      final fLandmarks = dataSourceHelper.generateChordLandmarks('F');
      final eval = ruleEngine.evaluate(fLandmarks);

      expect(eval.ruleScores.containsKey('F'), true);
      expect(eval.ruleScores['F']!, greaterThanOrEqualTo(0.50));
    });

    test('Mengevaluasi template chord B dan menghasilkan skor B tinggi', () {
      final bLandmarks = dataSourceHelper.generateChordLandmarks('B');
      final eval = ruleEngine.evaluate(bLandmarks);

      expect(eval.ruleScores.containsKey('B'), true);
      expect(eval.ruleScores['B']!, greaterThanOrEqualTo(0.50));
    });

    test('Mengevaluasi template chord E dan memastikan skor E lebih tinggi dari Am', () {
      final eLandmarks = dataSourceHelper.generateChordLandmarks('E');
      final eval = ruleEngine.evaluate(eLandmarks);

      expect(eval.ruleScores.containsKey('E'), true);
      expect(eval.ruleScores['E']!, greaterThan(eval.ruleScores['Am']!));
    });

    test('fuseWithMlProbabilities menstabilkan probabilitas dan menyelesaikan ambiguitas', () {
      // Skenario: MLP ragu antara C (45%) dan Am (45%)
      final mlProbs = {
        'C': 0.45,
        'Am': 0.45,
        'G': 0.05,
        'D': 0.05,
      };

      // Aturan geometri memastikan bentuk C (skor C 0.90, skor Am 0.10)
      final ruleScores = {
        'C': 0.90,
        'Am': 0.10,
        'G': 0.10,
        'D': 0.10,
      };

      final fused = ruleEngine.fuseWithMlProbabilities(
        mlProbs,
        ruleScores,
        mlWeight: 0.50,
        ruleWeight: 0.50,
      );

      // C harus menang mutlak setelah fusi
      expect(fused['C']!, greaterThan(fused['Am']!));
      expect(fused['C']!, greaterThan(0.50));

      // Total probabilitas ternormalisasi mendekati 1.0
      final total = fused.values.reduce((a, b) => a + b);
      expect(total, closeTo(1.0, 0.01));
    });
  });
}
