import 'package:flutter/material.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/theme/app_colors.dart';

enum NotificationType { weather, booking, safety, reminder, destination }

class _AppNotification {
  final NotificationType type;
  final String title;
  final String body;
  final String timeAgo;
  final bool isRead;

  const _AppNotification({
    required this.type,
    required this.title,
    required this.body,
    required this.timeAgo,
    this.isRead = false,
  });
}

const _notifications = [
  _AppNotification(
    type: NotificationType.weather,
    title: 'Weather Alert: Cox\'s Bazar',
    body: 'Light rain expected this evening — pack an umbrella for outdoor plans.',
    timeAgo: '2h ago',
  ),
  _AppNotification(
    type: NotificationType.reminder,
    title: 'Upcoming Trip Reminder',
    body: 'Your trip to Sreemangal starts in 3 days. Review your itinerary now.',
    timeAgo: '5h ago',
  ),
  _AppNotification(
    type: NotificationType.safety,
    title: 'Travel Advisory',
    body: 'Ferry services in the Sundarbans region may be affected by tidal conditions this week.',
    timeAgo: '1d ago',
    isRead: true,
  ),
  _AppNotification(
    type: NotificationType.destination,
    title: 'New Destination Added',
    body: 'Explore our newly added guide for Kuakata Beach in Barisal Division.',
    timeAgo: '2d ago',
    isRead: true,
  ),
  _AppNotification(
    type: NotificationType.booking,
    title: 'Booking Confirmed',
    body: 'Your stay at Sayeman Beach Resort is confirmed for your upcoming trip.',
    timeAgo: '3d ago',
    isRead: true,
  ),
];

IconData _iconFor(NotificationType type) {
  switch (type) {
    case NotificationType.weather:
      return Icons.cloud_outlined;
    case NotificationType.booking:
      return Icons.confirmation_number_outlined;
    case NotificationType.safety:
      return Icons.warning_amber_outlined;
    case NotificationType.reminder:
      return Icons.event_outlined;
    case NotificationType.destination:
      return Icons.explore_outlined;
  }
}

Color _colorFor(NotificationType type) {
  switch (type) {
    case NotificationType.weather:
      return AppColors.secondary;
    case NotificationType.booking:
      return AppColors.primary;
    case NotificationType.safety:
      return AppColors.error;
    case NotificationType.reminder:
      return AppColors.accentDark;
    case NotificationType.destination:
      return AppColors.primaryDark;
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [TextButton(onPressed: () {}, child: const Text('Mark all read'))],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        itemCount: _notifications.length,
        separatorBuilder: (context, i) => const SizedBox(height: 10),
        itemBuilder: (context, i) => _NotificationTile(notification: _notifications[i]),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final _AppNotification notification;
  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(notification.type);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: notification.isRead ? Theme.of(context).cardTheme.color : color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(_iconFor(notification.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(notification.title, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700))),
                    if (!notification.isRead)
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.body, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(notification.timeAgo, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
