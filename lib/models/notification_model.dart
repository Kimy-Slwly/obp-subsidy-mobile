enum NotificationCategory {
  all('All'),
  quota('Quota & Claims'),
  maintenance('Maintenance'),
  system('System');

  final String label;
  const NotificationCategory(this.label);

  static NotificationCategory fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'maintenance':
        return NotificationCategory.maintenance;
      case 'system':
        return NotificationCategory.system;
      default:
        return NotificationCategory.quota;
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high;

  static NotificationPriority fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'high':
        return NotificationPriority.high;
      case 'low':
        return NotificationPriority.low;
      default:
        return NotificationPriority.normal;
    }
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final String type;
  final String? claimId;
  final NotificationCategory category;
  final NotificationPriority priority;
  final bool isRead;
  final String? actionLabel;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    this.type = 'claim_status',
    this.claimId,
    required this.category,
    this.priority = NotificationPriority.normal,
    this.isRead = false,
    this.actionLabel,
    required this.createdAt,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      type: type,
      claimId: claimId,
      category: category,
      priority: priority,
      isRead: isRead ?? this.isRead,
      actionLabel: actionLabel,
      createdAt: createdAt,
    );
  }

  factory NotificationModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime created;
    if (data['createdAt'] != null) {
      if (data['createdAt'] is DateTime) {
        created = data['createdAt'] as DateTime;
      } else if (data['createdAt'] is String) {
        created = DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
      } else {
        try {
          created = (data['createdAt'] as dynamic).toDate() as DateTime;
        } catch (_) {
          created = DateTime.now();
        }
      }
    } else {
      created = DateTime.now();
    }

    return NotificationModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      title: data['title'] as String? ?? 'Notification',
      message: data['message'] as String? ?? '',
      type: data['type'] as String? ?? 'system',
      claimId: data['claimId'] as String?,
      category: NotificationCategory.fromString(data['category'] as String?),
      priority: NotificationPriority.fromString(data['priority'] as String?),
      isRead: data['isRead'] as bool? ?? false,
      actionLabel: data['actionLabel'] as String?,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'message': message,
      'type': type,
      'claimId': claimId,
      'category': category.name,
      'priority': priority.name,
      'isRead': isRead,
      'actionLabel': actionLabel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static List<NotificationModel> dummyList = [
    NotificationModel(
      id: 'notif_1',
      userId: 'demo_driver_001',
      title: '78% Monthly Allowance Consumed',
      message: 'Quota remaining: 550 L before monthly quota resets on 1 Nov 2026.',
      type: 'quota_alert',
      category: NotificationCategory.quota,
      priority: NotificationPriority.high,
      isRead: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
    ),
    NotificationModel(
      id: 'notif_2',
      userId: 'demo_driver_001',
      title: 'Claim #40921 Approved',
      message: 'Claim for 280.5 L at Shell Rawang has been verified and processed by Dispatch.',
      type: 'claim_status',
      claimId: 'CLM-40921',
      category: NotificationCategory.quota,
      priority: NotificationPriority.normal,
      isRead: true,
      actionLabel: 'View Claim',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationModel(
      id: 'notif_3',
      userId: 'demo_driver_001',
      title: 'Odometer Rescan Requested',
      message: 'Blurry photo detected for Claim #40918. Please upload a clear photo of the dashboard meter.',
      type: 'claim_status',
      claimId: 'CLM-40918',
      category: NotificationCategory.quota,
      priority: NotificationPriority.high,
      isRead: false,
      actionLabel: 'Update Photo',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    NotificationModel(
      id: 'notif_4',
      userId: 'demo_driver_001',
      title: 'Routine Lorry Inspection Due',
      message: 'Lorry JDT 1111 quarterly mechanical inspection is scheduled for 25 Oct at Pasir Gudang Depot #2.',
      type: 'maintenance',
      category: NotificationCategory.maintenance,
      priority: NotificationPriority.normal,
      isRead: true,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];
}
