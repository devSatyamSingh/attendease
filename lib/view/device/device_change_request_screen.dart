import 'package:flutter/material.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';

/// AttendEase — "Connected Devices" / device-change-request screen.
/// Shown when a login is detected from a device other than the one
/// bound to the employee's account (Zero-Trust device binding flow).
class DeviceChangeRequestScreen extends StatefulWidget {
  const DeviceChangeRequestScreen({super.key});

  @override
  State<DeviceChangeRequestScreen> createState() => _DeviceChangeRequestScreenState();
}

class _DeviceChangeRequestScreenState extends State<DeviceChangeRequestScreen> {
  static const _maxReasonLength = 140;
  static const _quickReasons = ["Upgraded device", "Old phone damaged", "Lost old device"];

  // ---- Replace with real data from DeviceViewModel ----
  static const _registeredDeviceName = "iPhone 15 Pro Max";
  static const _registeredDeviceInfo = "iOS 17.5 • Active yesterday";
  static const _newDeviceName = "Google Pixel 8 Pro";
  static const _newDeviceInfo = "Detected: Today, 09:42 AM • Ghaziabad, IN";
  static const _queueLabel = "QUEUE #3";
  static const _refId = "Ref: REQ-88219-ATN";
  static const _submittedAt = "Today, 09:44 AM";
  static const _etaLabel = "15 – 30 mins";
  static const _approverNote =
      "Your manager (Devon Vance) and IT Ops receive immediate push "
      "verification. Need instant access for a shift?";

  final TextEditingController _reasonController = TextEditingController();
  String? _selectedQuickReason;
  bool _reviewExpanded = true;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                _buildTopBar(context),
                const SizedBox(height: 22),
                _buildHeroIcon(context),
                const SizedBox(height: 20),
                AppText(
                  "New Device Detected",
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                AppText(
                  "You're logging in from a different device. Submit a "
                      "quick verification request for admin approval to continue.",
                  fontSize: 13,
                  color: AppColors.labelTextColor,
                  textAlign: TextAlign.center,
                  height: 1.4,
                ),
                const SizedBox(height: 24),
                _buildDeviceCompareCard(context),
                const SizedBox(height: 24),
                _buildReasonLabel(context),
                const SizedBox(height: 10),
                _buildReasonField(context),
                const SizedBox(height: 10),
                _buildQuickReasonChips(context),
                const SizedBox(height: 22),
                _buildSubmitButton(context),
                const SizedBox(height: 14),
                _buildStatusLink(context),
                const SizedBox(height: 20),
                _buildReviewCard(context),
                const SizedBox(height: 24),
                _buildFooter(context),
              ],
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
        Expanded(
          child: AppText(
            "Connected Devices",
            fontSize: 18,
            fontWeight: FontWeight.w700,
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          height: 34,
          width: 34,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.person_rounded, color: AppColors.whiteColor, size: 18),
        ),
      ],
    );
  }

  // ==================== HERO ICON ====================
  Widget _buildHeroIcon(BuildContext context) {
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            height: 100,
            width: 100,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.warningColor.withOpacity(.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.phone_iphone_rounded,
              size: 44,
              color: AppColors.warningColor,
            ),
          ),
          Positioned(
            bottom: 2,
            right: 2,
            child: Container(
              height: 26,
              width: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withOpacity(.08),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.priority_high_rounded,
                size: 15,
                color: AppColors.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DEVICE COMPARE CARD ====================
  Widget _buildDeviceCompareCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Column(
        children: [
          _buildDeviceRow(
            iconBg: AppColors.primaryLight,
            icon: Icons.phone_iphone_rounded,
            iconColor: AppColors.primaryColor,
            label: "REGISTERED DEVICE",
            labelColor: AppColors.labelTextColor,
            name: _registeredDeviceName,
            info: _registeredDeviceInfo,
            statusLabel: "Active",
            statusColor: AppColors.successColor,
            statusIcon: Icons.circle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(child: Divider(color: AppColors.dividerColor)),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  height: 28,
                  width: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.fieldFillColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.swap_vert_rounded,
                    size: 15,
                    color: AppColors.labelTextColor,
                  ),
                ),
                Expanded(child: Divider(color: AppColors.dividerColor)),
              ],
            ),
          ),
          _buildDeviceRow(
            iconBg: AppColors.warningColor.withOpacity(.12),
            icon: Icons.phone_android_rounded,
            iconColor: AppColors.warningColor,
            label: "THIS DEVICE (NEW)",
            labelColor: AppColors.warningColor,
            name: _newDeviceName,
            info: _newDeviceInfo,
            statusLabel: "Pending",
            statusColor: AppColors.warningColor,
            statusIcon: Icons.access_time_rounded,
            showNewDot: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceRow({
    required Color iconBg,
    required IconData icon,
    required Color iconColor,
    required String label,
    required Color labelColor,
    required String name,
    required String info,
    required String statusLabel,
    required Color statusColor,
    required IconData statusIcon,
    bool showNewDot = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 42,
              width: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            if (showNewDot)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  height: 9,
                  width: 9,
                  decoration: BoxDecoration(
                    color: AppColors.warningColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteColor, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                label,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: .6,
                color: labelColor,
              ),
              const SizedBox(height: 3),
              AppText(name, fontSize: 15, fontWeight: FontWeight.w700),
              const SizedBox(height: 2),
              CaptionText(info),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, size: statusIcon == Icons.circle ? 7 : 12, color: statusColor),
              const SizedBox(width: 4),
              AppText(statusLabel, fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== REASON ====================
  Widget _buildReasonLabel(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppText("Reason for change", fontSize: 14, fontWeight: FontWeight.w700),
            const SizedBox(width: 4),
            CaptionText("(optional)"),
          ],
        ),
        CaptionText("${_reasonController.text.length}/$_maxReasonLength"),
      ],
    );
  }

  Widget _buildReasonField(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: TextField(
        controller: _reasonController,
        maxLength: _maxReasonLength,
        maxLines: 3,
        style: const TextStyle(fontFamily: "Poppins", fontSize: 14, color: AppColors.headlineTextColor),
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(14),
          hintText: "e.g. Lost old phone, upgraded to a new model, or\nloaner handset...",
          hintStyle: TextStyle(fontFamily: "Poppins", fontSize: 13, color: AppColors.placeholderColor),
        ),
      ),
    );
  }

  Widget _buildQuickReasonChips(BuildContext context) {
    final icons = {
      "Upgraded device": Icons.phone_iphone_rounded,
      "Old phone damaged": Icons.warning_amber_rounded,
      "Lost old device": Icons.sync_alt_rounded,
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _quickReasons.map((label) {
          final bool selected = _selectedQuickReason == label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => setState(() {
                _selectedQuickReason = label;
                _reasonController.text = label;
                _reasonController.selection = TextSelection.collapsed(offset: label.length);
              }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : AppColors.fieldFillColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icons[label],
                      size: 13,
                      color: selected ? AppColors.whiteColor : AppColors.labelTextColor,
                    ),
                    const SizedBox(width: 6),
                    AppText(
                      label,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? AppColors.whiteColor : AppColors.bodyTextColor,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== SUBMIT ====================
  Widget _buildSubmitButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: () {
        // TODO: DeviceViewModel.submitChangeRequest(context, reason: _reasonController.text)
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryColor.withOpacity(.35),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.send_rounded, size: 18, color: AppColors.whiteColor),
            const SizedBox(width: 10),
            AppText(
              "Submit Request",
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.whiteColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusLink(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: () => setState(() => _reviewExpanded = !_reviewExpanded),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_rounded, size: 15, color: AppColors.primaryColor),
            const SizedBox(width: 6),
            AppText(
              "Check Request Status & Timeline",
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== REVIEW STATUS CARD ====================
  Widget _buildReviewCard(BuildContext context) {
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
          InkWell(
            onTap: () => setState(() => _reviewExpanded = !_reviewExpanded),
            child: Row(
              children: [
                Container(
                  height: 40,
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.pending_actions_rounded, size: 19, color: AppColors.warningColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText("Review in Progress", fontSize: 15, fontWeight: FontWeight.w700),
                      const SizedBox(height: 2),
                      CaptionText(_refId),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.warningColor.withOpacity(.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: AppText(
                    _queueLabel,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warningColor,
                  ),
                ),
                const SizedBox(width: 4),
                AnimatedRotation(
                  turns: _reviewExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.labelTextColor),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState: _reviewExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.fieldFillColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildTimelineRow("Submitted", _submittedAt),
                      const SizedBox(height: 8),
                      _buildTimelineRow("Estimated Response", _etaLabel, valueColor: AppColors.primaryColor),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 16, color: AppColors.infoColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        _approverNote,
                        fontSize: 12,
                        color: AppColors.bodyTextColor,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () {
                          // TODO: open IT desk chat / call
                        },
                        child: Container(
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.fieldFillColor,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.bodyTextColor),
                              const SizedBox(width: 8),
                              AppText(
                                "Contact IT Desk",
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.bodyTextColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        // TODO: refresh request status from API
                      },
                      child: Container(
                        height: 46,
                        width: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.fieldFillColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.refresh_rounded, size: 19, color: AppColors.bodyTextColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        CaptionText(label),
        AppText(
          value,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: valueColor ?? AppColors.headlineTextColor,
        ),
      ],
    );
  }

  // ==================== FOOTER ====================
  Widget _buildFooter(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.shield_outlined, size: 13, color: AppColors.placeholderColor),
            const SizedBox(width: 6),
            AppText(
              "HARDWARE-BACKED ZERO-TRUST POLICY",
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: .8,
              color: AppColors.placeholderColor,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppText(
          "AttendEase Enterprise binds your cryptographic key to ensure "
              "authentic, tamper-proof attendance logs.",
          fontSize: 11,
          color: AppColors.placeholderColor,
          textAlign: TextAlign.center,
          height: 1.4,
        ),
      ],
    );
  }
}