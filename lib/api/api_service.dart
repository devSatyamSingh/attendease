import 'package:dio/dio.dart';
import '../core/network/api_exceptions.dart';
import 'api_client.dart';

class ApiService {
  final Dio _dio = ApiClient().dio;

  Future<dynamic> getApi({
    required String url,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final response = await _dio.get(url, queryParameters: queryParams);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<dynamic> postApi({
    required String url,
    dynamic body,
  }) async {
    try {
      final response = await _dio.post(url, data: body);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<dynamic> putApi({
    required String url,
    dynamic body,
  }) async {
    try {
      final response = await _dio.put(url, data: body);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<dynamic> patchApi({
    required String url,
    dynamic body,
  }) async {
    try {
      final response = await _dio.patch(url, data: body);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<dynamic> deleteApi({
    required String url,
    dynamic body,
  }) async {
    try {
      final response = await _dio.delete(url, data: body);
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }

  Future<dynamic> uploadApi({
    required String url,
    required FormData formData,
    void Function(int sent, int total)? onSendProgress,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response.data;
    } on DioException catch (e) {
      throw handleDioError(e);
    }
  }
}