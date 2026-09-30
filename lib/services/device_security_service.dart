import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

class DeviceSecurityResult {
  final bool isMockLocation;
  final bool isRooted;
  final bool isRealDevice;

  const DeviceSecurityResult({
    required this.isMockLocation,
    required this.isRooted,
    required this.isRealDevice,
  });

  bool get isSafe => !isMockLocation && !isRooted && isRealDevice;

  String get message {
    if (isMockLocation) {
      return "Fake/Mock location detected. Please turn off mock location apps and try again.";
    }
    if (isRooted) {
      return "Rooted/jailbroken device detected. Attendance is not allowed on this device.";
    }
    if (!isRealDevice) {
      return "Emulator detected. Please use a real device.";
    }
    return "";
  }

  String get code {
    if (isMockLocation) return "MOCK_LOCATION_DETECTED";
    if (isRooted) return "DEVICE_ROOTED";
    if (!isRealDevice) return "EMULATOR_DETECTED";
    return "";
  }
}

class DeviceSecurityService {
  static final DeviceSecurityService _instance = DeviceSecurityService._internal();
  factory DeviceSecurityService() => _instance;
  DeviceSecurityService._internal();
  Future<DeviceSecurityResult> check({bool withLocation = false}) async {
    try {
      // Sab checks parallel chalte hain
      final r = await Future.wait([
        SafeDevice.isMockLocation,
        SafeDevice.isJailBroken,
        SafeDevice.isRealDevice,
        withLocation ? _isMockedByFreshLocation() : Future.value(false),
      ]);

      return DeviceSecurityResult(
        isMockLocation: r[0] || r[3],
        isRooted: r[1],
        // Debug me emulator allow, taaki tum development kar sako
        isRealDevice: kDebugMode ? true : r[2],
      );
    } catch (e) {
      debugPrint("Device security check failed: $e");
      // Check khud fail ho gaya to block mat karo, backend validation to hai hi
      return const DeviceSecurityResult(
        isMockLocation: false,
        isRooted: false,
        isRealDevice: true,
      );
    }
  }

  Future<bool> _isMockedByFreshLocation({
    Duration wait = const Duration(seconds: 3),
  }) async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return false;
      }
      if (!await Geolocator.isLocationServiceEnabled()) return false;

      final completer = Completer<bool>();
      late StreamSubscription<Position> sub;

      final timer = Timer(wait, () {
        if (!completer.isCompleted) completer.complete(false);
      });

      sub = Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      ).listen(
            (p) {
          // Pehli fresh reading hi kaafi hai (mock ho ya na ho)
          if (!completer.isCompleted) completer.complete(p.isMocked);
        },
        onError: (_) {
          if (!completer.isCompleted) completer.complete(false);
        },
      );

      try {
        return await completer.future;
      } finally {
        timer.cancel();
        await sub.cancel();
      }
    } catch (_) {
      return false;
    }
  }
}