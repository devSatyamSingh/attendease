import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/device_model.dart';
import '../model/device_status_model.dart';
import '../repo/device_repo.dart';

/// AttendEase — Device ViewModel (Riverpod).
/// `build()` fires `GET /devices/status` the moment this is first
/// watched, so the Profile screen's "Registered Device" card and the
/// Device Change Request screen both watch this SAME instance — no
/// duplicate network calls, one consistent state everywhere.
final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => DeviceRepository());

class DeviceViewModel extends AsyncNotifier<DeviceStatusModel> {
  @override
  FutureOr<DeviceStatusModel> build() {
    return ref.read(deviceRepositoryProvider).getDeviceStatus();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(deviceRepositoryProvider).getDeviceStatus(),
    );
  }

  /// Returns true on success and merges the new pending request into
  /// state immediately — no extra round trip needed to reflect it.
  Future<bool> requestChange(DeviceModel newDevice) async {
    final repo = ref.read(deviceRepositoryProvider);
    final previousActive = state.asData?.value.activeDevice;

    final result = await AsyncValue.guard(() async {
      final request = await repo.requestDeviceChange(newDevice);
      return DeviceStatusModel(activeDevice: previousActive, pendingRequest: request);
    });

    state = result;
    return !result.hasError;
  }
}

final deviceViewModelProvider =
AsyncNotifierProvider<DeviceViewModel, DeviceStatusModel>(DeviceViewModel.new);