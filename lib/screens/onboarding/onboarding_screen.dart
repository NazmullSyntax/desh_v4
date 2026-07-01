import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/constants/app_strings.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/common/primary_button.dart';

const _onboardingSeenKey = 'onboarding_seen';

class _OnboardPage {
  final String title;
  final String body;
  final IconData icon;
  final Gradient gradient;

  const _OnboardPage({required this.title, required this.body, required this.icon, required this.gradient});
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  final _pages = const [
    _OnboardPage(
      title: AppStrings.onboardTitle1,
      body: AppStrings.onboardBody1,
      icon: Icons.map_outlined,
      gradient: AppColors.primaryGradient,
    ),
    _OnboardPage(
      title: AppStrings.onboardTitle2,
      body: AppStrings.onboardBody2,
      icon: Icons.event_note_outlined,
      gradient: AppColors.skyGradient,
    ),
    _OnboardPage(
      title: AppStrings.onboardTitle3,
      body: AppStrings.onboardBody3,
      icon: Icons.shield_outlined,
      gradient: AppColors.sunsetGradient,
    ),
  ];

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_index == _pages.length - 1) {
      _finish();
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextButton(onPressed: _finish, child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) => _OnboardPageView(page: _pages[i]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: SmoothPageIndicator(
                controller: _controller,
                count: _pages.length,
                effect: const ExpandingDotsEffect(
                  activeDotColor: AppColors.primary,
                  dotColor: AppColors.borderLight,
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              child: PrimaryButton(
                label: _index == _pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: _next,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  const _OnboardPageView({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(gradient: page.gradient, shape: BoxShape.circle),
            child: Icon(page.icon, size: 84, color: Colors.white),
          ),
          const SizedBox(height: 40),
          Text(page.title, style: Theme.of(context).textTheme.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(
            page.body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
