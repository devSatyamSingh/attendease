import 'package:flutter/material.dart';
import '../../core/routes/app_routes.dart';
import '../../core/routes/route_name.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';


class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // ---- Replace these with real data from your ProfileViewModel ----
  static const _employeeName = "Rahul Sharma";
  static const _designation = "Senior Flutter Developer";
  static const _department = "Mobile Engineering";
  static const _empId = "EMP-48209";
  static const _avatarUrl = "https://i.pravatar.cc/150?img=12";
  static const _isOnline = true;

  static const _presentDays = "18";
  static const _graceUsed = "01";
  static const _avgHours = "8.4h";

  static const _employmentStatus = "Active Full-Time";
  static const _workEmail = "rahul.sharma@company.com";
  static const _contactPhone = "+91 98765 43210";
  static const _expectedTiming = "10:00 AM – 07:00 PM";
  static const _shiftTag = "Standard 9h";
  static const _gracePeriod = "15 minutes window";
  static const _graceTag = "Daily";

  static const _deviceModel = "iPhone 15 Pro Max";
  static const _deviceInfo = "iOS 17.5 • Biometric Verified";
  static const _deviceBound = true;

  static const _appVersion = "AttendEase v2.4.0";
  static const _footerText = "AttendEase Mobile • Zero-Trust Enterprise Edition";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildOverviewHeader(context),
                      const SizedBox(height: 12),
                      _buildOverviewStatsRow(context),
                      const SizedBox(height: 20),
                      _buildEmploymentDetailsCard(context),
                      const SizedBox(height: 16),
                      _buildDeviceCard(context),
                      const SizedBox(height: 16),
                      _buildSettingsList(context),
                      const SizedBox(height: 20),
                      _buildSignOutButton(context),
                      const SizedBox(height: 14),
                      Center(
                        child: CaptionText(
                          _footerText,
                          textAlign: TextAlign.center,
                        ),
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

  // ==================== GRADIENT HEADER ====================
  Widget _buildHeader(BuildContext context) {
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
              AppText(
                "Profile",
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.whiteColor,
              ),
              _buildCircleIconButton(
                icon: Icons.edit_rounded,
                onTap: () {
                  // TODO: Navigator.pushNamed(context, AppRoutes.editProfile);
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildAvatar(),
          const SizedBox(height: 14),
          AppText(
            _employeeName,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.whiteColor,
          ),
          const SizedBox(height: 4),
          AppText(
            "$_designation • $_department",
            fontSize: 13,
            color: AppColors.whiteColor.withOpacity(.85),
            textAlign: TextAlign.center,
            maxLines: 2,
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
                const Icon(
                  Icons.badge_outlined,
                  size: 14,
                  color: AppColors.whiteColor,
                ),
                const SizedBox(width: 6),
                AppText(
                  _empId,
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

  Widget _buildCircleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
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

  Widget _buildAvatar() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 92,
          width: 92,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.whiteColor.withOpacity(.6), width: 2),
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.whiteColor.withOpacity(.2),
            backgroundImage: const NetworkImage(_avatarUrl),
          ),
        ),
        if (_isOnline)
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              height: 16,
              width: 16,
              decoration: BoxDecoration(
                color: AppColors.workingColor,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.whiteColor, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  // ==================== OVERVIEW ====================
  Widget _buildOverviewHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText("October Overview", fontSize: 16, fontWeight: FontWeight.w700),
        InkWell(
          onTap: () {
            // TODO: Navigator.pushNamed(context, AppRoutes.history);
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(
                "Detailed Logs",
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryColor,
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.primaryColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewStatsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatPill(
            icon: Icons.check_circle_outline_rounded,
            iconColor: AppColors.successColor,
            value: _presentDays,
            label: "Present Days",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.watch_later_outlined,
            iconColor: AppColors.errorColor,
            value: _graceUsed,
            label: "Grace Used",
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatPill(
            icon: Icons.timelapse_rounded,
            iconColor: AppColors.infoColor,
            value: _avgHours,
            label: "Per Day",
          ),
        ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: iconColor),
          ),
          const SizedBox(height: 8),
          AppText(value, fontSize: 18, fontWeight: FontWeight.w700),
          const SizedBox(height: 2),
          CaptionText(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // ==================== EMPLOYMENT DETAILS ====================
  Widget _buildEmploymentDetailsCard(BuildContext context) {
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
              _buildDotChip(_employmentStatus, AppColors.successColor),
            ],
          ),
          const SizedBox(height: 14),
          _buildDetailRow(
            icon: Icons.mail_outline_rounded,
            label: "Work Email",
            value: _workEmail,
            trailing: Icons.copy_rounded,
          ),
          const Divider(height: 26),
          _buildDetailRow(
            icon: Icons.call_outlined,
            label: "Contact Phone",
            value: _contactPhone,
            trailing: Icons.phone_forwarded_outlined,
          ),
          const Divider(height: 26),
          _buildDetailRow(
            icon: Icons.access_time_rounded,
            label: "Expected Timing",
            value: _expectedTiming,
            tag: _shiftTag,
          ),
          const Divider(height: 26),
          _buildDetailRow(
            icon: Icons.hourglass_bottom_rounded,
            label: "Grace Period",
            value: _gracePeriod,
            tag: _graceTag,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    IconData? trailing,
    String? tag,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          height: 38,
          width: 38,
          alignment: Alignment.center,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primaryColor),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CaptionText(label),
              const SizedBox(height: 2),
              AppText(
                value,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (tag != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.fieldFillColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: AppText(
              tag,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.labelTextColor,
            ),
          ),
        if (trailing != null)
          IconButton(
            onPressed: () {
              // TODO: copy / call action
            },
            icon: Icon(trailing, size: 18, color: AppColors.labelTextColor),
          ),
      ],
    );
  }

  // ==================== REGISTERED DEVICE ====================
  Widget _buildDeviceCard(BuildContext context) {
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
              AppText("Registered Device", fontSize: 15, fontWeight: FontWeight.w700),
              _buildDotChip(
                _deviceBound ? "Bound & Active" : "Not Bound",
                _deviceBound ? AppColors.successColor : AppColors.errorColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.whiteColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.phone_iphone_rounded,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(_deviceModel, fontSize: 14, fontWeight: FontWeight.w700),
                      const SizedBox(height: 2),
                      CaptionText(_deviceInfo),
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
              Expanded(
                child: CaptionText("Zero-Trust Device Binding"),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, RouteNames.deviceChangeRequest);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: AppText(
                  "Request Change",
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDotChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          AppText(label, fontSize: 11, fontWeight: FontWeight.w700, color: color),
        ],
      ),
    );
  }

  // ==================== SETTINGS LIST ====================
  Widget _buildSettingsList(BuildContext context) {
    final items = [
      _SettingsItem(Icons.password_rounded, "Change Security PIN & Password"),
      _SettingsItem(Icons.notifications_none_rounded, "Notification & Geofence Alerts"),
      _SettingsItem(Icons.support_agent_rounded, "Help & Support Desk"),
      _SettingsItem(Icons.info_outline_rounded, "About $_appVersion"),
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
                      Expanded(
                        child: AppText(item.label, fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.placeholderColor,
                      ),
                    ],
                  ),
                ),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  // ==================== SIGN OUT ====================
  Widget _buildSignOutButton(BuildContext context) {
    return AppButton(
      text: "Sign Out from Device",
      icon: Icons.logout_rounded,
      color: AppColors.errorColor.withOpacity(.1),
      textColor: AppColors.errorColor,
      iconColor: AppColors.errorColor,
      boxShadow: const [],
      onTap: () {
        // TODO: show confirm dialog -> AuthViewModel.signOut(context)
      },
    );
  }
}

class _SettingsItem {
  final IconData icon;
  final String label;
  const _SettingsItem(this.icon, this.label);
}