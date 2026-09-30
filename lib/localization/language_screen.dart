import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../localization/language_model.dart';
import '../../utils/app_topbar.dart';
import '../../widget/app_colors.dart';
import '../../widget/app_text.dart';
import 'lanaguge_provider.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(languageProvider);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Normal app bar ----
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: hPad - 6),
                  child: AppTopBar(title: 'common.language'.tr()),
                ),

                // ---- Subtitle (app bar ke niche) ----
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(hPad, 6, hPad, 4),
                  child: CaptionText('language.subtitle'.tr()),
                ),

                // ---- Language list ----
                Expanded(
                  child: ListView(
                    padding: EdgeInsetsDirectional.fromSTEB(hPad, 14, hPad, 24),
                    children: [
                      ...LanguageModel.all.map(
                            (lang) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _LanguageTile(
                            lang: lang,
                            selected: lang.code == current.code,
                            onTap: () => _onSelect(context, ref, lang, current),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      _InfoNote(text: 'language.note'.tr()),
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

  Future<void> _onSelect(
      BuildContext context,
      WidgetRef ref,
      LanguageModel lang,
      LanguageModel current,
      ) async {
    if (lang.code == current.code) return;
    HapticFeedback.selectionClick();
    await ref.read(languageProvider.notifier).change(context, lang);
  }
}

// ==================== LANGUAGE TILE ====================
class _LanguageTile extends StatelessWidget {
  final LanguageModel lang;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.lang,
    required this.selected,
    required this.onTap,
  });

  String _englishLabel() {
    switch (lang.code) {
      case 'hi':
        return 'language.hindi'.tr();
      case 'ur':
        return 'language.urdu'.tr();
      default:
        return 'language.english'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryLight : AppColors.cardBgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primaryColor : AppColors.borderColor,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              // Language code avatar
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                height: 42,
                width: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected ? AppColors.primaryColor : AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: AppText(
                    lang.code.toUpperCase(),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? AppColors.whiteColor : AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Native name + translated name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      lang.name,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    CaptionText(_englishLabel()),
                  ],
                ),
              ),

              // Check indicator
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                child: selected
                    ? Container(
                  key: const ValueKey('on'),
                  height: 24,
                  width: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 16, color: AppColors.whiteColor),
                )
                    : Container(
                  key: const ValueKey('off'),
                  height: 24,
                  width: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderColor, width: 1.5),
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

// ==================== INFO NOTE ====================
class _InfoNote extends StatelessWidget {
  final String text;
  const _InfoNote({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 1),
          child: Icon(Icons.info_outline_rounded, size: 14, color: AppColors.labelTextColor),
        ),
        const SizedBox(width: 7),
        Expanded(child: CaptionText(text)),
      ],
    );
  }
}