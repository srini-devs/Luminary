import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimensions.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _version = '1.0.0 (1)';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  _CircleBtn(
                    onTap: () => context.pop(),
                    child: const Text('‹',
                        style: TextStyle(
                            fontSize: 22,
                            color: AppColors.textSecondary)),
                  ),
                  Expanded(
                    child: Text('About Luminary',
                        style: AppTextStyles.screenTitle,
                        textAlign: TextAlign.center),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Semantics(
                        label: 'Luminary candle',
                        child: CandleIcon(size: 72),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Luminary',
                        style: AppTextStyles.displayH1
                            .copyWith(fontSize: 36),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You are not alone in this.',
                        style: AppTextStyles.bodyMedium
                            .copyWith(
                                color:
                                    AppColors.textSecondary,
                                fontStyle:
                                    FontStyle.italic),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgWhite,
                          borderRadius:
                              BorderRadius.circular(
                                  AppDimensions.cardRadius),
                          border: Border.all(
                              color: AppColors.cardBorder,
                              width: 2),
                        ),
                        child: Column(
                          children: [
                            _AboutRow(
                              label: 'Version',
                              value: _version,
                            ),
                            const Divider(
                                height: 1,
                                color: Color(0xFFF0F0F0)),
                            Semantics(
                              label: 'Privacy Policy',
                              button: true,
                              child: _AboutRow(
                                label: 'Privacy Policy',
                                isLink: true,
                                onTap: () {
                                  // TODO(backend): url_launcher → launch privacy policy URL
                                },
                              ),
                            ),
                            const Divider(
                                height: 1,
                                color: Color(0xFFF0F0F0)),
                            Semantics(
                              label: 'Terms of Service',
                              button: true,
                              child: _AboutRow(
                                label: 'Terms of Service',
                                isLink: true,
                                onTap: () {
                                  // TODO(backend): url_launcher → launch terms URL
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        '© 2025 Luminary. Made with care.',
                        style: AppTextStyles.caption,
                        textAlign: TextAlign.center,
                      ),
                    ],
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

class _AboutRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLink;
  final VoidCallback? onTap;

  const _AboutRow({
    required this.label,
    this.value,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isLink
                      ? AppColors.warmAmber
                      : AppColors.textPrimary,
                )),
            if (value != null)
              Text(value!,
                  style: AppTextStyles.caption)
            else if (isLink)
              const Icon(Icons.open_in_new,
                  size: 16,
                  color: AppColors.warmAmber),
          ],
        ),
      ),
    );
  }
}

class _CircleBtn extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const _CircleBtn({required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.bgGray,
          shape: BoxShape.circle,
          border: Border.all(
              color: AppColors.divider, width: 1.5),
        ),
        child: Center(child: child),
      ),
    );
  }
}
