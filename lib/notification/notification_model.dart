import 'dart:convert';

/// Backend jo "type" field bhejta hai, usse match karta hai.
class NotificationType {
  NotificationType._();
  static const holiday = "HOLIDAY";
  static const leaveApproved = "LEAVE_APPROVED";
  static const leaveRejected = "LEAVE_REJECTED";
}

class NotificationModel {
  final int id;
  final String type;
  final String title;
  final String body;

  /// Type ke hisab se extra data:
  /// LEAVE_*  -> {leave_request_id}
  /// HOLIDAY  -> {holiday_id, holiday_date}
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.data,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _toInt(json['notification_id']) ?? 0,
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      body: json['body']?.toString() ?? '',
      data: _toMap(json['data']),
      isRead: _toBool(json['is_read']), // backend 0/1 bhejta hai
      readAt: _toDate(json['read_at']),
      createdAt: _toDate(json['created_at']) ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      data: data,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  int? get leaveRequestId => _toInt(data['leave_request_id']);
  int? get holidayId => _toInt(data['holiday_id']);

  // ---------- helpers ----------
  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '');
  }

  static bool _toBool(dynamic v) {
    if (v is bool) return v;
    if (v is num) return v != 0;
    final s = v?.toString().toLowerCase();
    return s == '1' || s == 'true';
  }

  static DateTime? _toDate(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString())?.toLocal(); // UTC -> local
  }

  static Map<String, dynamic> _toMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is String && v.isNotEmpty) {
      try {
        final decoded = jsonDecode(v);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return const {};
  }
}