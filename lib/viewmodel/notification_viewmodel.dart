import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../notification/notification_model.dart';
import '../repo/notification_repo.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>(
      (ref) => NotificationRepository(),
);

/// Bell icon ka badge.
final unreadCountProvider = FutureProvider<int>((ref) {
  return ref.read(notificationRepositoryProvider).getUnreadCount();
});

class NotificationListState {
  final List<NotificationModel> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;

  const NotificationListState({
    this.items = const [],
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  NotificationListState copyWith({
    List<NotificationModel>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return NotificationListState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class NotificationListViewModel extends AsyncNotifier<NotificationListState> {
  static const _limit = 20;

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);

  @override
  Future<NotificationListState> build() => _fetchFirstPage();

  Future<NotificationListState> _fetchFirstPage() async {
    final items = await _repo.getNotifications(page: 1, limit: _limit);
    return NotificationListState(
      items: items,
      page: 1,
      hasMore: items.length >= _limit,
    );
  }

  /// Pull-to-refresh. Error aane par purani list screen par rehti hai.
  Future<void> refresh() async {
    final result = await AsyncValue.guard(_fetchFirstPage);
    if (!result.hasError || !state.hasValue) {
      state = result;
    }
    ref.invalidate(unreadCountProvider);
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = current.page + 1;
      final fetched = await _repo.getNotifications(page: nextPage, limit: _limit);

      final existingIds = current.items.map((e) => e.id).toSet();
      final fresh = fetched.where((e) => !existingIds.contains(e.id)).toList();

      state = AsyncData(current.copyWith(
        items: [...current.items, ...fresh],
        page: nextPage,
        hasMore: fetched.length >= _limit,
        isLoadingMore: false,
      ));
    } catch (_) {
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  /// Optimistic update: UI turant badalta hai, API fail ho to wapas revert.
  Future<void> markAsRead(NotificationModel n) async {
    final current = state.value;
    if (current == null || n.isRead) return;

    _replace(n.id, (e) => e.copyWith(isRead: true, readAt: DateTime.now()));
    try {
      await _repo.markAsRead(n.id);
    } catch (_) {
      _replace(n.id, (e) => NotificationModel(
        id: e.id,
        type: e.type,
        title: e.title,
        body: e.body,
        data: e.data,
        isRead: false,
        readAt: null,
        createdAt: e.createdAt,
      ));
    }
    ref.invalidate(unreadCountProvider);
  }

  /// Fail hone par Failure throw karta hai taaki screen snackbar dikha sake.
  Future<void> markAllAsRead() async {
    final current = state.value;
    if (current == null) return;

    await _repo.markAllAsRead();
    final now = DateTime.now();
    state = AsyncData(current.copyWith(
      items: current.items
          .map((e) => e.isRead ? e : e.copyWith(isRead: true, readAt: now))
          .toList(),
    ));
    ref.invalidate(unreadCountProvider);
  }

  void _replace(int id, NotificationModel Function(NotificationModel) update) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(current.copyWith(
      items: current.items.map((e) => e.id == id ? update(e) : e).toList(),
    ));
  }
}

final notificationListViewModelProvider =
AsyncNotifierProvider<NotificationListViewModel, NotificationListState>(
  NotificationListViewModel.new,
);