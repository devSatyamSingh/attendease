import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_name.dart';

void main() {
  // ProviderScope MUST wrap the whole app — every ref.watch/ref.read
  // (AuthViewModel, DeviceViewModel, ProfileViewModel, sessionCheckProvider…)
  // needs this in the widget tree above it, or you get exactly the
  // "Bad state: No ProviderScope found" crash you just saw.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AttendEase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: RouteNames.splash,
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}