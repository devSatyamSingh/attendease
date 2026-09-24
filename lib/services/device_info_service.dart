import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/constants/app_constants.dart';
import '../model/device_model.dart';
import 'storage_service.dart';

/// AttendEase — builds the `device` payload sent on login and on a
/// device-change request.
///
/// The device_id is generated ONCE (from the OS's own vendor/android
/// id) and then persisted via StorageService — every subsequent call
/// reuses the same cached id, which is exactly what lets the backend
/// tell "same phone, new login" apart from "different phone".
class DeviceInfoService {
  static final DeviceInfoService _instance = DeviceInfoService._internal();
  factory DeviceInfoService() => _instance;
  DeviceInfoService._internal();

  final DeviceInfoPlugin _plugin = DeviceInfoPlugin();

  Future<DeviceModel> buildDeviceModel() async {
    final cachedId = await StorageService().getDeviceId();

    if (Platform.isAndroid) {
      final info = await _plugin.androidInfo;
      final deviceId = cachedId ?? info.id;
      if (cachedId == null) await StorageService().saveDeviceId(deviceId);
      return DeviceModel(
        deviceId: deviceId,
        model: "${info.manufacturer} ${info.model}".trim(),
        platform: "ANDROID",
        osVersion: "Android ${info.version.release}",
        appVersion: AppConstants.appVersion,
      );
    }

    if (Platform.isIOS) {
      final info = await _plugin.iosInfo;
      final deviceId = cachedId ??
          info.identifierForVendor ??
          "IOS-${DateTime.now().millisecondsSinceEpoch}";
      if (cachedId == null) await StorageService().saveDeviceId(deviceId);
      return DeviceModel(
        deviceId: deviceId,
        model: info.utsname.machine,
        platform: "IOS",
        osVersion: "iOS ${info.systemVersion}",
        appVersion: AppConstants.appVersion,
      );
    }

    // Fallback for dev on web/desktop — shouldn't hit in production.
    final fallbackId = cachedId ?? "UNKNOWN-${DateTime.now().millisecondsSinceEpoch}";
    if (cachedId == null) await StorageService().saveDeviceId(fallbackId);
    return DeviceModel(
      deviceId: fallbackId,
      model: "Unknown Device",
      platform: "UNKNOWN",
      osVersion: "Unknown",
      appVersion: AppConstants.appVersion,
    );
  }
}