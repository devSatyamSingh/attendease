import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();

  factory LocalNotificationService() => _instance;

  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'attendease_default_channel',
    'AttendEase Notifications',
    description: 'Holiday and leave update notifications',
    importance: Importance.max,
  );

  void Function(String? payload)? onNotificationTap;

  Future<void> init() async {
    const androidInit = AndroidInitializationSettings(
      '@drawable/ic_stat_attendease',
    );

    const initSettings = InitializationSettings(android: androidInit);

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        onNotificationTap?.call(response.payload);
      },
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);
  }

  Future<void> show({
    required String title,
    required String body,
    String? payload,
  }) async {
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'attendease_default_channel',
        'AttendEase Notifications',
        channelDescription: 'Holiday and leave update notifications',
        importance: Importance.max,
        priority: Priority.high,
        icon: '@drawable/ic_stat_attendease',
      ),
    );

    await _plugin.show(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
