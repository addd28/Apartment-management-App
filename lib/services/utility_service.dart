import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/utility_usage_model.dart';

class UtilityService {
  final Dio _dio = ApiClient().dio;

  Future<List<UtilityUsageModel>> getMyUtilityUsages() async {
    try {
      final response = await _dio.get('/UtilityUsages/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => UtilityUsageModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
