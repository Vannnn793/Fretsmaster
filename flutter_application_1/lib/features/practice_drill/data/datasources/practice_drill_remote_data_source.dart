import '../../../../core/network/api_client.dart';
import '../models/practice_drill_model.dart';
import '../models/practice_log_model.dart';

abstract class PracticeDrillRemoteDataSource {
  Future<List<PracticeDrillModel>> getDrills();
  Future<PracticeDrillModel> getDrillDetail(int id);
  Future<List<PracticeLogModel>> getPracticeLogs();
  Future<PracticeLogModel> savePracticeLog(PracticeLogModel model);
}

class PracticeDrillRemoteDataSourceImpl implements PracticeDrillRemoteDataSource {
  final ApiClient apiClient;

  PracticeDrillRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<PracticeDrillModel>> getDrills() async {
    final response = await apiClient.get('/drills', auth: false);
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list.map((item) => PracticeDrillModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<PracticeDrillModel> getDrillDetail(int id) async {
    final response = await apiClient.get('/drills/$id', auth: false);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return PracticeDrillModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    throw Exception('Detail drill latihan tidak ditemukan.');
  }

  @override
  Future<List<PracticeLogModel>> getPracticeLogs() async {
    final response = await apiClient.get('/practice-logs', auth: false);
    if (response is Map<String, dynamic> && response['data'] is List) {
      final list = response['data'] as List<dynamic>;
      return list.map((item) => PracticeLogModel.fromJson(item as Map<String, dynamic>)).toList();
    }
    return [];
  }

  @override
  Future<PracticeLogModel> savePracticeLog(PracticeLogModel model) async {
    final response = await apiClient.post('/practice-logs', body: model.toJson(), auth: false);
    if (response is Map<String, dynamic> && response['data'] != null) {
      return PracticeLogModel.fromJson(response['data'] as Map<String, dynamic>);
    }
    return model;
  }
}
