import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/leave_model.dart';


class LeaveRepository {
  final ApiService _apiService;

  LeaveRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<LeaveTypeModel>> getLeaveTypes() async {
    final response = await _apiService.getApi(url: ApiUrls.leaveTypes);
    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return (response['data'] as List)
        .map((e) => LeaveTypeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaveBalanceModel>> getBalance({required int year}) async {
    final response = await _apiService.getApi(
      url: ApiUrls.leaveBalance,
      queryParams: {"year": year},
    );
    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return (response['data'] as List)
        .map((e) => LeaveBalanceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LeaveRequestModel> applyLeave({
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required String leaveDurationType,
    String? reason,
  }) async {
    final body = <String, dynamic>{
      "leave_type_id": leaveTypeId,
      "start_date": DateFormat("yyyy-MM-dd").format(startDate),
      "end_date": DateFormat("yyyy-MM-dd").format(endDate),
      "leave_duration_type": leaveDurationType,
    };
    if (reason != null && reason.trim().isNotEmpty) {
      body["reason"] = reason.trim();
    }

    final response = await _apiService.postApi(url: ApiUrls.leaveRequests, body: body);

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return LeaveRequestModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<LeaveHistoryResponseModel> getHistory({
    int page = 1,
    int limit = 20,
    String? status,
  }) async {
    final query = <String, dynamic>{"page": page, "limit": limit};
    if (status != null) query["status"] = status;

    final response = await _apiService.getApi(url: ApiUrls.leaveHistory, queryParams: query);

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return LeaveHistoryResponseModel.fromJson(response['data'] as Map<String, dynamic>);
  }

  Future<LeaveRequestModel> getLeaveRequest(int leaveRequestId) async {
    final response = await _apiService.getApi(url: "${ApiUrls.leaveRequests}/$leaveRequestId");
    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }
    return LeaveRequestModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}