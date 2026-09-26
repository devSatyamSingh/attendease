import 'package:attendease/widget/connectivity_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/navigator_key.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_name.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendEase',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurpleAccent.shade400),
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
      builder: (context, child) {
        return ConnectivityWrapper(child: child ?? const SizedBox.shrink());
      },
    );
  }}
