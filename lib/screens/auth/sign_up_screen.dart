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

class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;

  String? _emailError;
  String? _passwordError;
  String? _confirmError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validateEmail(String v) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v);
  }

  bool _validatePassword(String v) {
    return v.length >= 8 && RegExp(r'[0-9!@#\$%^&*]').hasMatch(v);
  }

  Future<void> _submit() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmError = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    bool valid = true;

    if (!_validateEmail(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      valid = false;
    }
    if (!_validatePassword(password)) {
      setState(() =>
          _passwordError = 'At least 8 characters with 1 number or symbol');
      valid = false;
    }
    if (password != confirm) {
      setState(() => _confirmError = 'Passwords do not match');
      valid = false;
    }

    if (!valid) return;

    setState(() => _isLoading = true);
    // TODO(backend): Call Supabase signUp with email/password
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() => _isLoading = false);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_email', email);
    await ref.read(appStateProvider.notifier).setSessionActive(true);
    if (!mounted) return;
    context.go('/onboarding/welcome');
  }

  @override
  Widget build(BuildContext context) {
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
              Text('Create your account', style: AppTextStyles.displayH1.copyWith(
                fontSize: 28,
                textBaseline: TextBaseline.alphabetic,
              )),
              const SizedBox(height: 6),
              Text(
                'Your information is private and secure.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              LuminaryTextField(
                label: 'EMAIL ADDRESS',
                hint: 'you@email.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                errorText: _emailError,
              ),
              LuminaryTextField(
                label: 'PASSWORD',
                hint: '8+ characters with a number or symbol',
                controller: _passwordController,
                obscureText: true,
                errorText: _passwordError,
              ),
              LuminaryTextField(
                label: 'CONFIRM PASSWORD',
                hint: 'Repeat your password',
                controller: _confirmController,
                obscureText: true,
                errorText: _confirmError,
              ),
              const SizedBox(height: 8),
              LuminaryButton(
                label: 'Create account',
                onTap: _submit,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 14),
              GestureDetector(
                onTap: () => context.go('/sign-in'),
                child: RichText(
                  text: TextSpan(
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    children: [
                      const TextSpan(text: 'Already have an account? '),
                      TextSpan(
                        text: 'Sign in',
                        style: TextStyle(
                          color: AppColors.warmAmber,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'By continuing you agree to our Terms of Service and Privacy Policy',
                style: AppTextStyles.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
