import 'package:dio/dio.dart';
import 'storage_service.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  late Dio dio;

  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: StorageService.getBaseUrl(),
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Dynamic baseUrl update if changed in storage
          options.baseUrl = StorageService.getBaseUrl();
          final token = StorageService.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Handle 401 or network errors gracefully
          if (error.response?.statusCode == 401) {
            // Token expired or invalid
            StorageService.clearAll();
          }
          return handler.next(error);
        },
      ),
    );
  }

  static String getErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.response != null && error.response?.data != null) {
        final data = error.response!.data;
        if (data is Map) {
          if (data['message'] != null) return data['message'].toString();
          if (data['title'] != null) return data['title'].toString();
          if (data['errors'] != null) {
            final errors = data['errors'];
            if (errors is Map) {
              return errors.values.map((e) => e is List ? e.join(', ') : e.toString()).join('\n');
            }
          }
        } else if (data is String && data.isNotEmpty) {
          return data;
        }
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại sau.';
        case DioExceptionType.badResponse:
          final code = error.response?.statusCode;
          if (code == 400) return 'Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.';
          if (code == 401) return 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.';
          if (code == 403) return 'Bạn không có quyền thực hiện hành động này.';
          if (code == 404) return 'Không tìm thấy dữ liệu yêu cầu.';
          if (code == 500) return 'Máy chủ gặp sự cố nội bộ. Vui lòng thử lại sau.';
          return 'Lỗi máy chủ: $code';
        case DioExceptionType.connectionError:
          return 'Không kết nối được tới Backend (${error.requestOptions.baseUrl}). Vui lòng kiểm tra xem Backend ASP.NET Core đang chạy chưa.';
        default:
          return error.message ?? 'Đã xảy ra lỗi không xác định.';
      }
    }
    return error.toString();
  }
}
