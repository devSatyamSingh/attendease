import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../model/profile_model.dart';

/// AttendEase — profile repository.
class ProfileRepository {
  final ApiService _apiService;

  ProfileRepository({ApiService? apiService})
      : _apiService = apiService ?? ApiService();

  Future<ProfileModel> getMyProfile() async {
    final response = await _apiService.getApi(url: ApiUrls.profile);

    if (response is! Map<String, dynamic> || response['data'] == null) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    return ProfileModel.fromJson(response['data'] as Map<String, dynamic>);
  }
}