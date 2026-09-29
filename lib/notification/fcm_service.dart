import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'local_notification.dart';

/// Top-level function hona zaroori hai (class ke andar nahi) — background
/// isolate isko call karta hai jab app terminated/background me hoti hai.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background FCM: ${message.data}");
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Notification data (type + id) ke saath navigate karne ke liye —
  /// main.dart isko set karega.
  void Function(Map<String, dynamic> data)? onNotificationData;

  /// App foreground me hai aur push aaya — UI (badge/list) refresh karne ke liye.
  final StreamController<RemoteMessage> _foregroundController =
  StreamController<RemoteMessage>.broadcast();
  Stream<RemoteMessage> get onForegroundMessage =>
      _foregroundController.stream;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return; // dobara call hone par listeners duplicate na hon
    _initialized = true;

    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    await LocalNotificationService().init();
    LocalNotificationService().onNotificationTap = (payload) {
      if (payload == null || payload.isEmpty) return;
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        onNotificationData?.call(data);
      } catch (e) {
        debugPrint("Invalid notification payload: $e");
      }
    };

    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // App foreground me hai — FCM khud popup nahi dikhata, isliye local
    // notification se manually dikhate hain.
    FirebaseMessaging.onMessage.listen((message) {
      _foregroundController.add(message);
      LocalNotificationService().show(
        title: message.notification?.title ?? "AttendEase",
        body: message.notification?.body ?? "",
        payload: jsonEncode(message.data),
      );
    });

    // App background me thi, user ne notification tap kiya.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      onNotificationData?.call(message.data);
    });

    // App terminated thi, tap karke khola gaya.
    // Navigator abhi ready nahi hota — NotificationRouter data ko pending
    // rakhta hai, Dashboard me flushPending() se navigate hota hai.
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      onNotificationData?.call(initialMessage.data);
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;

  Future<void> deleteToken() => _messaging.deleteToken();
}