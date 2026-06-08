import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/candle_icon.dart';
import '../../widgets/luminary_button.dart';
import '../../widgets/luminary_text_field.dart';

class PasswordResetScreen extends StatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  State<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends State<PasswordResetScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _emailError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _emailError = null);
    final email = _emailController.text.trim();

    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() => _emailError = 'Enter a valid email address');
      return;
    }

    setState(() => _isLoading = true);
    // TODO(backend): Call Supabase resetPasswordForEmail
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgGray,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: _isSuccess ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const CandleIcon(size: 40),
        const SizedBox(height: 8),
        Text('Reset your password', style: AppTextStyles.displayH1),
        const SizedBox(height: 6),
        Text(
          "Enter the email address on your account and we'll send a reset link.",
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
        const SizedBox(height: 8),
        LuminaryButton(
          label: 'Send reset link',
          onTap: _submit,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 14),
        LuminaryButton(
          label: 'Back to sign in',
          onTap: () => context.pop(),
          style: LuminaryButtonStyle.ghost,
        ),
      ],
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        const CandleIcon(size: 48),
        const SizedBox(height: 24),
        Text(
          'Check your email.',
          style: AppTextStyles.displayH1,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Text(
          'A reset link is on its way.',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
