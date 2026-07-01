import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';

class _EmergencyNumber {
  final String label;
  final String number;
  final IconData icon;
  const _EmergencyNumber(this.label, this.number, this.icon);
}

const _nationalNumbers = [
  _EmergencyNumber('National Emergency (Police/Fire/Ambulance)', '999', Icons.emergency_outlined),
  _EmergencyNumber('Tourist Police Helpline', '01320-110110', Icons.local_police_outlined),
  _EmergencyNumber('Fire Service', '199', Icons.local_fire_department_outlined),
  _EmergencyNumber('National Health Helpline', '16263', Icons.health_and_safety_outlined),
  _EmergencyNumber("Women & Children Helpline", '109', Icons.support_outlined),
];

const _safetyGuidelines = [
  'Keep a digital and printed copy of your ID/passport while traveling.',
  'Share your itinerary with a friend or family member.',
  'Avoid swimming alone in unmarked beach areas — currents can be strong.',
  'In the Chittagong Hill Tracts, travel with a registered guide and required permits.',
  'Use registered transport and tour operators, especially for boat trips.',
  'Keep emergency numbers saved and accessible even offline.',
];

const _womensSafetyTips = [
  "Use the Tourist Police helpline (01320-110110) if you feel unsafe.",
  'Prefer registered hotels and transport with reviews from other travelers.',
  'Dress modestly at religious and rural sites to minimize unwanted attention.',
  'Avoid traveling alone late at night in unfamiliar areas.',
];

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _SosButton(),
          const SizedBox(height: 28),
          Text('Emergency Contacts', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._nationalNumbers.map((n) => _ContactTile(entry: n)),

          const SizedBox(height: 24),
          Text("Women's Safety Tips", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _TipsCard(tips: _womensSafetyTips, color: AppColors.secondary),

          const SizedBox(height: 24),
          Text('Safety Guidelines', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _TipsCard(tips: _safetyGuidelines, color: AppColors.primary),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.offline_bolt_outlined, color: AppColors.accentDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Emergency contacts on this screen are cached and remain available even without an internet connection.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _SosButton extends StatelessWidget {
  const _SosButton();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse('tel:999')),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppColors.error.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Column(
          children: [
            const Icon(Icons.sos_rounded, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            const Text('SOS — Tap to Call 999', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 4),
            Text('Police · Fire · Ambulance', style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final _EmergencyNumber entry;
  const _ContactTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.error.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(entry.icon, color: AppColors.error, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entry.label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(entry.number, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () => launchUrl(Uri.parse('tel:${entry.number}')),
            icon: const Icon(Icons.call_outlined, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  final List<String> tips;
  final Color color;
  const _TipsCard({required this.tips, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: tips
            .map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.circle, size: 6, color: color).withTopPadding(),
                      const SizedBox(width: 10),
                      Expanded(child: Text(tip, style: Theme.of(context).textTheme.bodyMedium)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}

extension on Widget {
  Widget withTopPadding() => Padding(padding: const EdgeInsets.only(top: 6), child: this);
}
