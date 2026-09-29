import '../api/api_service.dart';
import '../api/api_urls.dart';
import '../core/errors/failure.dart';
import '../notification/notification_model.dart';

class NotificationRepository {
  final ApiService _api;

  NotificationRepository({ApiService? apiService})
      : _api = apiService ?? ApiService();

  /// GET /notifications?page=1&limit=20
  /// Backend total/pagination meta nahi bhejta, isliye hasMore ka
  /// faisla viewmodel me "list.length >= limit" se hota hai.
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _api.getApi(
      url: ApiUrls.notifications,
      queryParams: {"page": page, "limit": limit},
    );

    if (response is! Map<String, dynamic> || response['data'] is! List) {
      throw const ServerFailure(message: "Unexpected response from server.");
    }

    return (response['data'] as List)
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// GET /notifications/unread-count  ->  {"data": {"unread": 0}}
  Future<int> getUnreadCount() async {
    final response = await _api.getApi(url: ApiUrls.notificationUnreadCount);
    if (response is Map<String, dynamic> && response['data'] is Map) {
      final v = (response['data'] as Map)['unread'];
      return v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    }
    return 0;
  }

  /// PATCH /notifications/:id/read
  Future<void> markAsRead(int id) async {
    await _api.patchApi(url: ApiUrls.notificationRead(id));
  }

  /// PATCH /notifications/read-all
  Future<void> markAllAsRead() async {
    await _api.patchApi(url: ApiUrls.notificationReadAll);
  }

  /// POST /notifications/fcm-token   body: {"fcm_token": "..."}
  /// Errors throw hote hain (422 VALIDATION_ERROR, 403 DEVICE_NOT_AUTHORIZED).
  Future<void> registerFcmToken(String token) async {
    await _api.postApi(url: ApiUrls.fcmToken, body: {"fcm_token": token});
  }

  /// Login/token-refresh ke liye safe wrapper — fail hone par login block nahi hota.
  Future<void> syncFcmToken(String token) async {
    try {
      await registerFcmToken(token);
    } catch (_) {}
  }

  /// DELETE /notifications/fcm-token (logout). Logout se pehle call karo,
  /// jab tak JWT valid hai. Fail ho to bhi logout nahi rukna chahiye.
  Future<void> removeFcmToken(String token) async {
    try {
      await _api.deleteApi(url: ApiUrls.fcmToken, body: {"fcm_token": token});
    } catch (_) {}
  }
}