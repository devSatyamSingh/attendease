import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../model/holiday_model.dart';
import '../../utils/app_topbar.dart';
import '../../viewmodel/holiday_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';

class HolidaysScreen extends ConsumerWidget {
  const HolidaysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final holidaysAsync = ref.watch(holidayViewModelProvider);
    final year = ref.read(holidayViewModelProvider.notifier).currentYear;

    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () =>
                  ref.read(holidayViewModelProvider.notifier).refresh(),
              child: ListView(
                padding: EdgeInsets.fromLTRB(hPad, 6, hPad, 16),
                children: [
                  const AppTopBar(title: "Company Holidays"),                  const SizedBox(height: 10),
                  _buildYearSelector(context, ref, year),
                  const SizedBox(height: 12),
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
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: AppColors.headlineTextColor,
            ),
          ),
        ),
        const Expanded(
          child: AppText(
            "Company Holidays",
            fontSize: 14,
            fontWeight: FontWeight.w600,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(width: 28),
      ],
    );
  }

  // ==================== YEAR SELECTOR ====================
  Widget _buildYearSelector(BuildContext context, WidgetRef ref, int year) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        InkWell(
          onTap: () =>
              ref.read(holidayViewModelProvider.notifier).loadYear(year - 1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(
              Icons.chevron_left_rounded,
              size: 20,
              color: AppColors.labelTextColor,
            ),
          ),
        ),
        SizedBox(
          width: 80,
          child: AppText(
            "$year",
            fontSize: 16,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        InkWell(
          onTap: () =>
              ref.read(holidayViewModelProvider.notifier).loadYear(year + 1),
          customBorder: const CircleBorder(),
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.labelTextColor,
            ),
          ),
        ),
      ],
    );
  }

  // ==================== CONTENT (grouped by month) ====================
  Widget _buildContent(List<HolidayModel> holidays) {
    if (holidays.isEmpty) return _buildEmptyState();

    final sorted = [...holidays]
      ..sort((a, b) => a.holidayDate.compareTo(b.holidayDate));

    final upcoming = sorted.where((h) => !h.isPast).toList();
    final next = upcoming.isNotEmpty ? upcoming.first : null;

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
          const SizedBox(height: 16),
        ],
        ...grouped.entries.map(
              (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  entry.key.toUpperCase(),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: .8,
                  color: AppColors.labelTextColor,
                ),
                const SizedBox(height: 8),
                ...entry.value.map(
                      (h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
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
    final now = DateTime.now();
    final daysAway =
        DateTime(
          holiday.holidayDate.year,
          holiday.holidayDate.month,
          holiday.holidayDate.day,
        )
            .difference(DateTime(now.year, now.month, now.day))
            .inDays;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withOpacity(.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 36,
            width: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.celebration_rounded,
              color: AppColors.whiteColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  holiday.isToday
                      ? "Today's Holiday"
                      : "Next Holiday • ${daysAway}d away",
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor.withOpacity(.8),
                ),
                const SizedBox(height: 2),
                AppText(
                  holiday.name,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                AppText(
                  DateFormat("EEEE, MMM d").format(holiday.holidayDate),
                  fontSize: 11,
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
    final Color accent = holiday.isFullDay
        ? AppColors.successColor
        : AppColors.warningColor;
    final String typeLabel = holiday.isFullDay
        ? "Full Day"
        : "Half Day${holiday.halfDayPeriod != null ? ' • ${_periodLabel(holiday.halfDayPeriod!)}' : ''}";

    return Opacity(
      opacity: holiday.isPast ? .55 : 1,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            _buildDateBox(holiday.holidayDate, accent),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    holiday.name,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
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
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          AppText(
            "${date.day}",
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
          const SizedBox(height: 1),
          AppText(
            DateFormat("MMM").format(date).toUpperCase(),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: AppText(
        label,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        color: color,
      ),
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
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 44,
            width: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.event_busy_rounded,
              size: 20,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          const AppText(
            "No holidays found",
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 3),
          AppText(
            "No holidays are listed for this year yet.",
            fontSize: 11,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== ERROR STATE ====================
  Widget _buildErrorState(WidgetRef ref, Object error) {
    final message = error is Failure
        ? error.message
        : "Couldn't load holidays.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            size: 26,
            color: AppColors.errorColor,
          ),
          const SizedBox(height: 8),
          AppText(
            message,
            fontSize: 12,
            color: AppColors.labelTextColor,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 130,
            child: AppButton(
              text: "Retry",
              icon: Icons.refresh_rounded,
              height: 40,
              onTap: () =>
                  ref.read(holidayViewModelProvider.notifier).refresh(),
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
        AppSkeletonBox(height: 70, borderRadius: 16),
        const SizedBox(height: 16),
        AppSkeletonBox(height: 10, width: 100, borderRadius: 6),
        const SizedBox(height: 8),
        ...List.generate(4, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: AppColors.cardBgColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderColor),
              ),
              child: Row(
                children: [
                  AppSkeletonBox(height: 44, width: 44, borderRadius: 10),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSkeletonBox(height: 12, width: 130, borderRadius: 6),
                        const SizedBox(height: 7),
                        AppSkeletonBox(height: 9, width: 80, borderRadius: 6),
                      ],
                    ),
                  ),
                  AppSkeletonBox(height: 20, width: 55, borderRadius: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}