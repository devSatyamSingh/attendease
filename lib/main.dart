import 'package:attendease/viewmodel/auth_viewmodel.dart';
import 'package:attendease/viewmodel/notification_viewmodel.dart';
import 'package:attendease/widget/connectivity_wrapper.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/navigator_key.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_name.dart';
import 'firebase_options.dart';
import 'notification/fcm_service.dart';
import 'notification/notification_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FcmService().onNotificationData = NotificationRouter.handle;
  await FcmService().initialize();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  static const _defaultOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  );

  @override
  void initState() {
    super.initState();

    // FCM token badal gaya -> logged in ho to backend ko naya token do.
    FcmService().onTokenRefresh.listen((newToken) async {
      debugPrint("FCM token refreshed: $newToken");
      final isLoggedIn = await ref.read(authRepositoryProvider).isLoggedIn();
      if (isLoggedIn) {
        await ref.read(notificationRepositoryProvider).syncFcmToken(newToken);
      }
    });

    // App khuli hai aur push aaya -> unread badge + list refresh.
    FcmService().onForegroundMessage.listen((_) {
      ref.invalidate(unreadCountProvider);
      ref.invalidate(notificationListViewModelProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendEase',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
        ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent.shade400),
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _defaultOverlayStyle,
          child: ConnectivityWrapper(child: child ?? const SizedBox.shrink()),
        );
      },
    );
  }
}