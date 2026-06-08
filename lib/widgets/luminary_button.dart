import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';
import '../theme/app_text_styles.dart';

enum LuminaryButtonStyle { primary, purple, green, danger, ghost }

class LuminaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final LuminaryButtonStyle style;
  final bool isLoading;
  final double? width;

  const LuminaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = LuminaryButtonStyle.primary,
    this.isLoading = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = _config(style);
    return SizedBox(
      width: width ?? double.infinity,
      height: AppDimensions.buttonHeight,
      child: GestureDetector(
        onTap: isLoading || onTap == null
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap!();
              },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgWhite,
            borderRadius: BorderRadius.circular(AppDimensions.buttonRadius),
            border: Border.all(
              color: cfg.borderColor,
              width: style == LuminaryButtonStyle.ghost ? 1.5 : 2.5,
            ),
            boxShadow: cfg.shadow != null
                ? [
                    BoxShadow(
                      color: cfg.shadow!,
                      offset: AppDimensions.neoShadowOffset,
                      blurRadius: AppDimensions.neoShadowBlur,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: AppColors.warmAmber,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.buttonLabel.copyWith(
                      color: cfg.textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  _ButtonConfig _config(LuminaryButtonStyle s) {
    return switch (s) {
      LuminaryButtonStyle.primary => _ButtonConfig(
          borderColor: AppColors.warmAmber,
          shadow: AppColors.warmAmber,
          textColor: AppColors.textPrimary,
        ),
      LuminaryButtonStyle.purple => _ButtonConfig(
          borderColor: AppColors.softPurple,
          shadow: AppColors.softPurple,
          textColor: AppColors.textPrimary,
        ),
      LuminaryButtonStyle.green => _ButtonConfig(
          borderColor: AppColors.sageGreen,
          shadow: AppColors.sageGreen,
          textColor: AppColors.textPrimary,
        ),
      LuminaryButtonStyle.danger => _ButtonConfig(
          borderColor: AppColors.dustyRose,
          shadow: AppColors.dustyRose,
          textColor: AppColors.dustyRose,
        ),
      LuminaryButtonStyle.ghost => _ButtonConfig(
          borderColor: AppColors.divider,
          shadow: null,
          textColor: AppColors.textTertiary,
        ),
    };
  }
}

class _ButtonConfig {
  final Color borderColor;
  final Color? shadow;
  final Color textColor;
  const _ButtonConfig({
    required this.borderColor,
    required this.shadow,
    required this.textColor,
  });
}
