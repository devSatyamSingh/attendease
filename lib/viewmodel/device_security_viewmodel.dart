import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/device_security_service.dart';

class DeviceSecurityNotifier extends AsyncNotifier<DeviceSecurityResult> {
  @override
  FutureOr<DeviceSecurityResult> build() =>
      DeviceSecurityService().check(withLocation: true);

  Future<void> recheck() async {
    final result = await DeviceSecurityService().check(withLocation: true);
    state = AsyncData(result);
  }
}

final deviceSecurityProvider =
    AsyncNotifierProvider<DeviceSecurityNotifier, DeviceSecurityResult>(
      DeviceSecurityNotifier.new,
    );
