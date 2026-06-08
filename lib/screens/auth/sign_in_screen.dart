import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/app_state_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_text_field.dart';

final _failedAttemptsProvider = StateProvider<int>((ref) => 0);

class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email address');
      return;
    }
    if (password.isEmpty) {
      setState(() => _passwordError = 'Enter your password');
      return;
    }

    setState(() => _isLoading = true);
    // TODO(backend): Call Supabase signIn with email/password
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() => _isLoading = false);

    // Mock: always succeed on first try, simulate failure tracking
    final isMockSuccess = password.length >= 4;
    if (isMockSuccess) {
      ref.read(_failedAttemptsProvider.notifier).state = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_email', email);
      await ref.read(appStateProvider.notifier).setSessionActive(true);
      if (!mounted) return;
      context.go('/home/dashboard');
    } else {
      ref.read(_failedAttemptsProvider.notifier).state++;
      setState(() => _passwordError = 'Incorrect email or password');
    }
  }

  @override
  Widget build(BuildContext context) {
    final failedAttempts = ref.watch(_failedAttemptsProvider);
    final showForgotProminent = failedAttempts >= 3;

    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const CandleIcon(size: 40),
              const SizedBox(height: 8),
              Text('Welcome back.', style: AppTextStyles.displayH1),
              const SizedBox(height: 6),
              Text(
                'Sign in to continue your journey.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LuminaryTextField(
                label: 'EMAIL ADDRESS',
                hint: 'Your email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              LuminaryTextField(
                label: 'PASSWORD',
                hint: 'Your password',
                controller: _passwordController,
                obscureText: true,
                errorText: _passwordError,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => context.push('/password-reset'),
                  child: Text(
                    'Forgot password?',
                    style: AppTextStyles.caption.copyWith(
                      color: showForgotProminent
                          ? AppColors.dustyRose
                          : AppColors.warmAmber,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              LuminaryButton(
                label: 'Sign in',
                onTap: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.go('/sign-up'),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: "New to Luminary? "),
                      TextSpan(
                        text: 'Create an account',
                        style: TextStyle(
                          color: AppColors.warmAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
