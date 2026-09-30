import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/move_request_model.dart';

class MoveRequestService {
  final Dio _dio = ApiClient().dio;

  Future<List<MoveRequestModel>> getMyMoveRequests() async {
    try {
      final response = await _dio.get('/MoveRequests/my');
      final data = response.data;
      // Backend may return paged result { items: [...], totalCount: ... } or List
      if (data is List) {
        return data.map((json) => MoveRequestModel.fromJson(json)).toList();
      } else if (data is Map && data['items'] is List) {
        return (data['items'] as List).map((json) => MoveRequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<MoveRequestModel> createMoveRequest({
    required int apartmentId,
    required String type, // MoveIn or MoveOut
    required DateTime scheduledDate,
    required String startTime,
    required String endTime,
    required String description,
    String? vehicleLicensePlate,
    String? driverName,
    String? driverPhone,
    String? notes,
  }) async {
    try {
      final formData = FormData.fromMap({
        'ApartmentId': apartmentId,
        'Type': type,
        'ScheduledDate': scheduledDate.toIso8601String(),
        'StartTime': startTime.length == 5 ? '$startTime:00' : startTime,
        'EndTime': endTime.length == 5 ? '$endTime:00' : endTime,
        'Description': description.trim(),
        'VehicleLicensePlate': vehicleLicensePlate?.trim() ?? '',
        'DriverName': driverName?.trim() ?? '',
        'DriverPhone': driverPhone?.trim() ?? '',
        'Notes': notes?.trim() ?? '',
      });

      final response = await _dio.post('/MoveRequests', data: formData);
      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        return MoveRequestModel.fromJson(resData['data']);
      }
      return MoveRequestModel.fromJson(resData);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> cancelMoveRequest(int id) async {
    try {
      final response = await _dio.put('/MoveRequests/$id/cancel');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
