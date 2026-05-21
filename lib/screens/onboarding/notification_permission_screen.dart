import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/loss_profile_provider.dart';
import '../../providers/notification_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';

class NotificationPermissionScreen extends ConsumerWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(lossProfileProvider);
    final name = profile?.deceasedName ?? 'your loved one';

    return Scaffold(
      backgroundColor: AppColors.bgWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CandleIcon(size: 64),
              const SizedBox(height: 36),
              Text(
                'Let me reach out\non the hard days.',
                style: AppTextStyles.displayH1.copyWith(height: 1.3),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Text(
                "Grief has a rhythm. Luminary can reach out before $name's birthday, on anniversaries, and on your hardest days.",
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              Text(
                'You choose exactly which notifications you receive — always.',
                style: AppTextStyles.bodyLarge.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 44),
              LuminaryButton(
                label: 'Allow Luminary to reach out',
                onTap: () async {
                  await ref.read(notificationProvider.notifier).requestPermission();
                  if (context.mounted) context.go('/home/dashboard');
                },
              ),
              const SizedBox(height: 12),
              LuminaryButton(
                label: "Not now — I'll turn on later",
                onTap: () => context.go('/home/dashboard'),
                style: LuminaryButtonStyle.ghost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
