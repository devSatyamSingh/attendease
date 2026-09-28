import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../model/device_model.dart';
import '../model/login_response_model.dart';
import '../repo/auth_repo.dart';
import '../services/storage_service.dart';
import 'attendance_viewmodel.dart';
import 'device_viewmodel.dart';
import 'profile_viewmodel.dart';
import 'leave_viewmodel.dart';
import 'holiday_viewmodel.dart'; // profileRepositoryProvider yahin se aata hai

final authRepositoryProvider = Provider<AuthRepository>(
      (ref) => AuthRepository(),
);

final sessionCheckProvider = FutureProvider<bool>((ref) async {
  final storage = StorageService();
  final hasLocalSession = await storage.isLoggedIn();
  if (!hasLocalSession) return false;

  try {
    await ref.read(profileRepositoryProvider).getMyProfile();
    return true;
  } on Failure {
    return false;
  } catch (_) {
    return false;
  }
});

class AuthViewModel extends AsyncNotifier<LoginResponseModel?> {
  @override
  FutureOr<LoginResponseModel?> build() {
    return null;
  }

  /// Purane user ka saara cached data hatao.
  /// Naye login ke baad screens pehli baar fresh API call karengi.
  void _resetUserData() {
    // Profile / device / session
    ref.invalidate(profileViewModelProvider);
    ref.invalidate(deviceViewModelProvider);
    ref.invalidate(sessionCheckProvider);

    // Attendance
    ref.invalidate(attendanceViewModelProvider);
    ref.invalidate(recentAttendanceProvider);
    ref.invalidate(attendanceHistoryViewModelProvider);

    // Leave
    ref.invalidate(leaveTypesProvider);
    ref.invalidate(leaveBalanceViewModelProvider);
    ref.invalidate(recentLeaveRequestsProvider);
    ref.invalidate(leaveStatusCountsProvider);
    ref.invalidate(leaveHistoryViewModelProvider);
    ref.invalidate(applyLeaveViewModelProvider);

    // Holidays
    ref.invalidate(holidayViewModelProvider);
  }

  Future<bool> login({
    required String loginId,
    required String password,
    required DeviceModel device,
  }) async {
    state = const AsyncValue.loading();
    final repo = ref.read(authRepositoryProvider);

    final result = await AsyncValue.guard(
          () => repo.login(login: loginId, password: password, device: device),
    );

    if (!result.hasError) {
      _resetUserData(); // naye user ke liye fresh start
    }

    state = result;
    return !result.hasError;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authViewModelProvider =
AsyncNotifierProvider<AuthViewModel, LoginResponseModel?>(
  AuthViewModel.new,
);