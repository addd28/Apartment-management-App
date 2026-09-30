import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/vehicle_model.dart';

class VehicleService {
  final Dio _dio = ApiClient().dio;

  Future<List<VehicleModel>> getMyVehicles() async {
    try {
      final response = await _dio.get('/Vehicles/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => VehicleModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<VehicleModel> registerVehicle({
    required int apartmentId,
    required String type,
    String? licensePlate,
    String? brand,
    String? color,
    String? notes,
  }) async {
    try {
      final response = await _dio.post(
        '/Vehicles',
        data: {
          'apartmentId': apartmentId,
          'type': type,
          'licensePlate': licensePlate?.trim(),
          'brand': brand?.trim(),
          'color': color?.trim(),
          'notes': notes?.trim(),
        },
      );
      return VehicleModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<bool> deleteVehicle(int id) async {
    try {
      final response = await _dio.delete('/Vehicles/$id');
      return response.statusCode == 200;
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
