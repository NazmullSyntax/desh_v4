import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _language = 'English';
  bool _weatherAlerts = true;
  bool _bookingUpdates = true;
  bool _safetyAlerts = true;
  bool _travelReminders = true;
  bool _newDestinations = false;
  bool _locationSharing = true;
  bool _analytics = true;

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          _SettingsSection(
            title: 'Appearance',
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dark Mode'),
                subtitle: Text(themeMode == ThemeMode.system ? 'Following system setting' : (themeMode == ThemeMode.dark ? 'Enabled' : 'Disabled')),
                value: themeMode == ThemeMode.dark,
                activeColor: AppColors.primary,
                onChanged: (v) => ref.read(themeModeProvider.notifier).toggleDark(v),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Use System Theme'),
                trailing: Switch(
                  value: themeMode == ThemeMode.system,
                  activeColor: AppColors.primary,
                  onChanged: (v) => ref.read(themeModeProvider.notifier).setThemeMode(v ? ThemeMode.system : ThemeMode.light),
                ),
              ),
            ],
          ),

          _SettingsSection(
            title: 'Language',
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('App Language'),
                subtitle: Text(_language),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final selected = await showModalBottomSheet<String>(
                    context: context,
                    builder: (context) => _LanguageSheet(current: _language),
                  );
                  if (selected != null) setState(() => _language = selected);
                },
              ),
            ],
          ),

          _SettingsSection(
            title: 'Notifications',
            children: [
              _ToggleRow(label: 'Weather Alerts', value: _weatherAlerts, onChanged: (v) => setState(() => _weatherAlerts = v)),
              _ToggleRow(label: 'Booking Updates', value: _bookingUpdates, onChanged: (v) => setState(() => _bookingUpdates = v)),
              _ToggleRow(label: 'Safety Alerts', value: _safetyAlerts, onChanged: (v) => setState(() => _safetyAlerts = v)),
              _ToggleRow(label: 'Travel Reminders', value: _travelReminders, onChanged: (v) => setState(() => _travelReminders = v)),
              _ToggleRow(label: 'New Destinations', value: _newDestinations, onChanged: (v) => setState(() => _newDestinations = v)),
            ],
          ),

          _SettingsSection(
            title: 'Privacy',
            children: [
              _ToggleRow(label: 'Share Location for Nearby Suggestions', value: _locationSharing, onChanged: (v) => setState(() => _locationSharing = v)),
              _ToggleRow(label: 'Share Anonymous Usage Analytics', value: _analytics, onChanged: (v) => setState(() => _analytics = v)),
            ],
          ),

          _SettingsSection(
            title: 'Support',
            children: [
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.help_outline), title: const Text('Help Center'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.info_outline), title: const Text('About DeshExplorer'), trailing: const Icon(Icons.chevron_right), onTap: () => _showAbout(context)),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.privacy_tip_outlined), title: const Text('Privacy Policy'), trailing: const Icon(Icons.chevron_right), onTap: () {}),
            ],
          ),
          const SizedBox(height: 24),
          Center(child: Text('DeshExplorer v1.0.0', style: Theme.of(context).textTheme.bodySmall)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'DeshExplorer',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.travel_explore_rounded, color: AppColors.primary, size: 40),
      children: const [
        SizedBox(height: 12),
        Text('A smart travel guide and trip planner for exploring Bangladesh — built with Flutter.'),
      ],
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.primary)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label, style: Theme.of(context).textTheme.bodyMedium),
      value: value,
      activeColor: AppColors.primary,
      onChanged: onChanged,
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  final String current;
  const _LanguageSheet({required this.current});

  @override
  Widget build(BuildContext context) {
    const languages = ['English', 'বাংলা (Bangla)'];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Language', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            ...languages.map((lang) => RadioListTile<String>(
                  title: Text(lang),
                  value: lang,
                  groupValue: current,
                  activeColor: AppColors.primary,
                  onChanged: (v) => Navigator.of(context).pop(v),
                )),
          ],
        ),
      ),
    );
  }
}
