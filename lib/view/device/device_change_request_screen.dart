import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/errors/failure.dart';
import '../../model/active_device_model.dart';
import '../../model/device_change_request_model.dart';
import '../../model/device_model.dart';
import '../../model/device_status_model.dart';
import '../../services/device_info_service.dart';
import '../../utils/app_utils.dart';
import '../../viewmodel/device_viewmodel.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_loader.dart';
import '../../widget/app_text.dart';


class DeviceChangeRequestScreen extends ConsumerStatefulWidget {
  const DeviceChangeRequestScreen({super.key});

  @override
  ConsumerState<DeviceChangeRequestScreen> createState() => _DeviceChangeRequestScreenState();
}

class _DeviceChangeRequestScreenState extends ConsumerState<DeviceChangeRequestScreen> {
  static const _maxReasonLength = 140;
  static const _quickReasons = ["Upgraded device", "Old phone damaged", "Lost old device"];

  final TextEditingController _reasonController = TextEditingController();
  String? _selectedQuickReason;
  bool _reviewExpanded = true;

  DeviceModel? _thisDevice;
  bool _loadingThisDevice = true;

  @override
  void initState() {
    super.initState();
    _reasonController.addListener(() => setState(() {}));
    _loadThisDevice();
  }

  Future<void> _loadThisDevice() async {
    final device = await DeviceInfoService().buildDeviceModel();
    if (!mounted) return;
    setState(() {
      _thisDevice = device;
      _loadingThisDevice = false;
    });
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    final device = _thisDevice;
    if (device == null) return;

    final success = await ref.read(deviceViewModelProvider.notifier).requestChange(device);
    if (!mounted) return;

    if (success) {
      AppUtils.showSnackbar(context, "Request submitted — awaiting admin approval.");
      setState(() {
        _reasonController.clear();
        _selectedQuickReason = null;
        _reviewExpanded = true;
      });
    } else {
      final error = ref.read(deviceViewModelProvider).error;
      final message = error is Failure ? error.message : "Couldn't submit the request. Try again.";
      AppUtils.showErrorSnackbar(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(deviceViewModelProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBgColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: RefreshIndicator(
              color: AppColors.primaryColor,
              onRefresh: () => ref.read(deviceViewModelProvider.notifier).refresh(),
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
                    fontWeight: FontWeight.w500,
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
                  statusAsync.when(
                    loading: () => const _CompareCardSkeleton(),
                    error: (error, _) => _buildLoadErrorCard(error),
                    data: (status) => _buildBodyForStatus(context, status),
                  ),
                  const SizedBox(height: 24),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBodyForStatus(BuildContext context, DeviceStatusModel status) {
    final pending = status.pendingRequest;
    final bool hasBlockingPending = pending != null && pending.status.toUpperCase() == "PENDING";

    return Column(
      children: [
        _buildDeviceCompareCard(context, status.activeDevice),
        const SizedBox(height: 24),
        if (hasBlockingPending) ...[
          _buildAlreadyPendingBanner(),
          const SizedBox(height: 20),
        ] else ...[
          if (pending != null && pending.status.toUpperCase() == "REJECTED") ...[
            _buildRejectedBanner(pending),
            const SizedBox(height: 20),
          ],
          _buildReasonLabel(context),
          const SizedBox(height: 10),
          _buildReasonField(context),
          const SizedBox(height: 10),
          _buildQuickReasonChips(context),
          const SizedBox(height: 22),
          _buildSubmitButton(context),
          const SizedBox(height: 14),
        ],
        if (pending != null) ...[
          _buildStatusLink(context),
          const SizedBox(height: 20),
          _buildReviewCard(context, pending),
        ],
      ],
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
          decoration: const BoxDecoration(color: AppColors.primaryColor, shape: BoxShape.circle),
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
            decoration: BoxDecoration(color: AppColors.warningColor.withOpacity(.15), shape: BoxShape.circle),
            child: const Icon(Icons.phone_iphone_rounded, size: 44, color: AppColors.warningColor),
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
                boxShadow: [BoxShadow(color: AppColors.blackColor.withOpacity(.08), blurRadius: 6, offset: const Offset(0, 2))],
              ),
              child: const Icon(Icons.priority_high_rounded, size: 15, color: AppColors.warningColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadErrorCard(Object error) {
    final message = error is Failure ? error.message : "Couldn't load device status.";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: AppColors.errorColor),
          const SizedBox(width: 10),
          Expanded(child: AppText(message, fontSize: 13, color: AppColors.labelTextColor)),
          TextButton(
            onPressed: () => ref.read(deviceViewModelProvider.notifier).refresh(),
            child: const AppText("Retry", fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryColor),
          ),
        ],
      ),
    );
  }

  // ==================== "ALREADY PENDING" / "REJECTED" BANNERS ====================
  Widget _buildAlreadyPendingBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lock_clock_rounded, size: 18, color: AppColors.warningColor),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              "You already have a request awaiting admin approval. This "
                  "device stays locked until it's reviewed — check the status below.",
              fontSize: 12,
              color: AppColors.bodyTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRejectedBanner(DeviceChangeRequestModel pending) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.errorColor.withOpacity(.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cancel_outlined, size: 18, color: AppColors.errorColor),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              pending.rejectionReason == null || pending.rejectionReason!.isEmpty
                  ? "Your last request was rejected. You can submit a new one below."
                  : "Last request rejected: ${pending.rejectionReason}",
              fontSize: 12,
              color: AppColors.bodyTextColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== DEVICE COMPARE CARD ====================
  Widget _buildDeviceCompareCard(BuildContext context, ActiveDeviceModel? activeDevice) {
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
            name: activeDevice?.deviceModel ?? "No device registered yet",
            info: activeDevice == null
                ? "—"
                : "${activeDevice.platform}${activeDevice.lastLoginAt != null ? ' • Active ${_relativeLabel(activeDevice.lastLoginAt!)}' : ''}",
            statusLabel: activeDevice?.status ?? "—",
            statusColor: activeDevice == null
                ? AppColors.labelTextColor
                : AppColors.requestStatusColor(activeDevice.status),
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
                  decoration: const BoxDecoration(color: AppColors.fieldFillColor, shape: BoxShape.circle),
                  child: const Icon(Icons.swap_vert_rounded, size: 15, color: AppColors.labelTextColor),
                ),
                Expanded(child: Divider(color: AppColors.dividerColor)),
              ],
            ),
          ),
          _loadingThisDevice
              ? const _DeviceRowSkeleton()
              : _buildDeviceRow(
            iconBg: AppColors.warningColor.withOpacity(.12),
            icon: Icons.phone_android_rounded,
            iconColor: AppColors.warningColor,
            label: "THIS DEVICE (NEW)",
            labelColor: AppColors.warningColor,
            name: _thisDevice?.model ?? "Unknown device",
            info: "Detected: today • ${_thisDevice?.osVersion ?? ''}",
            statusLabel: "Pending",
            statusColor: AppColors.warningColor,
            statusIcon: Icons.access_time_rounded,
            showNewDot: true,
          ),
        ],
      ),
    );
  }

  String _relativeLabel(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return DateFormat("dd MMM").format(dateTime);
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
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
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
              AppText(label, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: .6, color: labelColor),
              const SizedBox(height: 3),
              AppText(name, fontSize: 15, fontWeight: FontWeight.w700, maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              CaptionText(info),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
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
                    Icon(icons[label], size: 13, color: selected ? AppColors.whiteColor : AppColors.labelTextColor),
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
    final isSubmitting = ref.watch(deviceViewModelProvider).isLoading;
    final bool canSubmit = !isSubmitting && !_loadingThisDevice && _thisDevice != null;

    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: canSubmit ? _submitRequest : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: AppColors.primaryColor.withOpacity(.35), blurRadius: 18, offset: const Offset(0, 10)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSubmitting)
              const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.whiteColor),
              )
            else
              const Icon(Icons.send_rounded, size: 18, color: AppColors.whiteColor),
            const SizedBox(width: 10),
            AppText(
              isSubmitting ? "Submitting..." : "Submit Request",
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

  // ==================== REVIEW STATUS CARD (real data) ====================
  Widget _buildReviewCard(BuildContext context, DeviceChangeRequestModel request) {
    final statusColor = AppColors.requestStatusColor(request.status);
    final refLabel = "Ref: REQ-${request.deviceChangeRequestId.toString().padLeft(5, '0')}";
    final submittedLabel = request.requestedAt == null
        ? "—"
        : DateFormat("dd MMM, hh:mm a").format(request.requestedAt!);

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
                  decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(12)),
                  child: Icon(Icons.pending_actions_rounded, size: 19, color: statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        request.status.toUpperCase() == "PENDING" ? "Review in Progress" : "Request History",
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      const SizedBox(height: 2),
                      CaptionText(refLabel),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(.12), borderRadius: BorderRadius.circular(20)),
                  child: AppText(request.status, fontSize: 11, fontWeight: FontWeight.w700, color: statusColor),
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
                  decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    children: [
                      _buildTimelineRow("Submitted", submittedLabel),
                      if (request.status.toUpperCase() == "PENDING") ...[
                        const SizedBox(height: 8),
                        _buildTimelineRow("Status", "Awaiting admin review", valueColor: AppColors.primaryColor),
                      ],
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
                        "This device stays locked out of the dashboard until an "
                            "admin approves this request. Once approved, your other "
                            "signed-in device will be logged out automatically.",
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
                          decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(14)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.support_agent_rounded, size: 16, color: AppColors.bodyTextColor),
                              const SizedBox(width: 8),
                              AppText("Contact IT Desk", fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.bodyTextColor),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => ref.read(deviceViewModelProvider.notifier).refresh(),
                      child: Container(
                        height: 46,
                        width: 46,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(color: AppColors.fieldFillColor, borderRadius: BorderRadius.circular(14)),
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
        AppText(value, fontSize: 13, fontWeight: FontWeight.w700, color: valueColor ?? AppColors.headlineTextColor),
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

// ==================== SKELETONS ====================
class _CompareCardSkeleton extends StatelessWidget {
  const _CompareCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderColor),
      ),
      child: const Column(
        children: [
          _DeviceRowSkeleton(),
          SizedBox(height: 20),
          _DeviceRowSkeleton(),
        ],
      ),
    );
  }
}

class _DeviceRowSkeleton extends StatelessWidget {
  const _DeviceRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        AppSkeletonBox(height: 42, width: 42, borderRadius: 12),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSkeletonBox(height: 9, width: 100, borderRadius: 6),
              const SizedBox(height: 8),
              AppSkeletonBox(height: 14, width: 150, borderRadius: 6),
              const SizedBox(height: 6),
              AppSkeletonBox(height: 10, width: 120, borderRadius: 6),
            ],
          ),
        ),
      ],
    );
  }
}