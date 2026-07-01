import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_text_field.dart';
import '../../widgets/common/primary_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.sendPasswordReset(_emailController.text.trim());
    if (success && mounted) {
      setState(() => _emailSent = true);
    } else if (mounted) {
      final error = ref.read(authControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error?.toString() ?? AppStrings.genericError), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authControllerProvider).isLoading;

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
          child: _emailSent ? _buildSentState(context) : _buildFormState(context, isLoading),
        ),
      ),
    );
  }

  Widget _buildFormState(BuildContext context, bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.12), borderRadius: BorderRadius.circular(18)),
            child: const Icon(Icons.lock_reset_outlined, color: AppColors.secondary, size: 32),
          ),
          const SizedBox(height: 24),
          Text(AppStrings.forgotPasswordTitle, style: Theme.of(context).textTheme.displayLarge),
          const SizedBox(height: 8),
          Text(AppStrings.forgotPasswordSubtitle, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 32),
          AppTextField(
            label: 'Email',
            controller: _emailController,
            hint: 'you@example.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email is required';
              if (!v.contains('@')) return 'Enter a valid email';
              return null;
            },
          ),
          const SizedBox(height: 28),
          PrimaryButton(label: 'Send Reset Link', onPressed: _submit, isLoading: isLoading),
        ],
      ),
    );
  }

  Widget _buildSentState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.12), shape: BoxShape.circle),
          child: const Icon(Icons.check_circle_outline, color: AppColors.success, size: 44),
        ),
        const SizedBox(height: 24),
        Text('Check your email', style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
        const SizedBox(height: 8),
        Text(
          "We've sent a password reset link to ${_emailController.text.trim()}",
          style: Theme.of(context).textTheme.bodyLarge,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        PrimaryButton(label: 'Back to Login', onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
