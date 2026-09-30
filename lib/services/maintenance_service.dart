import 'dart:io';
import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/maintenance_model.dart';

class MaintenanceService {
  final Dio _dio = ApiClient().dio;

  Future<List<MaintenanceRequestModel>> getMyRequests({String? status, String? priority}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status;
      }
      if (priority != null && priority.isNotEmpty && priority.toLowerCase() != 'all') {
        queryParams['priority'] = priority;
      }

      final response = await _dio.get(
        '/MaintenanceRequests/my',
        queryParameters: queryParams,
      );

      final data = response.data;
      if (data is List) {
        return data.map((json) => MaintenanceRequestModel.fromJson(json)).toList();
      } else if (data is Map && data['items'] is List) {
        return (data['items'] as List).map((json) => MaintenanceRequestModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<MaintenanceRequestModel> getById(int id) async {
    try {
      final response = await _dio.get('/MaintenanceRequests/$id');
      final data = response.data;
      if (data is Map && data['data'] != null) {
        return MaintenanceRequestModel.fromJson(data['data']);
      }
      return MaintenanceRequestModel.fromJson(data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<MaintenanceRequestModel> createRequest({
    required int apartmentId,
    required String title,
    required String description,
    required String priority,
    List<File> imageFiles = const [],
  }) async {
    try {
      final formData = FormData.fromMap({
        'ApartmentId': apartmentId,
        'Title': title.trim(),
        'Description': description.trim(),
        'Priority': priority.toUpperCase(),
      });

      if (imageFiles.isNotEmpty) {
        for (var file in imageFiles) {
          final fileName = file.path.split(Platform.pathSeparator).last;
          formData.files.add(
            MapEntry(
              'Attachments',
              await MultipartFile.fromFile(file.path, filename: fileName),
            ),
          );
        }
      }

      final response = await _dio.post(
        '/MaintenanceRequests',
        data: formData,
      );

      final resData = response.data;
      if (resData is Map && resData['data'] != null) {
        return MaintenanceRequestModel.fromJson(resData['data']);
      }
      return MaintenanceRequestModel.fromJson(resData);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> updateRequest({
    required int id,
    required String title,
    required String description,
    required String priority,
  }) async {
    try {
      final formData = FormData.fromMap({
        'Title': title.trim(),
        'Description': description.trim(),
        'Priority': priority.toUpperCase(),
      });

      final response = await _dio.put(
        '/MaintenanceRequests/$id',
        data: formData,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> cancelRequest(int id) async {
    try {
      final response = await _dio.put('/MaintenanceRequests/$id/cancel');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> uploadAttachments(int id, List<File> files) async {
    try {
      final formData = FormData();
      for (var file in files) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        formData.files.add(
          MapEntry(
            'files',
            await MultipartFile.fromFile(file.path, filename: fileName),
          ),
        );
      }

      final response = await _dio.post(
        '/MaintenanceRequests/$id/attachments',
        data: formData,
      );
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> deleteAttachment(int id, int attachmentId) async {
    try {
      final response = await _dio.delete('/MaintenanceRequests/$id/attachments/$attachmentId');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
