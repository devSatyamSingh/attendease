import 'package:easy_localization/easy_localization.dart' hide TextDirection;
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

/// Version / number ka order Urdu me ulta na ho.
String _ltrIso(String s) => '\u2066$s\u2069';

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

    final success = await ref
        .read(authViewModelProvider.notifier)
        .login(
      loginId: _employeeIdController.text.trim(),
      password: _passwordController.text,
      device: device,
    );

    if (!mounted || !success) return;

    final loginResponse = ref.read(authViewModelProvider).value;
    final deviceStatus = loginResponse?.deviceStatus.toUpperCase() ?? "ACTIVE";

    if (deviceStatus == "PENDING") {
      Navigator.of(
        context,
      ).pushReplacementNamed(RouteNames.deviceChangeRequest);
    } else {
      Navigator.of(context).pushReplacementNamed(RouteNames.bottombar);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final headerIconSize = size.width * 0.14 > 60 ? 60.0 : size.width * 0.14;

    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading || _buildingDeviceInfo;

    ref.listen<AsyncValue<LoginResponseModel?>>(authViewModelProvider, (
        previous,
        next,
        ) {
      next.whenOrNull(
        error: (error, _) {
          final message = error is Failure
              ? error.message
              : 'errors.generic'.tr();
          AppUtils.showErrorSnackbar(context, message);
        },
      );
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,  // Android: white icons
        statusBarBrightness: Brightness.dark,       // iOS
      ),
      child: Scaffold(
        backgroundColor: AppColors.whiteColor,
        body: Stack(
          children: [
            Container(
              width: double.infinity,
              height: topPadding + 200,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _Header(topPadding: topPadding, iconSize: headerIconSize),
                        Transform.translate(
                          offset: const Offset(0, -28),
                          child: Container(
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              color: AppColors.whiteColor,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                            ),
                            padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: HeadlineText(
                                          'login.welcome_back'.tr(),
                                          fontSize: 18,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const _GeofenceBadge(),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  CaptionText('login.subtitle'.tr()),
                                  const SizedBox(height: 16),
                                  AppText(
                                    'login.work_email'.tr(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 6),

                                  // Email / employee ID hamesha LTR me type hota hai (Urdu me bhi)
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: AppTextField(
                                      controller: _employeeIdController,
                                      hintText: "EMP-48209",
                                      keyboardType: TextInputType.text,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.badge_outlined,
                                        size: 18,
                                        color: AppColors.labelTextColor,
                                      ),
                                      suffixIcon: ValueListenableBuilder(
                                        valueListenable: _employeeIdController,
                                        builder: (context, value, _) {
                                          if (value.text.trim().isEmpty) {
                                            return const SizedBox.shrink();
                                          }
                                          return const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.successColor,
                                            size: 17,
                                          );
                                        },
                                      ),
                                      validator: Validators.employeeIdOrEmail,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  AppText(
                                    'login.master_password'.tr(),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  const SizedBox(height: 6),

                                  // Password bhi LTR me
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: AppTextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      enabled: !isLoading,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        size: 18,
                                        color: AppColors.labelTextColor,
                                      ),
                                      suffixIcon: IconButton(
                                        padding: EdgeInsets.zero,
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          size: 18,
                                          color: AppColors.labelTextColor,
                                        ),
                                        onPressed: () => setState(
                                              () =>
                                          _obscurePassword = !_obscurePassword,
                                        ),
                                      ),
                                      validator: Validators.password,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  AppButton(
                                    text: 'login.btn_login'.tr(),
                                    icon: Icons.fingerprint_rounded,
                                    height: 50,
                                    loading: isLoading,
                                    onTap: isLoading ? null : _handleLogin,
                                  ),
                                  const SizedBox(height: 14),
                                  _InfoBanner(text: 'login.bind_info'.tr()),
                                  const SizedBox(height: 14),
                                  Center(
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.support_agent_rounded,
                                              size: 13,
                                              color: AppColors.labelTextColor,
                                            ),
                                            const SizedBox(width: 5),
                                            Flexible(
                                              child: CaptionText(
                                                'login.contact_it'.tr(),
                                                color: AppColors.labelTextColor,
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        CaptionText(
                                          'login.security_footer'.tr(
                                            args: [_ltrIso('v2.4.0')],
                                          ),
                                          color: AppColors.placeholderColor,
                                          textAlign: TextAlign.center,
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
      padding: EdgeInsets.only(top: topPadding + 18, bottom: 52),
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
                    colors: [
                      AppColors.primaryColor.withOpacity(.9),
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(iconSize * 0.26),
                  border: Border.all(
                    color: AppColors.whiteColor.withOpacity(.3),
                  ),
                ),
                child: Icon(
                  Icons.verified_rounded,
                  color: AppColors.whiteColor,
                  size: iconSize * 0.48,
                ),
              ),
              // RTL me green dot bhi side badal leta hai
              PositionedDirectional(
                top: -2,
                end: -2,
                child: Container(
                  height: 12,
                  width: 12,
                  decoration: BoxDecoration(
                    color: AppColors.workingColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.whiteColor, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Brand name translate nahi hota
          const AppText(
            "AttendEase",
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.whiteColor,
          ),
          const SizedBox(height: 2),
          AppText(
            'login.tagline'.tr(),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.whiteColor.withOpacity(.75),
            textAlign: TextAlign.center,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.successColor.withOpacity(.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 5,
            width: 5,
            decoration: const BoxDecoration(
              color: AppColors.successColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          AppText(
            'login.geofence_active'.tr(),
            fontSize: 10,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.fieldFillColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.phonelink_lock_outlined,
            size: 14,
            color: AppColors.labelTextColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: AppText(
              text,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: AppColors.labelTextColor,
            ),
          ),
        ],
      ),
    );
  }
}