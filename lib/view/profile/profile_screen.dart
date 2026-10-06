import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../localization/lanaguge_provider.dart';
import '../../localization/language_screen.dart';
import '../../model/active_device_model.dart';
import '../../model/profile_model.dart';
import '../../utils/app_topbar.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/device_viewmodel.dart';
import '../../viewmodel/profile_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';
import 'holiday_screen.dart';
import 'logout_dialog.dart';

const String _appVersion = '2.4.0';

// ==================== RTL HELPERS ====================

/// Phone / email / employee code hamesha LTR me dikhne chahiye (Urdu me bhi).
Widget _ltr(Widget child) => Directionality(textDirection: TextDirection.ltr, child: child);

/// Forward chevron: LTR me ">", RTL me "<" (explicit, har device pe same).
class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Icon(
      rtl ? Icons.chevron_left_rounded : Icons.chevron_right_rounded,
      size: 20,
      color: AppColors.placeholderColor,
      textDirection: TextDirection.ltr, // double-mirroring roko
    );
  }
}

/// API se aane wale status ("ACTIVE") ko translate karo.
/// Key na mile to original value hi dikhao.
String _statusLabel(String raw) {
  final key = 'status.${raw.toLowerCase().trim()}';
  final translated = key.tr();
  return translated == key ? raw : translated;
}

// ==================== SCREEN ====================
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Language badalte hi ye screen rebuild hogi
    ref.watch(languageProvider);

    final profileAsync = ref.watch(profileViewModelProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final hPad = (screenWidth * 0.045).clamp(12.0, 24.0);
    final maxContentWidth = screenWidth > 700 ? 520.0 : double.infinity;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxContentWidth),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => Future.wait([
                ref.read(profileViewModelProvider.notifier).refresh(),
                ref.read(deviceViewModelProvider.notifier).refresh(),
              ]),
              child: profileAsync.when(
                loading: () => _ProfileSkeleton(hPad: hPad),
                error: (error, _) => _ProfileErrorState(
                  message: error is Failure ? error.message : 'errors.generic'.tr(),
                  onRetry: () => ref.read(profileViewModelProvider.notifier).refresh(),
                ),
                data: (profile) => _ProfileContent(
                  profile: profile,
                  hPad: hPad,
                  screenWidth: screenWidth,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==================== LOADED CONTENT ====================
class _ProfileContent extends ConsumerWidget {
  final ProfileModel profile;
  final double hPad;
  final double screenWidth;

  const _ProfileContent({
    required this.profile,
    required this.hPad,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _buildHeader(context, profile),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(hPad, 16, hPad, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHolidayCard(context),
              const SizedBox(height: 12),
              _buildEmploymentDetailsCard(context, profile),
              const SizedBox(height: 12),
              _buildDeviceCard(context, ref),
              const SizedBox(height: 12),
              _buildLanguageCard(context, ref),
              const SizedBox(height: 12),
              _buildSettingsList(context),
              const SizedBox(height: 16),
              const _SignOutButton(),
              const SizedBox(height: 12),
              Center(
                child: CaptionText(
                  'profile.footer'.tr(),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== HEADER ====================
  Widget _buildHeader(BuildContext context, ProfileModel profile) {
    final initials = _initialsOf(profile.name);
    final avatarSize = (screenWidth * 0.19).clamp(64.0, 80.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.fromSTEB(hPad, 6, hPad, 22),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          AppTopBar(title: 'profile.title'.tr(), color: AppColors.whiteColor),
          const SizedBox(height: 10),
          Container(
            height: avatarSize,
            width: avatarSize,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.whiteColor.withOpacity(.18),
              border: Border.all(color: AppColors.whiteColor.withOpacity(.6), width: 2),
            ),
            child: AppText(
              initials,
              fontSize: avatarSize * 0.36,
              fontWeight: FontWeight.w600,
              color: AppColors.whiteColor,
            ),
          ),
          const SizedBox(height: 10),
          AppText(
            profile.name,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: AppColors.whiteColor,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          _ltr(
            AppText(
              profile.email,
              fontSize: 12,
              color: AppColors.whiteColor.withOpacity(.85),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: 13, color: AppColors.whiteColor),
                const SizedBox(width: 5),
                _ltr(
                  AppText(
                    profile.employeeCode,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.whiteColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r"\s+")).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return "?";
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  // ==================== HOLIDAY CARD ====================
  Widget _buildHolidayCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HolidaysScreen()));
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.celebration_rounded, size: 17, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('profile.holidays'.tr(), fontSize: 13, fontWeight: FontWeight.w600),
                  const SizedBox(height: 2),
                  CaptionText('profile.holidays_sub'.tr()),
                ],
              ),
            ),
            const _Chevron(),
          ],
        ),
      ),
    );
  }

  // ==================== EMPLOYMENT DETAILS ====================
  Widget _buildEmploymentDetailsCard(BuildContext context, ProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText('profile.employment'.tr(), fontSize: 13, fontWeight: FontWeight.w600),
              _buildDotChip(
                _statusLabel(profile.status),
                AppColors.requestStatusColor(profile.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            icon: Icons.mail_outline_rounded,
            label: 'profile.work_email'.tr(),
            value: profile.email,
            forceLtr: true,
          ),
          const Divider(height: 20),
          _buildDetailRow(
            icon: Icons.call_outlined,
            label: 'profile.contact_phone'.tr(),
            value: profile.phone,
            forceLtr: true,
          ),
          const Divider(height: 20),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: 'profile.expected_timing'.tr(),
            value:
            "${_formatTime(context, profile.expectedLoginTime)} – ${_formatTime(context, profile.expectedLogoutTime)}",
            forceLtr: true,   // NAYA
          ),
        ],
      ),
    );
  }

  String _formatTime(BuildContext context, String hms) {
    try {
      final parts = hms.split(":");
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      final t = DateFormat("hh:mm a", context.locale.toString()).format(dt);
      return '\u2066$t\u2069'; // LTR isolate: andar ka text hamesha left-to-right
    } catch (_) {
      return hms;
    }
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool forceLtr = false,
  }) {
    final valueText = AppText(
      value,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          alignment: Alignment.center,
          margin: const EdgeInsetsDirectional.only(end: 11),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: AppColors.primaryColor),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText(label),
              const SizedBox(height: 2),
              forceLtr ? _ltr(valueText) : valueText,
            ],
          ),
        ),
      ],
    );
  }

  // ==================== DEVICE CARD ====================
  Widget _buildDeviceCard(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceViewModelProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: deviceAsync.when(
        loading: () => const _DeviceCardSkeleton(),
        error: (error, _) => Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.errorColor),
            const SizedBox(width: 8),
            Expanded(child: CaptionText('profile.device_load_error'.tr())),
            TextButton(
              onPressed: () => ref.read(deviceViewModelProvider.notifier).refresh(),
              child: AppText(
                'common.retry'.tr(),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
          ],
        ),
        data: (status) => _buildDeviceCardContent(context, status.activeDevice),
      ),
    );
  }

  Widget _buildDeviceCardContent(BuildContext context, ActiveDeviceModel? device) {
    final bool bound = device != null && device.status.toUpperCase() == "ACTIVE";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppText('profile.registered_device'.tr(), fontSize: 13, fontWeight: FontWeight.w600),
            _buildDotChip(
              device == null
                  ? 'profile.not_registered'.tr()
                  : (bound ? 'profile.bound_active'.tr() : _statusLabel(device.status)),
              device == null ? AppColors.labelTextColor : AppColors.requestStatusColor(device.status),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Container(
                height: 36,
                width: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.whiteColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.phone_iphone_rounded, size: 18, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      device?.deviceModel ?? 'profile.no_device'.tr(),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CaptionText(
                      device == null
                          ? 'profile.login_to_bind'.tr()
                          : 'profile.last_active'.tr(
                        args: ['\u2066${device.platform}\u2069', _lastActiveLabel(context, device.lastLoginAt)],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Icon(Icons.shield_outlined, size: 13, color: AppColors.labelTextColor),
            const SizedBox(width: 6),
            Expanded(child: CaptionText('profile.device_binding'.tr())),
          ],
        ),
      ],
    );
  }

  String _lastActiveLabel(BuildContext context, DateTime? lastLoginAt) {
    if (lastLoginAt == null) return 'time.recently'.tr();
    final diff = DateTime.now().difference(lastLoginAt);
    if (diff.inMinutes < 60) return 'time.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    if (diff.inHours < 24) return 'time.hours_ago'.tr(args: ['${diff.inHours}']);
    return DateFormat("dd MMM", context.locale.toString()).format(lastLoginAt);
  }

  // ==================== LANGUAGE CARD ====================
  Widget _buildLanguageCard(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LanguageScreen()),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(Icons.translate_rounded, size: 17, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText('common.language'.tr(), fontSize: 13, fontWeight: FontWeight.w600),
                  const SizedBox(height: 2),
                  CaptionText('language.subtitle'.tr(), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AppText(
                current.name,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            const _Chevron(),
          ],
        ),
      ),
    );
  }

  Widget _buildDotChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, width: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          AppText(label, fontSize: 10, fontWeight: FontWeight.w600, color: color),
        ],
      ),
    );
  }

  // ==================== SETTINGS LIST ====================
  Widget _buildSettingsList(BuildContext context) {
    final items = [
      _SettingsItem(Icons.password_rounded, 'profile.settings_password'.tr()),
      _SettingsItem(Icons.notifications_none_rounded, 'profile.settings_alerts'.tr()),
      _SettingsItem(Icons.support_agent_rounded, 'profile.settings_help'.tr()),
      _SettingsItem(Icons.info_outline_rounded, 'profile.settings_about'.tr(args: [_appVersion])),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Column(
            children: [
              InkWell(
                onTap: () {
                  // TODO: route per item
                },
                borderRadius: BorderRadius.vertical(
                  top: index == 0 ? const Radius.circular(16) : Radius.zero,
                  bottom: index == items.length - 1 ? const Radius.circular(16) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 18, color: AppColors.headlineTextColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppText(item.label, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      const _Chevron(),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1) const Divider(height: 1, indent: 13, endIndent: 13),
            ],
          );
        }),
      ),
    );
  }

  // ==================== SIGN OUT ====================
  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: 'profile.sign_out'.tr(),
      icon: Icons.logout_rounded,
      color: AppColors.errorColor.withOpacity(.1),
      textColor: AppColors.errorColor,
      iconColor: AppColors.errorColor,
      boxShadow: const [],
      onTap: () => _confirmSignOut(context, ref),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.errorColor,
      title: 'profile.sign_out_title'.tr(),
      message: 'profile.sign_out_msg'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'profile.sign_out_confirm'.tr(),
      confirmColor: AppColors.errorColor,
    );

    if (confirmed != true) return;

    await ref.read(authViewModelProvider.notifier).logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  const _SettingsItem(this.icon, this.label);
}

// ==================== SKELETON (shimmer) ====================
class _ProfileSkeleton extends StatelessWidget {
  final double hPad;
  const _ProfileSkeleton({required this.hPad});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsetsDirectional.fromSTEB(hPad, 6, hPad, 22),
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              AppTopBar(title: 'profile.title'.tr(), color: AppColors.whiteColor),
              const SizedBox(height: 10),
              Container(
                height: 72,
                width: 72,
                decoration: BoxDecoration(color: Colors.white.withOpacity(.3), shape: BoxShape.circle),
              ),
              const SizedBox(height: 12),
              AppSkeletonBox(height: 16, width: 150, borderRadius: 8),
              const SizedBox(height: 8),
              AppSkeletonBox(height: 12, width: 190, borderRadius: 6),
            ],
          ),
        ),
        Padding(
          padding: EdgeInsetsDirectional.fromSTEB(hPad, 16, hPad, 20),
          child: Column(
            children: [
              AppSkeletonBox(height: 60, borderRadius: 16),
              const SizedBox(height: 12),
              _cardSkeleton(rows: 4),
              const SizedBox(height: 12),
              _cardSkeleton(rows: 2),
              const SizedBox(height: 12),
              AppSkeletonBox(height: 200, borderRadius: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cardSkeleton({required int rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: List.generate(rows, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 14),
            child: Row(
              children: [
                AppSkeletonBox(height: 34, width: 34, borderRadius: 10),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(height: 9, width: 80, borderRadius: 6),
                      const SizedBox(height: 6),
                      AppSkeletonBox(height: 13, width: 140, borderRadius: 6),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _DeviceCardSkeleton extends StatelessWidget {
  const _DeviceCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppSkeletonBox(height: 13, width: 120, borderRadius: 6),
            AppSkeletonBox(height: 20, width: 80, borderRadius: 20),
          ],
        ),
        const SizedBox(height: 12),
        AppSkeletonBox(height: 58, borderRadius: 14),
      ],
    );
  }
}

// ==================== SIGN OUT BUTTON ====================
class _SignOutButton extends ConsumerStatefulWidget {
  const _SignOutButton();

  @override
  ConsumerState<_SignOutButton> createState() => _SignOutButtonState();
}

class _SignOutButtonState extends ConsumerState<_SignOutButton> {
  bool _loading = false;

  Future<void> _handleSignOut() async {
    final confirmed = await AnimatedConfirmDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.errorColor,
      title: 'profile.sign_out_title'.tr(),
      message: 'profile.sign_out_msg'.tr(),
      cancelText: 'common.cancel'.tr(),
      confirmText: 'profile.sign_out_confirm'.tr(),
      confirmColor: AppColors.errorColor,
    );

    if (confirmed != true || !mounted) return;

    // await se pehle navigator pakad lo, widget dispose bhi ho jaye to
    // navigation chalega.
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      await ref.read(authViewModelProvider.notifier).logout();
    } finally {
      if (mounted) setState(() => _loading = false);
    }

    navigator.pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return AppButton(
      text: 'profile.sign_out'.tr(),
      icon: Icons.logout_rounded,
      color: AppColors.errorColor.withOpacity(.1),
      textColor: AppColors.errorColor,
      iconColor: AppColors.errorColor,
      boxShadow: const [],
      loading: _loading,
      onTap: _loading ? null : _handleSignOut,
    );
  }
}

// ==================== ERROR STATE ====================
class _ProfileErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ProfileErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        AppTopBar(title: 'profile.title'.tr()),
        SizedBox(
          height: 440,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 56,
                    width: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 26, color: AppColors.errorColor),
                  ),
                  const SizedBox(height: 14),
                  AppText(
                    'profile.load_error'.tr(),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    message,
                    fontSize: 12,
                    color: AppColors.labelTextColor,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 150,
                    child: AppButton(
                      text: 'common.retry'.tr(),
                      icon: Icons.refresh_rounded,
                      onTap: onRetry,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}