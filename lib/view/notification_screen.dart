import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../core/errors/failure.dart';
import '../localization/lanaguge_provider.dart';
import '../notification/notification_model.dart';
import '../notification/notification_router.dart';
import '../utils/app_utils.dart';
import '../viewmodel/notification_viewmodel.dart';
import '../widget/app_colors.dart';
import '../widget/app_text.dart';

class NotificationScreen extends ConsumerStatefulWidget {
  const NotificationScreen({super.key});

  @override
  ConsumerState<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends ConsumerState<NotificationScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 200) {
        ref.read(notificationListViewModelProvider.notifier).loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationListViewModelProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _markAllRead() async {
    try {
      await ref
          .read(notificationListViewModelProvider.notifier)
          .markAllAsRead();
    } catch (e) {
      if (!mounted) return;
      AppUtils.showErrorSnackbar(
        context,
        e is Failure ? e.message : 'notifications.err_mark_read'.tr(),
      );
    }
  }

  void _onTap(NotificationModel n) {
    ref.read(notificationListViewModelProvider.notifier).markAsRead(n);
    // NotificationRouter.handle({"type": n.type, ...n.data});
  }

  @override
  Widget build(BuildContext context) {
    // Language badalte hi ye screen turant rebuild ho
    ref.watch(languageProvider);

    final asyncState = ref.watch(notificationListViewModelProvider);
    final unread = ref.watch(unreadCountProvider).value ?? 0;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      appBar: AppBar(
        backgroundColor: AppColors.scaffoldBgColor,
        elevation: 0,
        centerTitle: false,
        // arrow_back_rounded RTL me apne aap mirror hota hai (sahi behavior)
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.headlineTextColor,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: AppText(
          'notifications.title'.tr(),
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          if (unread > 0)
            Padding(
              padding: const EdgeInsetsDirectional.only(end: 8),
              child: TextButton(
                onPressed: _markAllRead,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: AppText(
                  'notifications.mark_all_read'.tr(),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: asyncState.when(
              loading: () => const _NotificationSkeleton(),
              error: (e, _) => _ErrorView(
                message: e is Failure
                    ? e.message
                    : 'notifications.something_wrong_short'.tr(),
                onRetry: () =>
                    ref.invalidate(notificationListViewModelProvider),
              ),
              data: (s) => RefreshIndicator(
                color: AppColors.primaryColor,
                onRefresh: () => ref
                    .read(notificationListViewModelProvider.notifier)
                    .refresh(),
                child: s.items.isEmpty
                    ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [_EmptyView()],
                )
                    : ListView.separated(
                  controller: _scroll,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding:
                  const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
                  itemCount: s.items.length + (s.isLoadingMore ? 1 : 0),
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    if (i >= s.items.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(
                          child: SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppColors.primaryColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    }
                    final n = s.items[i];
                    return _NotificationTile(
                      n: n,
                      onTap: () => _onTap(n),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION TILE
// ============================================================
class _NotificationTile extends StatelessWidget {
  final NotificationModel n;
  final VoidCallback onTap;

  const _NotificationTile({required this.n, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(n.type);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead
              ? AppColors.cardBgColor
              : AppColors.primaryColor.withOpacity(.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: n.isRead
                ? AppColors.borderColor
                : AppColors.primaryColor.withOpacity(.25),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 44,
              width: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withOpacity(.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title/body server se aata hai, waisa hi dikhega
                      Expanded(
                        child: AppText(
                          n.title,
                          fontSize: 14,
                          fontWeight:
                          n.isRead ? FontWeight.w600 : FontWeight.w700,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!n.isRead)
                        Container(
                          margin: const EdgeInsetsDirectional.only(
                            start: 8,
                            top: 4,
                          ),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AppText(
                    n.body,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.bodyTextColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: AppColors.placeholderColor,
                      ),
                      const SizedBox(width: 4),
                      CaptionText(_timeAgo(context, n.createdAt)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _iconFor(String type) {
    switch (type) {
      case NotificationType.holiday:
        return (Icons.celebration_outlined, AppColors.secondaryColor);
      case NotificationType.leaveApproved:
        return (Icons.check_circle_outline, AppColors.successColor);
      case NotificationType.leaveRejected:
        return (Icons.cancel_outlined, AppColors.errorColor);
      default:
        return (Icons.notifications_outlined, AppColors.primaryColor);
    }
  }

  String _timeAgo(BuildContext context, DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'time.just_now'.tr();
    if (d.inMinutes < 60) return 'time.minutes_ago'.tr(args: ['${d.inMinutes}']);
    if (d.inHours < 24) return 'time.hours_ago'.tr(args: ['${d.inHours}']);
    if (d.inDays < 7) return 'time.days_ago'.tr(args: ['${d.inDays}']);
    // Purani date: selected language ke hisaab se (28 Sep 2026 / २८ सित॰ ...)
    return DateFormat("dd MMM yyyy", context.locale.toString()).format(t);
  }
}

// ============================================================
// SHIMMER SKELETON
// ============================================================
class _NotificationSkeleton extends StatefulWidget {
  const _NotificationSkeleton();

  @override
  State<_NotificationSkeleton> createState() => _NotificationSkeletonState();
}

class _NotificationSkeletonState extends State<_NotificationSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ListView.separated(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            return _ShimmerTile(
              progress: _controller.value,
              widthFactor: index.isEven ? 0.85 : 0.65,
            );
          },
        );
      },
    );
  }
}

class _ShimmerTile extends StatelessWidget {
  final double progress;
  final double widthFactor;

  const _ShimmerTile({
    required this.progress,
    required this.widthFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ShimmerBox(
            progress: progress,
            height: 44,
            width: 44,
            radius: 12,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ShimmerBox(
                  progress: progress,
                  height: 14,
                  width: double.infinity,
                ),
                const SizedBox(height: 8),
                _ShimmerBox(
                  progress: progress,
                  height: 12,
                  width: double.infinity,
                ),
                const SizedBox(height: 6),
                FractionallySizedBox(
                  alignment: AlignmentDirectional.centerStart,
                  widthFactor: widthFactor,
                  child: _ShimmerBox(
                    progress: progress,
                    height: 12,
                    width: double.infinity,
                  ),
                ),
                const SizedBox(height: 10),
                _ShimmerBox(
                  progress: progress,
                  height: 10,
                  width: 70,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  final double progress;
  final double height;
  final double width;
  final double radius;

  const _ShimmerBox({
    required this.progress,
    required this.height,
    required this.width,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    // Gradient shimmer: left se right sweep
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1.0 + progress * 2, 0),
          end: Alignment(-0.5 + progress * 2, 0),
          colors: const [
            Color(0xFFE9EDF2),
            Color(0xFFF5F7FA),
            Color(0xFFE9EDF2),
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

// ============================================================
// EMPTY VIEW
// ============================================================
class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.7,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.cardBgColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.borderColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 88,
                  width: 88,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_off_outlined,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(height: 22),
                AppText(
                  'notifications.caught_up'.tr(),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                AppText(
                  'notifications.caught_up_sub'.tr(),
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.bodyTextColor,
                  textAlign: TextAlign.center,
                  height: 1.5,
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFillColor,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.labelTextColor,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: CaptionText('notifications.no_pending'.tr()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ERROR VIEW
// ============================================================
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderColor),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 80,
                width: 80,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.errorColor.withOpacity(.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off_rounded,
                  size: 36,
                  color: AppColors.errorColor,
                ),
              ),
              const SizedBox(height: 18),
              AppText(
                'notifications.something_wrong'.tr(),
                fontSize: 17,
                fontWeight: FontWeight.w700,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              AppText(
                message,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.bodyTextColor,
                textAlign: TextAlign.center,
                height: 1.4,
              ),
              const SizedBox(height: 20),
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        size: 16,
                        color: AppColors.whiteColor,
                      ),
                      const SizedBox(width: 8),
                      AppText(
                        'notifications.try_again'.tr(),
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.whiteColor,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// NOTIFICATION BELL (Dashboard AppBar ke liye)
// ============================================================
class NotificationBell extends ConsumerWidget {
  final VoidCallback onPressed;
  const NotificationBell({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).value ?? 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppColors.headlineTextColor,
          ),
        ),
        if (count > 0)
        // RTL me badge bhi dusre kone par aayega
          PositionedDirectional(
            end: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 16),
              decoration: BoxDecoration(
                color: AppColors.errorColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.scaffoldBgColor,
                  width: 1.5,
                ),
              ),
              child: Text(
                count > 99 ? "99+" : "$count",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: "Poppins",
                  color: AppColors.whiteColor,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}