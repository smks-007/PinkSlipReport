/// Model representing an official department broadcast notice and notification
class DepartmentNoticeModel {
  final String id;
  final String title;
  final String message;
  final String targetAudience;
  final String priority;
  final String templateType;
  final String senderName;
  final bool isRead;
  final DateTime createdAt;

  const DepartmentNoticeModel({
    required this.id,
    required this.title,
    required this.message,
    required this.targetAudience,
    this.priority = 'Normal',
    this.templateType = 'Others',
    this.senderName = 'HOD Dr. K. Manivannan',
    this.isRead = false,
    required this.createdAt,
  });

  bool get isUrgent => priority.toLowerCase().contains('urgent') || priority.toLowerCase().contains('high');

  DepartmentNoticeModel copyWith({
    String? id,
    String? title,
    String? message,
    String? targetAudience,
    String? priority,
    String? templateType,
    String? senderName,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return DepartmentNoticeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      targetAudience: targetAudience ?? this.targetAudience,
      priority: priority ?? this.priority,
      templateType: templateType ?? this.templateType,
      senderName: senderName ?? this.senderName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory DepartmentNoticeModel.fromMap(Map<String, dynamic> map) {
    return DepartmentNoticeModel(
      id: map['notice_id']?.toString() ?? 'notice_${DateTime.now().millisecondsSinceEpoch}',
      title: map['title'] as String? ?? 'Department Notice',
      message: map['message'] as String? ?? '',
      targetAudience: map['target_audience'] as String? ?? 'All 10 Sections',
      priority: map['priority'] as String? ?? 'Normal',
      templateType: map['template_type'] as String? ?? 'Others',
      senderName: map['sender_name'] as String? ?? 'HOD Dr. K. Manivannan',
      isRead: map['is_read'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
