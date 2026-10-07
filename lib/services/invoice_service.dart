import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/invoice_model.dart';

class InvoiceService {
  final Dio _dio = ApiClient().dio;

  Future<List<InvoiceModel>> getMyInvoices({String? status}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (status != null && status.isNotEmpty && status.toLowerCase() != 'all') {
        queryParams['status'] = status;
      }

      final response = await _dio.get('/Invoices/my', queryParameters: queryParams);
      final data = response.data;
      if (data is List) {
        return data.map((json) => InvoiceModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<InvoiceModel> getInvoiceById(int id) async {
    try {
      final response = await _dio.get('/Invoices/$id');
      return InvoiceModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<PaymentModel> createPayment({
    required int invoiceId,
    required double amount,
    required String paymentMethod,
    String? transactionRef,
    String? notes,
  }) async {
    try {
      final refCode = transactionRef ?? notes ?? 'ONLINE_${DateTime.now().millisecondsSinceEpoch}';
      final response = await _dio.post(
        '/Payments',
        data: {
          'invoiceId': invoiceId,
          'amount': amount,
          'paymentMethod': paymentMethod,
          'referenceCode': refCode,
        },
      );
      return PaymentModel.fromJson(response.data);
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<String> createVnpayPayment(int invoiceId) async {
    try {
      final response = await _dio.post(
        '/Payments/vnpay/create',
        data: {'invoiceId': invoiceId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return (data['paymentUrl'] ?? data['data']?['paymentUrl'] ?? '').toString();
      }
      return '';
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }

  Future<List<PaymentModel>> getMyPayments() async {
    try {
      final response = await _dio.get('/Payments/my');
      final data = response.data;
      if (data is List) {
        return data.map((json) => PaymentModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(ApiClient.getErrorMessage(e));
    }
  }
}

