enum NotificationCategory {
  all('All'),
  quota('Quota & Claims'),
  maintenance('Maintenance'),
  system('System');

  final String label;
  const NotificationCategory(this.label);
}

enum NotificationPriority {
  low,
  normal,
  high,
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String timestamp;
  final NotificationCategory category;
  final NotificationPriority priority;
  final bool isRead;
  final String? actionLabel;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.category,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.actionLabel,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      timestamp: timestamp,
      category: category,
      priority: priority,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel,
    );
  }

  static List<NotificationModel> dummyList = const [
    NotificationModel(
      id: 'NOTIF-1',
      title: '78% Monthly Allowance Consumed',
      message: 'Quota remaining: 550 L before monthly quota resets on 1 Nov 2026.',
      timestamp: '15 mins ago',
      category: NotificationCategory.quota,
      priority: NotificationPriority.high,
      isRead: false,
    ),
    NotificationModel(
      id: 'NOTIF-2',
      title: 'Claim #40921 Approved',
      message: 'Claim for 280.5 L at Shell Rawang has been verified and processed by Dispatch.',
      timestamp: '2 hours ago',
      category: NotificationCategory.quota,
      priority: NotificationPriority.normal,
      isRead: true,
      actionLabel: 'View Claim',
    ),
    NotificationModel(
      id: 'NOTIF-3',
      title: 'Odometer Rescan Requested',
      message: 'Blurry photo detected for Claim #40918. Please upload a clear photo of the dashboard meter.',
      timestamp: 'Yesterday',
      category: NotificationCategory.quota,
      priority: NotificationPriority.high,
      isRead: false,
      actionLabel: 'Update Photo',
    ),
    NotificationModel(
      id: 'NOTIF-4',
      title: 'Routine Lorry Inspection Due',
      message: 'Lorry JDT 1111 quarterly mechanical inspection is scheduled for 25 Oct at Pasir Gudang Depot #2.',
      timestamp: '2 days ago',
      category: NotificationCategory.maintenance,
      priority: NotificationPriority.normal,
      isRead: true,
    ),
  ];
}
