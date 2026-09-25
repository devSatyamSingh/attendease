import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/attendance_model.dart';


class AttendanceRepository {
  final ApiService _apiService;

  AttendanceRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<AttendanceModel> checkIn({
    required double latitude,
    required double longitude,
    required double accuracy,
    required String deviceId,
  }) async {
    final response = await _apiService.postApi(
      url: ApiUrls.attendanceCheckIn,
      body: {
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": accuracy,
        "device_id": deviceId,
      },
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return AttendanceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AttendanceModel> checkOut({
    required double latitude,
    required double longitude,
    required double accuracy,
    required String deviceId,
  }) async {
    final response = await _apiService.postApi(
      url: ApiUrls.attendanceCheckOut,
      body: {
        "latitude": latitude,
        "longitude": longitude,
        "accuracy": accuracy,
        "device_id": deviceId,
      },
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return AttendanceModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<AttendanceModel?> getTodayAttendance() async {
    final response = await _apiService.getApi(url: ApiUrls.attendanceToday);

    if (response is! Map<String, dynamic>) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    final data = response['data'];
    if (data == null) return null;

    final map = data as Map<String, dynamic>;
    if (map['attendance_id'] == null) return null;

    return AttendanceModel.fromJson(map);
  }

  Future<AttendanceHistoryResponseModel> getHistory({
    int page = 1,
    int limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final query = <String, dynamic>{"page": page, "limit": limit};
    if (from != null) query["from"] = DateFormat("yyyy-MM-dd").format(from);
    if (to != null) query["to"] = DateFormat("yyyy-MM-dd").format(to);

    final response = await _apiService.getApi(
      url: ApiUrls.attendanceHistory,
      queryParams: query,
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return AttendanceHistoryResponseModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}