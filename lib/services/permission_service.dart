import 'package:geolocator/geolocator.dart';
import '../core/errors/failure.dart';

class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  Future<bool> ensureLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionFailure(
        message:
        "Location permission is permanently denied. Please enable it from Settings.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionFailure(
        message: "Location permission is required to mark attendance.",
        code: "GPS_PERMISSION_REQUIRED",
      );
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  Future<void> openAppSettings() => Geolocator.openAppSettings();

  Future<bool> isGpsEnabled() => Geolocator.isLocationServiceEnabled();

  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}