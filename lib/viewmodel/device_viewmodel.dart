import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/device_model.dart';
import '../model/device_status_model.dart';
import '../repo/device_repo.dart';

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