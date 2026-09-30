class NotificationModel {
  final int id;
  final int? userId;
  final String title;
  final String body;
  final String type;
  final int? referenceId;
  final bool isRead;
  final bool isGlobal;
  final int? apartmentId;
  final String? apartmentNumber;
  final DateTime createdAt;

  // Compatibility getter
  String get content => body;

  NotificationModel({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    this.type = 'ANNOUNCEMENT',
    this.referenceId,
    this.isRead = false,
    this.isGlobal = true,
    this.apartmentId,
    this.apartmentNumber,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'] ?? json['content'] ?? '';
    final rawRef = json['referenceId'];
    int? refId;
    if (rawRef is int) {
      refId = rawRef;
    } else if (rawRef != null) {
      refId = int.tryParse(rawRef.toString());
    }

    return NotificationModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? ''),
      title: json['title'] ?? 'Thông báo',
      body: rawBody.toString(),
      type: json['type'] ?? 'ANNOUNCEMENT',
      referenceId: refId,
      isRead: json['isRead'] is bool ? json['isRead'] : (json['isRead']?.toString().toLowerCase() == 'true'),
      isGlobal: json['isGlobal'] is bool ? json['isGlobal'] : true,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId']?.toString() ?? ''),
      apartmentNumber: json['apartmentNumber'] ?? (json['apartment'] != null ? json['apartment']['apartmentNumber'] : null),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class NotificationPageResponse {
  final List<NotificationModel> items;
  final int page;
  final int pageSize;
  final int totalCount;
  final int unreadCount;

  NotificationPageResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalCount,
    required this.unreadCount,
  });

  factory NotificationPageResponse.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List? ?? [];
    return NotificationPageResponse(
      items: list.map((item) => NotificationModel.fromJson(item as Map<String, dynamic>)).toList(),
      page: json['page'] is int ? json['page'] : int.tryParse(json['page']?.toString() ?? '1') ?? 1,
      pageSize: json['pageSize'] is int ? json['pageSize'] : int.tryParse(json['pageSize']?.toString() ?? '20') ?? 20,
      totalCount: json['totalCount'] is int ? json['totalCount'] : int.tryParse(json['totalCount']?.toString() ?? '0') ?? 0,
      unreadCount: json['unreadCount'] is int ? json['unreadCount'] : int.tryParse(json['unreadCount']?.toString() ?? '0') ?? 0,
    );
  }
}
