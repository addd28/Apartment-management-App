import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/apartment_model.dart';

class ApartmentService {
  final Dio _dio = ApiClient().dio;

  Future<List<ApartmentModel>> getMyApartments() async {
    try {
      final response = await _dio.get('/Apartments/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => ApartmentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<List<ApartmentMemberModel>> getMyMembers() async {
    try {
      final response = await _dio.get('/apartment-members/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => ApartmentMemberModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<List<ContractModel>> getMyContracts() async {
    try {
      final response = await _dio.get('/Contracts/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => ContractModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}
