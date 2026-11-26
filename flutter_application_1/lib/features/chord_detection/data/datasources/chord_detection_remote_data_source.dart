import '../../../../core/network/api_client.dart';
import '../models/chord_guide_model.dart';

abstract class ChordDetectionRemoteDataSource {
  Future<List<ChordGuideModel>> getChordGuides();
  Future<ChordGuideModel> getChordDetail(String name);
}

class ChordDetectionRemoteDataSourceImpl implements ChordDetectionRemoteDataSource {
  final ApiClient apiClient;

  ChordDetectionRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<ChordGuideModel>> getChordGuides() async {
    final response = await apiClient.get('/chords', auth: false);
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list.map((item) => ChordGuideModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<ChordGuideModel> getChordDetail(String name) async {
    final response = await apiClient.get('/chords/$name', auth: false);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return ChordGuideModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Detail chord tidak ditemukan.');
  }
}
