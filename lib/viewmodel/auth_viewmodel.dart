import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../model/device_model.dart';
import '../model/login_response_model.dart';
import '../repo/auth_repo.dart';
import '../repo/profile_repo.dart';
import '../services/storage_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository());


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