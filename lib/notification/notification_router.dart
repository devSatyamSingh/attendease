import 'package:flutter/material.dart';
import '../core/constants/navigator_key.dart';
import '../core/routes/route_name.dart';
import 'notification_model.dart';

class NotificationRouter {
  NotificationRouter._();

  /// Terminated state se tap hone par navigator abhi ready nahi hota —
  /// data yahan rakh lete hain, Dashboard ready hone par flushPending() chalao.
  static Map<String, dynamic>? _pending;

  /// FCM data:  {"type": "LEAVE_APPROVED", "leave_request_id": "501"}
  /// (FCM data ki saari values String hoti hain.)
  static void handle(Map<String, dynamic> data) {
    final type = data["type"]?.toString();
    if (type == null) return;

    final nav = navigatorKey.currentState;
    if (nav == null) {
      _pending = data;
      return;
    }

    switch (type) {
      case NotificationType.holiday:
        nav.pushNamed(RouteNames.holidays);
        break;
      case NotificationType.leaveApproved:
      case NotificationType.leaveRejected:
        nav.pushNamed(RouteNames.leaveHistory);
        break;
      default:
        break;
    }
  }

  /// Dashboard initState me (postFrameCallback ke andar) call karo.
  static void flushPending() {
    final p = _pending;
    if (p == null) return;
    _pending = null;
    handle(p);
  }
}