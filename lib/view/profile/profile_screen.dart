import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../model/active_device_model.dart';
import '../../model/profile_model.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../viewmodel/device_viewmodel.dart';
import '../../viewmodel/profile_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';

/// AttendEase — Profile screen.
/// Watches [profileViewModelProvider] (the real `GET /profile` call)
/// and [deviceViewModelProvider] (`GET /devices/status`) — each
/// renders its own loading/error/data state independently, so a slow
/// device-status call never blocks the employment-details card from
/// showing, and vice versa.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => Future.wait([
                ref.read(profileViewModelProvider.notifier).refresh(),
                ref.read(deviceViewModelProvider.notifier).refresh(),
              ]),
              child: profileAsync.when(
                loading: () => const _ProfileSkeleton(),
                error: (error, _) => _ProfileErrorState(
                  message: error is Failure ? error.message : "Couldn't load your profile.",
                  onRetry: () => ref.read(profileViewModelProvider.notifier).refresh(),
                ),
                data: (profile) => _ProfileContent(profile: profile),
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
  const _ProfileContent({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(context, profile),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHistoryLink(context),
              const SizedBox(height: 16),
              _buildEmploymentDetailsCard(profile),
              const SizedBox(height: 16),
              _buildDeviceCard(context, ref),
              const SizedBox(height: 16),
              _buildSettingsList(context),
              const SizedBox(height: 20),
              _buildSignOutButton(context, ref),
              const SizedBox(height: 14),
              const Center(
                child: CaptionText(
                  "AttendEase Mobile • Zero-Trust Enterprise Edition",
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Header ----
  Widget _buildHeader(BuildContext context, ProfileModel profile) {
    final initials = _initialsOf(profile.name);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCircleIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              AppText("Profile", fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.whiteColor),
              _buildCircleIconButton(
                icon: Icons.edit_rounded,
                onTap: () {
                  // TODO: Navigator.pushNamed(context, AppRoutes.editProfile);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            height: 92,
            width: 92,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.whiteColor.withOpacity(.18),
              border: Border.all(color: AppColors.whiteColor.withOpacity(.6), width: 2),
            ),
            child: AppText(
              initials,
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: AppColors.whiteColor,
            ),
          ),
          const SizedBox(height: 14),
          AppText(profile.name, fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.whiteColor),
          const SizedBox(height: 4),
          AppText(
            profile.email,
            fontSize: 13,
            color: AppColors.whiteColor.withOpacity(.85),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withOpacity(.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_outlined, size: 14, color: AppColors.whiteColor),
                const SizedBox(width: 6),
                AppText(
                  profile.employeeCode,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.whiteColor,
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

  Widget _buildCircleIconButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: 38,
        width: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.whiteColor.withOpacity(.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.whiteColor, size: 18),
      ),
    );
  }

  // ---- History link ----
  Widget _buildHistoryLink(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigator.pushNamed(context, AppRoutes.history);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardBgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 38,
              width: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(11)),
              child: const Icon(Icons.history_rounded, size: 18, color: AppColors.primaryColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppText("View Attendance History", fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.placeholderColor),
          ],
        ),
      ),
    );
  }

  // ---- Employment details (real ProfileModel fields) ----
  Widget _buildEmploymentDetailsCard(ProfileModel profile) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText("Employment Details", fontSize: 15, fontWeight: FontWeight.w700),
              _buildDotChip(
                profile.status,
                AppColors.requestStatusColor(profile.status),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow(icon: Icons.mail_outline_rounded, label: "Work Email", value: profile.email),
          const Divider(height: 26),
          _buildDetailRow(icon: Icons.call_outlined, label: "Contact Phone", value: profile.phone),
          const Divider(height: 26),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: "Expected Timing",
            value:
            "${_formatTime(profile.expectedLoginTime)} – ${_formatTime(profile.expectedLogoutTime)}",
          ),
          const Divider(height: 26),
          _buildDetailRow(
            icon: Icons.hourglass_bottom_rounded,
            label: "Grace Period",
            value: "${profile.lateGraceMinutes} minutes window",
          ),
        ],
      ),
    );
  }

  String _formatTime(String hms) {
    try {
      final parts = hms.split(":");
      final dt = DateTime(2000, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
      return DateFormat("hh:mm a").format(dt);
    } catch (_) {
      return hms;
    }
  }

  Widget _buildDetailRow({required IconData icon, required String label, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 38,
          width: 38,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: AppColors.primaryColor),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText(label),
              const SizedBox(height: 2),
              AppText(value, fontSize: 14, fontWeight: FontWeight.w600, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }

  // ---- Registered device (its own async, doesn't block the rest) ----
  Widget _buildDeviceCard(BuildContext context, WidgetRef ref) {
    final deviceAsync = ref.watch(deviceViewModelProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: deviceAsync.when(
        loading: () => const _DeviceCardSkeleton(),
        error: (error, _) => Row(
          children: [
            const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.errorColor),
            const SizedBox(width: 8),
            Expanded(child: CaptionText("Couldn't load device info")),
            TextButton(
              onPressed: () => ref.read(deviceViewModelProvider.notifier).refresh(),
              child: const AppText("Retry", fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
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
            AppText("Registered Device", fontSize: 15, fontWeight: FontWeight.w700),
            _buildDotChip(
              device == null ? "Not Registered" : (bound ? "Bound & Active" : device.status),
              device == null ? AppColors.labelTextColor : AppColors.requestStatusColor(device.status),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(14)),
          child: Row(
            children: [
              Container(
                height: 40,
                width: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.whiteColor, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.phone_iphone_rounded, color: AppColors.primaryColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      device?.deviceModel ?? "No device registered yet",
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    CaptionText(
                      device == null
                          ? "Log in once to bind this handset"
                          : "${device.platform} • Last active ${_lastActiveLabel(device.lastLoginAt)}",
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Icon(Icons.shield_outlined, size: 14, color: AppColors.labelTextColor),
            const SizedBox(width: 6),
            const Expanded(child: CaptionText("Zero-Trust Device Binding")),
            // TextButton(
            //   onPressed: () => Navigator.pushNamed(context, RouteNames.deviceChangeRequest),
            //   style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10)),
            //   child: const AppText(
            //     "Request Change",
            //     fontSize: 12,
            //     fontWeight: FontWeight.w700,
            //     color: AppColors.primaryColor,
            //   ),
            // ),
          ],
        ),
      ],
    );
  }

  String _lastActiveLabel(DateTime? lastLoginAt) {
    if (lastLoginAt == null) return "recently";
    final diff = DateTime.now().difference(lastLoginAt);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat("dd MMM").format(lastLoginAt);
  }

  Widget _buildDotChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 6, width: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 5),
          AppText(label, fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ],
      ),
    );
  }

  // ---- Settings list ----
  Widget _buildSettingsList(BuildContext context) {
    final items = [
      _SettingsItem(Icons.password_rounded, "Change Security PIN & Password"),
      _SettingsItem(Icons.notifications_none_rounded, "Notification & Geofence Alerts"),
      _SettingsItem(Icons.support_agent_rounded, "Help & Support Desk"),
      _SettingsItem(Icons.info_outline_rounded, "About AttendEase v2.4.0"),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
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
                  top: index == 0 ? const Radius.circular(18) : Radius.zero,
                  bottom: index == items.length - 1 ? const Radius.circular(18) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, size: 20, color: AppColors.headlineTextColor),
                      const SizedBox(width: 14),
                      Expanded(child: AppText(item.label, fontSize: 14, fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.placeholderColor),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1) const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  // ---- Sign out ----
  Widget _buildSignOutButton(BuildContext context, WidgetRef ref) {
    return AppButton(
      text: "Sign Out from Device",
      icon: Icons.logout_rounded,
      color: AppColors.errorColor.withOpacity(.1),
      textColor: AppColors.errorColor,
      iconColor: AppColors.errorColor,
      boxShadow: const [],
      onTap: () => _confirmSignOut(context, ref),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const AppText("Sign out?", fontSize: 16, fontWeight: FontWeight.w700),
        content: const AppText(
          "You'll need to sign in again to mark attendance on this device.",
          fontSize: 13,
          color: AppColors.labelTextColor,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const AppText("Cancel", fontSize: 13, fontWeight: FontWeight.w600),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const AppText(
              "Sign Out",
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.errorColor,
            ),
          ),
        ],
      ),
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
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          decoration: const BoxDecoration(
            gradient: AppColors.heroGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _shimmerCircle(38, baseColor: Colors.white.withOpacity(.25)),
                  _shimmerCircle(38, baseColor: Colors.white.withOpacity(.25)),
                ],
              ),
              const SizedBox(height: 18),
              _shimmerCircle(92, baseColor: Colors.white.withOpacity(.3)),
              const SizedBox(height: 16),
              AppSkeletonBox(height: 18, width: 160, borderRadius: 8),
              const SizedBox(height: 8),
              AppSkeletonBox(height: 12, width: 200, borderRadius: 6),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            children: [
              AppSkeletonBox(height: 62, borderRadius: 16),
              const SizedBox(height: 16),
              _cardSkeleton(rows: 4),
              const SizedBox(height: 16),
              _cardSkeleton(rows: 2),
              const SizedBox(height: 16),
              AppSkeletonBox(height: 220, borderRadius: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _shimmerCircle(double size, {required Color baseColor}) {
    return Container(height: size, width: size, decoration: BoxDecoration(color: baseColor, shape: BoxShape.circle));
  }

  Widget _cardSkeleton({required int rows}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: List.generate(rows, (i) {
          return Padding(
            padding: EdgeInsets.only(bottom: i == rows - 1 ? 0 : 18),
            child: Row(
              children: [
                AppSkeletonBox(height: 38, width: 38, borderRadius: 10),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSkeletonBox(height: 10, width: 80, borderRadius: 6),
                      const SizedBox(height: 6),
                      AppSkeletonBox(height: 14, width: 150, borderRadius: 6),
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
            AppSkeletonBox(height: 15, width: 130, borderRadius: 6),
            AppSkeletonBox(height: 20, width: 80, borderRadius: 20),
          ],
        ),
        const SizedBox(height: 14),
        AppSkeletonBox(height: 64, borderRadius: 14),
      ],
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
      children: [
        SizedBox(
          height: 500,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 64,
                    width: 64,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.errorColor.withOpacity(.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.wifi_off_rounded, size: 28, color: AppColors.errorColor),
                  ),
                  const SizedBox(height: 16),
                  AppText(
                    "Couldn't load your profile",
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  AppText(
                    message,
                    fontSize: 13,
                    color: AppColors.labelTextColor,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 160,
                    child: AppButton(text: "Retry", icon: Icons.refresh_rounded, onTap: onRetry),
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