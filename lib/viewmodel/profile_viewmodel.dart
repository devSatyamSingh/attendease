import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/profile_model.dart';
import '../repo/profile_repo.dart';

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(),
);

class ProfileViewModel extends AsyncNotifier<ProfileModel> {
  @override
  FutureOr<ProfileModel> build() {
    return ref.read(profileRepositoryProvider).getMyProfile();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(profileRepositoryProvider).getMyProfile(),
    );
  }
}

final profileViewModelProvider =
    AsyncNotifierProvider<ProfileViewModel, ProfileModel>(ProfileViewModel.new);
