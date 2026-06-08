import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import 'candle_icon.dart';

class HardDateBanner extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const HardDateBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title — $subtitle',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.purpleTint,
            borderRadius: BorderRadius.circular(14),
            border: Border(
              left: BorderSide(color: AppColors.softPurple, width: 4),
            ),
          ),
          child: Row(
            children: [
              const CandleIcon(size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2C2B4A),
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppTextStyles.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
