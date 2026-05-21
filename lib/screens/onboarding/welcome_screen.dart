import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: Stack(
        children: [
          // Glow blob
          Positioned(
            top: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.warmAmber.withAlpha(23),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 52, 28, 36),
              child: Column(
                children: [
                  // Candle
                  const CandleIcon(size: 72),
                  const SizedBox(height: 48),
                  // Headline
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          "You don't have to face\nthe hardest days alone.",
                          style: AppTextStyles.displayH1.copyWith(height: 1.3),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'A compassionate companion for grief — private, gentle, always here.',
                          style: AppTextStyles.bodyLarge.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  // Buttons
                  Column(
                    children: [
                      LuminaryButton(
                        label: 'Begin',
                        onTap: () => context.go('/onboarding/who'),
                      ),
                      const SizedBox(height: 12),
                      LuminaryButton(
                        label: 'Maybe later',
                        onTap: () => context.go('/sign-up'),
                        style: LuminaryButtonStyle.ghost,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
