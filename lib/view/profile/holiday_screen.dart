import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../model/holiday_model.dart';
import '../../viewmodel/holiday_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';

/// AttendEase — Holidays screen.
/// Wired to [holidayViewModelProvider] (`GET /holidays?from=&to=`),
/// scoped to a calendar year at a time. Holidays are grouped by month
/// and sorted chronologically; past dates are visually dimmed and the
/// next upcoming holiday is called out at the top.
class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayViewModelProvider);
    final year = ref.read(holidayViewModelProvider.notifier).currentYear;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => ref.read(holidayViewModelProvider.notifier).refresh(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _buildTopBar(context),
                  const SizedBox(height: 18),
                  _buildYearSelector(context, ref, year),
                  const SizedBox(height: 18),
                  holidaysAsync.when(
                    loading: () => const _HolidaysSkeleton(),
                    error: (error, _) => _buildErrorState(ref, error),
                    data: (holidays) => _buildContent(holidays),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ==================== TOP BAR ====================
  Widget _buildTopBar(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.arrow_back_rounded, color: AppColors.headlineTextColor),
          ),
        ),
        const Expanded(
          child: AppText(
            "Company Holidays",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 32),
      ],
    );
  }

  // ==================== YEAR SELECTOR ====================
  Widget _buildYearSelector(BuildContext context, WidgetRef ref, int year) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () => ref.read(holidayViewModelProvider.notifier).loadYear(year - 1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.chevron_left_rounded, color: AppColors.labelTextColor),
          ),
        ),
        SizedBox(
          width: 100,
          child: AppText(
            "$year",
            fontSize: 20,
            fontWeight: FontWeight.w800,
            textAlign: TextAlign.center,
          ),
        ),
        InkWell(
          onTap: () => ref.read(holidayViewModelProvider.notifier).loadYear(year + 1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.chevron_right_rounded, color: AppColors.labelTextColor),
          ),
        ),
      ],
    );
  }

  // ==================== CONTENT (grouped by month) ====================
  Widget _buildContent(List<HolidayModel> holidays) {
    if (holidays.isEmpty) return _buildEmptyState();

    final sorted = [...holidays]..sort((a, b) => a.holidayDate.compareTo(b.holidayDate));

    final upcoming = sorted.where((h) => !h.isPast).toList();
    final next = upcoming.isNotEmpty ? upcoming.first : null;

    // Group by "Month Year" label, preserving chronological order.
    final Map<String, List<HolidayModel>> grouped = {};
    for (final h in sorted) {
      final key = DateFormat("MMMM yyyy").format(h.holidayDate);
      grouped.putIfAbsent(key, () => []).add(h);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (next != null) ...[
          _buildNextHolidayBanner(next),
          const SizedBox(height: 22),
        ],
        ...grouped.entries.map(
              (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  entry.key.toUpperCase(),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: AppColors.labelTextColor,
                ),
                const SizedBox(height: 10),
                ...entry.value.map(
                      (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildHolidayCard(h),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==================== NEXT HOLIDAY BANNER ====================
  Widget _buildNextHolidayBanner(HolidayModel holiday) {
    final daysAway = DateTime(holiday.holidayDate.year, holiday.holidayDate.month, holiday.holidayDate.day)
        .difference(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day))
        .inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: AppColors.primaryColor.withOpacity(.3), blurRadius: 18, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 46,
            width: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.whiteColor.withOpacity(.18), shape: BoxShape.circle),
            child: const Icon(Icons.celebration_rounded, color: AppColors.whiteColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  holiday.isToday ? "Today's Holiday" : "Next Holiday • ${daysAway}d away",
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor.withOpacity(.8),
                ),
                const SizedBox(height: 3),
                AppText(
                  holiday.name,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.whiteColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                AppText(
                  DateFormat("EEEE, MMM d").format(holiday.holidayDate),
                  fontSize: 12,
                  color: AppColors.whiteColor.withOpacity(.85),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== HOLIDAY CARD ====================
  Widget _buildHolidayCard(HolidayModel holiday) {
    final Color accent = holiday.isFullDay ? AppColors.successColor : AppColors.warningColor;
    final String typeLabel = holiday.isFullDay
        ? "Full Day"
        : "Half Day${holiday.halfDayPeriod != null ? ' • ${_periodLabel(holiday.halfDayPeriod!)}' : ''}";

    return Opacity(
      opacity: holiday.isPast ? .55 : 1,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            _buildDateBox(holiday.holidayDate, accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    holiday.name,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  CaptionText(DateFormat("EEEE").format(holiday.holidayDate)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _buildTypeChip(typeLabel, accent),
          ],
        ),
      ),
    );
  }

  Widget _buildDateBox(DateTime date, Color accent) {
    return Container(
      width: 52,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: accent.withOpacity(.1), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          AppText("${date.day}", fontSize: 18, fontWeight: FontWeight.w800, color: accent),
          const SizedBox(height: 2),
          AppText(
            DateFormat("MMM").format(date).toUpperCase(),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: AppText(label, fontSize: 10, fontWeight: FontWeight.w700, color: color),
    );
  }

  String _periodLabel(String period) {
    switch (period.toUpperCase()) {
      case "FIRST_HALF":
        return "1st Half";
      case "SECOND_HALF":
        return "2nd Half";
      default:
        return period;
    }
  }

  // ==================== EMPTY STATE ====================
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 56,
            width: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
            child: const Icon(Icons.event_busy_rounded, size: 24, color: AppColors.primaryColor),
          ),
          const SizedBox(height: 14),
          const AppText("No holidays found", fontSize: 14, fontWeight: FontWeight.w700),
          const SizedBox(height: 4),
          AppText(
            "No holidays are listed for this year yet.",
            fontSize: 12,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(WidgetRef ref, Object error) {
    final message = error is Failure ? error.message : "Couldn't load holidays.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 32, color: AppColors.errorColor),
          const SizedBox(height: 10),
          AppText(message, fontSize: 13, color: AppColors.labelTextColor, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          SizedBox(
            width: 140,
            child: AppButton(
              text: "Retry",
              icon: Icons.refresh_rounded,
              onTap: () => ref.read(holidayViewModelProvider.notifier).refresh(),
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== SHIMMER SKELETON ====================
class _HolidaysSkeleton extends StatelessWidget {
  const _HolidaysSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBox(height: 96, borderRadius: 20),
        const SizedBox(height: 22),
        AppSkeletonBox(height: 12, width: 120, borderRadius: 6),
        const SizedBox(height: 10),
        ...List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  AppSkeletonBox(height: 52, width: 52, borderRadius: 12),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(height: 13, width: 140, borderRadius: 6),
                        const SizedBox(height: 8),
                        AppSkeletonBox(height: 10, width: 90, borderRadius: 6),
                      ],
                    ),
                  ),
                  AppSkeletonBox(height: 22, width: 60, borderRadius: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}