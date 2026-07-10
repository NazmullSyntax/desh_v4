import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_auth_service.dart';
import '../../widgets/common/app_text_field.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AdminAuthService();
      await authService.loginAdmin(email: email, password: password);

      // FIX: Force Riverpod to clear cache and look for the new admin session immediately
      ref.invalidate(authStateProvider);
      await ref.read(authStateProvider.future);

      if (!mounted) return;
      context.go(AppRoutes.adminPanel);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createAdminAccount() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter name, email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final authService = AdminAuthService();
      await authService.registerAdmin(name: name, email: email, password: password);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Admin account created successfully! Please login.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString().replaceAll('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Login'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Admin Portal - Manage customer support messages and replies',
                      style: TextStyle(color: Colors.blue.shade700, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text('Admin Portal', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text('Log in to view and reply to customer messages', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 32),
            AppTextField(
              label: 'Full Name',
              controller: _nameController,
              hint: 'Support Admin',
              prefixIcon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              controller: _emailController,
              hint: 'admin@deshexplorer.com',
              prefixIcon: Icons.mail_outline,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Password',
              controller: _passwordController,
              hint: 'Enter your password',
              prefixIcon: Icons.lock_outline,
              obscureText: true,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _login,
                icon: const Icon(Icons.login),
                label: Text(_isLoading ? 'Logging in...' : 'Login as Admin'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.blue.shade600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isLoading ? null : _createAdminAccount,
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(_isLoading ? 'Creating account...' : 'Create Admin Account'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: Colors.blue.shade700,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create or use an admin account:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.amber.shade900, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text('1. Enter your name, email and password', style: TextStyle(fontSize: 13, color: Colors.amber.shade800)),
                  const SizedBox(height: 4),
                  Text('2. Tap “Create Admin Account” to register', style: TextStyle(fontSize: 13, color: Colors.amber.shade800)),
                  const SizedBox(height: 4),
                  Text('3. Then sign in with those same credentials', style: TextStyle(fontSize: 13, color: Colors.amber.shade800)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What You Can Do:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.green.shade900, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const _InfoRow(icon: Icons.mail, text: 'View all customer messages'),
                  const _InfoRow(icon: Icons.reply, text: 'Reply to customer inquiries'),
                  const _InfoRow(icon: Icons.check_circle, text: 'Mark tickets as resolved'),
                  const _InfoRow(icon: Icons.filter_alt, text: 'Filter and sort tickets'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.green.shade700),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 13, color: Colors.green.shade800))),
        ],
      ),
    );
  }
}