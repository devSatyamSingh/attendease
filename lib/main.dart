import 'dart:async';
import 'package:attendease/localization/language_model.dart';
import 'package:attendease/localization/language_service.dart';
import 'package:attendease/viewmodel/auth_viewmodel.dart';
import 'package:attendease/viewmodel/notification_viewmodel.dart';
import 'package:attendease/widget/connectivity_wrapper.dart';
import 'package:attendease/widget/security_gate.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/navigator_key.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_name.dart';
import 'firebase_options.dart';
import 'localization/lanaguge_provider.dart';
import 'notification/fcm_service.dart';
import 'notification/notification_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  late final LanguageModel savedLang;
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    LanguageService().load().then((lang) => savedLang = lang),
  ]);

  FcmService().onNotificationData = NotificationRouter.handle;

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi'), Locale('ur')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      startLocale: savedLang.locale,
      saveLocale: false, // language hum khud LanguageService se save karte hain
      child: ProviderScope(
        overrides: [
          languageProvider.overrideWith(() => _PreloadedLanguage(savedLang)),
        ],
        child: const MyApp(),
      ),
    ),
  );

  // FCM (permission + token) UI dikhne ke BAAD background me.
  // Pehle ye runApp se pehle await hota tha aur start slow karta tha.
  unawaited(FcmService().initialize());
}

/// App start pe saved language ko provider ki initial state bana deta hai.
class _PreloadedLanguage extends LanguageNotifier {
  final LanguageModel initial;
  _PreloadedLanguage(this.initial);

  @override
  LanguageModel build() => initial;
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
    final isUrdu = context.locale.languageCode == 'ur';
    return MaterialApp(
      title: 'AttendEase',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme:
        ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent.shade400),
        fontFamily: isUrdu ? 'NotoNastaliqUrdu' : null,
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _defaultOverlayStyle,
          child: ConnectivityWrapper(
            child: SecurityGate(
              child: child ?? const SizedBox.shrink(),
            ),
          ),
        );
      },
    );
  }
}