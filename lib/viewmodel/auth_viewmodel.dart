import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/device_model.dart';
import '../model/login_response_model.dart';
import '../repo/auth_repo.dart';
import '../services/storage_service.dart';

/// AttendEase — Auth ViewModel (Riverpod).
///
/// Provider and ViewModel are the same thing here — `AuthViewModel` IS
/// the state container, `authViewModelProvider` is just how a widget
/// reaches it. A screen never does `AuthViewModel()` or touches
/// `AuthRepository` directly — it does:
///   ref.watch(authViewModelProvider)              // AsyncValue<LoginResponseModel?>
///   ref.read(authViewModelProvider.notifier).login(...)
///
/// `AsyncValue` gives loading/error/data for free — no separate
/// `isLoading` / `failure` fields to keep in sync by hand like a
/// ChangeNotifier version would need.
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());

/// Splash screen reads this exactly once — `StorageService().isLoggedIn()`
/// is true the moment login() succeeds, cleared on logout / forced logout.
final sessionCheckProvider = FutureProvider<bool>((ref) {
  return StorageService().isLoggedIn();
});

class AuthViewModel extends AsyncNotifier<LoginResponseModel?> {
  @override
  FutureOr<LoginResponseModel?> build() {
    // Nothing to load eagerly — state starts as "no login attempted yet".
    return null;
  }

  /// Returns true on success. On false, read
  /// `ref.watch(authViewModelProvider).error` for the message.
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

    state = result;
    return !result.hasError;
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

final authViewModelProvider =
AsyncNotifierProvider<AuthViewModel, LoginResponseModel?>(AuthViewModel.new);