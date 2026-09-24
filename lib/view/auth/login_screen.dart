import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/failure.dart';
import '../../core/routes/route_name.dart';
import '../../model/login_response_model.dart';
import '../../services/device_info_service.dart';
import '../../utils/app_utils.dart';
import '../../utils/validators.dart';
import '../../viewmodel/auth_viewmodel.dart';
import '../../widget/app_button.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';
import '../../widget/app_textfield.dart';


class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _buildingDeviceInfo = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    AppUtils.hideKeyboard(context);

    setState(() => _buildingDeviceInfo = true);
    final device = await DeviceInfoService().buildDeviceModel();
    if (!mounted) return;
    setState(() => _buildingDeviceInfo = false);

    final success = await ref.read(authViewModelProvider.notifier).login(
      loginId: _employeeIdController.text.trim(),
      password: _passwordController.text,
      device: device,
    );

    if (!mounted || !success) return;

    final loginResponse = ref.read(authViewModelProvider).value;
    final deviceStatus = loginResponse?.deviceStatus.toUpperCase() ?? "ACTIVE";

    if (deviceStatus == "PENDING") {
      // Same device rules as Profile's "Request Change" flow — a
      // pending device request blocks the dashboard until approved.
      Navigator.of(context).pushReplacementNamed(RouteNames.deviceChangeRequest);
    } else {
      Navigator.of(context).pushReplacementNamed(RouteNames.bottombar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerIconSize = size.width * 0.2 > 92 ? 92.0 : size.width * 0.2;

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading || _buildingDeviceInfo;

    // Any login failure shows via the app's shared snackbar helper —
    // same look everywhere else in the app uses AppUtils.showErrorSnackbar.
    ref.listen<AsyncValue<LoginResponseModel?>>(authViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is Failure ? error.message : "Something went wrong. Please try again.";
          AppUtils.showErrorSnackbar(context, message);
        },
      );
    });

    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: topPadding + 280,
            decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
          ),
          SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: size.height),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _Header(topPadding: topPadding, iconSize: headerIconSize),
                      Transform.translate(
                        offset: const Offset(0, -40),
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            color: AppColors.whiteColor,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: const [
                                    HeadlineText("Welcome Back", fontSize: 24),
                                    _GeofenceBadge(),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                const CaptionText("Sign in to mark your daily attendance"),
                                const SizedBox(height: 24),
                                const AppText(
                                  "Employee ID or Work Email",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _employeeIdController,
                                  hintText: "EMP-48209",
                                  keyboardType: TextInputType.text,
                                  enabled: !isLoading,
                                  prefixIcon: const Icon(
                                    Icons.badge_outlined,
                                    color: AppColors.labelTextColor,
                                  ),
                                  suffixIcon: ValueListenableBuilder(
                                    valueListenable: _employeeIdController,
                                    builder: (context, value, _) {
                                      if (value.text.trim().isEmpty) return const SizedBox.shrink();
                                      return const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.successColor,
                                        size: 20,
                                      );
                                    },
                                  ),
                                  validator: Validators.employeeIdOrEmail,
                                ),
                                const SizedBox(height: 18),
                                const AppText(
                                  "Master Password",
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                const SizedBox(height: 8),
                                AppTextField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  enabled: !isLoading,
                                  prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppColors.labelTextColor,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      color: AppColors.labelTextColor,
                                    ),
                                    onPressed: () =>
                                        setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: Validators.password,
                                ),
                                const SizedBox(height: 20),
                                AppButton(
                                  text: "Clock In / Login",
                                  icon: Icons.fingerprint_rounded,
                                  loading: isLoading,
                                  onTap: isLoading ? null : _handleLogin,
                                ),
                                const SizedBox(height: 22),
                                const _InfoBanner(
                                  text: "This handset will be bound to your biometrics profile",
                                ),
                                const SizedBox(height: 20),
                                Center(
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(
                                            Icons.support_agent_rounded,
                                            size: 15,
                                            color: AppColors.labelTextColor,
                                          ),
                                          SizedBox(width: 6),
                                          CaptionText(
                                            "Contact IT Helpdesk if unable to sign in",
                                            color: AppColors.labelTextColor,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      const CaptionText(
                                        "256-bit Hardware-Backed Security • v2.4.0",
                                        color: AppColors.placeholderColor,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final double topPadding;
  final double iconSize;

  const _Header({required this.topPadding, required this.iconSize});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(top: topPadding + 30, bottom: 80),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: iconSize,
                width: iconSize,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryColor.withOpacity(.9), AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(iconSize * 0.26),
                  border: Border.all(color: AppColors.whiteColor.withOpacity(.3)),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: AppColors.whiteColor,
                  size: iconSize * 0.48,
                ),
              ),
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  height: 15,
                  width: 15,
                  decoration: BoxDecoration(
                    color: AppColors.workingColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteColor, width: 2.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const AppText(
            "AttendEase",
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: AppColors.whiteColor,
          ),
          const SizedBox(height: 4),
          AppText(
            "SMART EMPLOYEE ATTENDANCE",
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.6,
            color: AppColors.whiteColor.withOpacity(.75),
          ),
        ],
      ),
    );
  }
}

class _GeofenceBadge extends StatelessWidget {
  const _GeofenceBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(color: AppColors.successColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const AppText(
            "Geofence Active",
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.successColor,
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final String text;
  const _InfoBanner({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.phonelink_lock_outlined, size: 16, color: AppColors.labelTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: AppText(
              text,
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.labelTextColor,
            ),
          ),
        ],
      ),
    );
  }
}