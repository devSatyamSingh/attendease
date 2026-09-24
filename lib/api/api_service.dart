import 'package:dio/dio.dart';
import '../core/network/api_exceptions.dart';
import 'api_client.dart';

/// AttendEase — generic, reusable API service.
///
/// Every repository calls one of these methods instead of touching Dio
/// directly. This is the ONLY file (besides api_client.dart and
/// api_exceptions.dart) that should ever import `dio`.
///
/// Every method returns the decoded JSON body (`response.data`) as
/// `dynamic` and throws a `Failure` — never a raw `DioException` — so a
/// repository can go straight from calling this to
/// `MyModel.fromJson(response['data'])` inside its own try/catch.
///
/// Usage in a repository:
/// ```dart
/// final response = await _apiService.postApi(
///   url: ApiUrls.checkIn,
///   body: {"latitude": lat, "longitude": lng, "accuracy": acc},
/// );
/// return AttendanceTodayModel.fromJson(response['data']);
/// // Failure thrown by ApiService already bubbles up automatically —
/// // no try/catch needed here unless you want to add extra context.
/// ```
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

  /// For partial updates — e.g. cancelling a leave request, updating a
  /// single profile field.
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

  /// Multipart upload — e.g. a profile photo. Kept separate from
  /// [postApi] so a plain JSON POST never pays multipart overhead by
  /// accident.
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