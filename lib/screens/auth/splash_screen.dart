import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _showSpinner = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    if (!kDebugMode) {
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() => _showSpinner = true);
      });
    }
  }

  void _navigate(AppState state) {
    if (_navigated || !state.isLoaded || !mounted) return;
    _navigated = true;
    if (state.sessionActive && state.onboardingComplete) {
      GoRouter.of(context).go('/home/dashboard');
    } else if (state.sessionActive && !state.onboardingComplete) {
      GoRouter.of(context).go('/onboarding/welcome');
    } else {
      GoRouter.of(context).go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      ref.listen<AppState>(appStateProvider, (_, next) => _navigate(next));
      _navigate(ref.read(appStateProvider));
    }

    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.warmAmber.withAlpha(46),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.7],
                  ),
                ),
              ),
            ),
          ),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CandleIcon(size: 64),
                const SizedBox(height: 32),
                Text('Luminary', style: AppTextStyles.splashTitle),
                const SizedBox(height: 8),
                const Text(
                  'grief companion',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 32),
                if (!kDebugMode)
                  AnimatedOpacity(
                    opacity: _showSpinner ? 1 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: AppColors.warmAmber,
                        strokeWidth: 1.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (kDebugMode)
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LuminaryButton(
                    label: 'Continue →',
                    onTap: () =>
                        GoRouter.of(context).go('/onboarding/welcome'),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => GoRouter.of(context).push('/dev/screens'),
                    child: const Text(
                      'View All Screens',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF888888),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF888888),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
