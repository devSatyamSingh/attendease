import 'user_model.dart';

/// AttendEase — parses `data` from `POST /auth/login`:
/// { "access_token", "refresh_token", "user": {...}, "device_status" }
class LoginResponseModel {
  final String accessToken;
  final String refreshToken;
  final UserModel user;
  final String deviceStatus; // "ACTIVE" / "PENDING" (device change awaited)

  const LoginResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.deviceStatus,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    return LoginResponseModel(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      deviceStatus: json['device_status'] as String,
    );
  }
}