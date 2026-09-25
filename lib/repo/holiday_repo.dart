import 'package:intl/intl.dart';
import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/holiday_model.dart';

/// AttendEase — holiday repository.
///
/// NOTE: add this to your `ApiUrls` class if it isn't there yet:
///   static const String holidays = "/holidays";
class HolidayRepository {
  final ApiService _apiService;

  HolidayRepository({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<List<HolidayModel>> getHolidays({DateTime? from, DateTime? to}) async {
    final query = <String, dynamic>{};
    if (from != null) query["from"] = DateFormat("yyyy-MM-dd").format(from);
    if (to != null) query["to"] = DateFormat("yyyy-MM-dd").format(to);

    final response = await _apiService.getApi(
      url: ApiUrls.holidays,
      queryParams: query,
    );

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    return (response['data'] as List)
        .map((e) => HolidayModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}