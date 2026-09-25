import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/errors/failure.dart';
import '../model/leave_model.dart';
import '../repo/leave_repo.dart';

final leaveRepositoryProvider = Provider<LeaveRepository>((ref) => LeaveRepository());

// ==================== LEAVE TYPES ====================

final leaveTypesProvider = FutureProvider<List<LeaveTypeModel>>((ref) {
  return ref.read(leaveRepositoryProvider).getLeaveTypes();
});

// ==================== BALANCE (per year) ====================

class LeaveBalanceViewModel extends AsyncNotifier<List<LeaveBalanceModel>> {
  int _year = DateTime.now().year;
  int get year => _year;

  @override
  FutureOr<List<LeaveBalanceModel>> build() {
    return ref.read(leaveRepositoryProvider).getBalance(year: _year);
  }

  Future<void> loadYear(int year) async {
    _year = year;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getBalance(year: _year));
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => ref.read(leaveRepositoryProvider).getBalance(year: _year));
  }
}

final leaveBalanceViewModelProvider =
AsyncNotifierProvider<LeaveBalanceViewModel, List<LeaveBalanceModel>>(LeaveBalanceViewModel.new);

// ==================== RECENT REQUESTS (Leaves screen preview) ====================

final recentLeaveRequestsProvider = FutureProvider<List<LeaveRequestModel>>((ref) async {
  final response = await ref.read(leaveRepositoryProvider).getHistory(page: 1, limit: 4);
  return response.items;
});

/// One lightweight call per status just to read `pagination.total` — used
/// for the filter-chip counts on the History screen (no dummy numbers).
final leaveStatusCountsProvider = FutureProvider<Map<String, int>>((ref) async {
  final repo = ref.read(leaveRepositoryProvider);
  final results = await Future.wait([
    repo.getHistory(page: 1, limit: 1),
    repo.getHistory(page: 1, limit: 1, status: "PENDING"),
    repo.getHistory(page: 1, limit: 1, status: "APPROVED"),
  ]);
  return {
    "ALL": results[0].pagination.total,
    "PENDING": results[1].pagination.total,
    "APPROVED": results[2].pagination.total,
  };
});

// ==================== PAGINATED + FILTERED HISTORY ====================

class LeaveHistoryState {
  final List<LeaveRequestModel> items;
  final int page;
  final int totalPages;
  final bool isLoading;
  final bool isLoadingMore;
  final Failure? failure;
  final String? statusFilter; // null = All

  const LeaveHistoryState({
    this.items = const [],
    this.page = 0,
    this.totalPages = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.failure,
    this.statusFilter,
  });

  bool get hasMore => page < totalPages;
  bool get isEmpty => items.isEmpty && !isLoading;

  LeaveHistoryState copyWith({
    List<LeaveRequestModel>? items,
    int? page,
    int? totalPages,
    bool? isLoading,
    bool? isLoadingMore,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return LeaveHistoryState(
      items: items ?? this.items,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      failure: clearFailure ? null : (failure ?? this.failure),
      statusFilter: statusFilter,
    );
  }
}

class LeaveHistoryViewModel extends Notifier<LeaveHistoryState> {
  static const _pageSize = 20;

  @override
  LeaveHistoryState build() {
    Future.microtask(loadFirstPage);
    return const LeaveHistoryState(isLoading: true);
  }

  Future<void> loadFirstPage({String? status}) async {
    state = LeaveHistoryState(isLoading: true, statusFilter: status);
    try {
      final response =
      await ref.read(leaveRepositoryProvider).getHistory(page: 1, limit: _pageSize, status: status);
      state = LeaveHistoryState(
        items: response.items,
        page: response.pagination.page,
        totalPages: response.pagination.totalPages,
        statusFilter: status,
      );
    } on Failure catch (f) {
      state = LeaveHistoryState(statusFilter: status, failure: f);
    } catch (e) {
      state = LeaveHistoryState(statusFilter: status, failure: UnknownFailure(message: e.toString()));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true, clearFailure: true);
    try {
      final nextPage = state.page + 1;
      final response = await ref.read(leaveRepositoryProvider).getHistory(
        page: nextPage,
        limit: _pageSize,
        status: state.statusFilter,
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

  Future<void> setStatusFilter(String? status) => loadFirstPage(status: status);

  Future<void> refresh() => loadFirstPage(status: state.statusFilter);
}

final leaveHistoryViewModelProvider =
NotifierProvider<LeaveHistoryViewModel, LeaveHistoryState>(LeaveHistoryViewModel.new);

// ==================== APPLY LEAVE (submit action) ====================

class ApplyLeaveViewModel extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  /// Returns true on success. On false, read
  /// `ref.watch(applyLeaveViewModelProvider).error` for the message.
  Future<bool> submit({
    required int leaveTypeId,
    required DateTime startDate,
    required DateTime endDate,
    required String leaveDurationType,
    String? reason,
  }) async {
    state = const AsyncValue.loading();

    final result = await AsyncValue.guard(() {
      return ref.read(leaveRepositoryProvider).applyLeave(
        leaveTypeId: leaveTypeId,
        startDate: startDate,
        endDate: endDate,
        leaveDurationType: leaveDurationType,
        reason: reason,
      );
    });

    state = result.hasError
        ? AsyncValue.error(result.error!, result.stackTrace ?? StackTrace.current)
        : const AsyncValue.data(null);

    if (!result.hasError) {
      // Balance aur history dono jagah turant reflect ho, jaise
      // attendance check-in/check-out ke baad karte hain.
      ref.invalidate(recentLeaveRequestsProvider);
      ref.invalidate(leaveStatusCountsProvider);
      ref.read(leaveHistoryViewModelProvider.notifier).refresh();
      ref.read(leaveBalanceViewModelProvider.notifier).refresh();
    }

    return !result.hasError;
  }
}

final applyLeaveViewModelProvider = AsyncNotifierProvider<ApplyLeaveViewModel, void>(ApplyLeaveViewModel.new);