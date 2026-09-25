import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../model/attendance_model.dart';
import '../repo/attendance_repo.dart';
import '../services/device_info_service.dart';
import '../services/location_service.dart';


final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) => AttendanceRepository());

// ==================== TODAY + CHECK-IN / CHECK-OUT ====================

class AttendanceViewModel extends AsyncNotifier<AttendanceModel?> {
  @override
  FutureOr<AttendanceModel?> build() {
    return ref.read(attendanceRepositoryProvider).getTodayAttendance();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
          () => ref.read(attendanceRepositoryProvider).getTodayAttendance(),
    );
  }

  Future<bool> checkIn() async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final position = await LocationService().getCurrentLocation();
      final device = await DeviceInfoService().buildDeviceModel();

      return ref.read(attendanceRepositoryProvider).checkIn(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        deviceId: device.deviceId,
      );
    });

    state = result;

    if (!result.hasError) {
      // Aaj ka naya check-in Recent Activity aur History (Daily
      // Records) list mein bhi turant reflect hona chahiye — inhe bhi
      // refresh kar do, warna wo purana cached data dikhate rehte hain.
      ref.invalidate(recentAttendanceProvider);
      ref.read(attendanceHistoryViewModelProvider.notifier).refresh();
    }

    return !result.hasError;
  }

  Future<bool> checkOut() async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() async {
      final position = await LocationService().getCurrentLocation();
      final device = await DeviceInfoService().buildDeviceModel();

      return ref.read(attendanceRepositoryProvider).checkOut(
        latitude: position.latitude,
        longitude: position.longitude,
        accuracy: position.accuracy,
        deviceId: device.deviceId,
      );
    });

    state = result;

    if (!result.hasError) {
      ref.invalidate(recentAttendanceProvider);
      ref.read(attendanceHistoryViewModelProvider.notifier).refresh();
    }

    return !result.hasError;
  }
}

final attendanceViewModelProvider =
AsyncNotifierProvider<AttendanceViewModel, AttendanceModel?>(AttendanceViewModel.new);

// ==================== PAGINATED HISTORY ====================

class AttendanceHistoryState {
  final List<AttendanceModel> items;
  final int page;
  final int totalPages;
  final bool isLoading; // first page / pull-to-refresh
  final bool isLoadingMore; // next page, appended to the bottom
  final Failure? failure;

  const AttendanceHistoryState({
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
  });

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty && !isLoading;

  AttendanceHistoryState copyWith({
    List<AttendanceModel>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return AttendanceHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }
}

class AttendanceHistoryViewModel extends Notifier<AttendanceHistoryState> {
  static const _pageSize = 31; // covers a full calendar month in one page


  DateTime? _lastFrom;
  DateTime? _lastTo;

  @override
  AttendanceHistoryState build() {
    Future.microtask(loadFirstPage);
    return const AttendanceHistoryState(isLoading: true);
  }

  Future<void> loadFirstPage({DateTime? from, DateTime? to}) async {
    _lastFrom = from;
    _lastTo = to;

    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      final response = await ref
          .read(attendanceRepositoryProvider)
          .getHistory(page: 1, limit: _pageSize, from: from, to: to);
      state = AttendanceHistoryState(
        items: response.items,
        page: response.pagination.page,
        totalPages: response.pagination.totalPages,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoading: false, failure: f);
    } catch (e) {
      state = state.copyWith(isLoading: false, failure: UnknownFailure(message: e.toString()));
    }
  }


  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    try {
      final nextPage = state.page + 1;
      final response = await ref.read(attendanceRepositoryProvider).getHistory(
        page: nextPage,
        limit: _pageSize,
        from: _lastFrom,
        to: _lastTo,
      );
      state = state.copyWith(
        items: [...state.items, ...response.items],
        page: response.pagination.page,
        totalPages: response.pagination.totalPages,
        isLoadingMore: false,
      );
    } on Failure catch (f) {
      state = state.copyWith(isLoadingMore: false, failure: f);
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, failure: UnknownFailure(message: e.toString()));
    }
  }

  Future<void> refresh() => loadFirstPage(from: _lastFrom, to: _lastTo);
}

// ==================== RECENT ACTIVITY (dashboard) ====================

final recentAttendanceProvider = FutureProvider<List<AttendanceModel>>((ref) async {
  final response = await ref
      .read(attendanceRepositoryProvider)
      .getHistory(page: 1, limit: 4);
  return response.items;
});

final attendanceHistoryViewModelProvider = NotifierProvider<AttendanceHistoryViewModel, AttendanceHistoryState>(
  AttendanceHistoryViewModel.new,
);