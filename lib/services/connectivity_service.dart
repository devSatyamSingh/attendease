import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';


final connectivityStatusProvider = StreamProvider<InternetStatus>((ref) {
  return InternetConnection().onStatusChange;
});

Future<bool> checkInternetNow() => InternetConnection().hasInternetAccess;