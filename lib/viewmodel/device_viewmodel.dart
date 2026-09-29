import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/device_model.dart';
import '../model/device_status_model.dart';
import '../repo/device_repo.dart';

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) => DeviceRepository());

class DeviceViewModel extends AsyncNotifier<DeviceStatusModel> {
  @override
  FutureOr<DeviceStatusModel> build() {
    return _fetchWithRetry();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchWithRetry());
  }

  /// Login ke turant baad backend me device activate hone me thoda time
  /// lag sakta hai. activeDevice null aaye to kuch retries kar lo, taaki
  /// user ko manually "Retry" na dabana pade.
  Future<DeviceStatusModel> _fetchWithRetry() async {
    final repo = ref.read(deviceRepositoryProvider);
    const delays = [Duration(milliseconds: 800), Duration(seconds: 1), Duration(seconds: 2)];

    DeviceStatusModel result = await repo.getDeviceStatus();
    if (result.activeDevice != null) return result;

    for (final delay in delays) {
      await Future.delayed(delay);
      result = await repo.getDeviceStatus();
      if (result.activeDevice != null) return result;
    }

    return result;
  }

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