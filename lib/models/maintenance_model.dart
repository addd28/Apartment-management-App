class MaintenanceAttachmentModel {
  final int id;
  final String filePath;
  final String fileName;
  final bool isResult;
  final String? fileType;
  final DateTime uploadedAt;

  MaintenanceAttachmentModel({
    required this.id,
    required this.filePath,
    required this.fileName,
    this.isResult = false,
    this.fileType,
    required this.uploadedAt,
  });

  factory MaintenanceAttachmentModel.fromJson(Map<String, dynamic> json) {
    return MaintenanceAttachmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      filePath: json['filePath'] ?? '',
      fileName: json['fileName'] ?? '',
      isResult: json['isResult'] ?? false,
      fileType: json['fileType'],
      uploadedAt: DateTime.tryParse(json['uploadedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class MaintenanceRequestModel {
  final int id;
  final int apartmentId;
  final String? apartmentNumber;
  final int residentId;
  final String? residentName;
  final String? residentPhone;
  final String title;
  final String description;
  final String priority; // Low, Normal, High, Urgent
  final String status; // Pending, Processing, Completed, Cancelled, Closed
  final int? assignedStaffId;
  final String? assignedStaffName;
  final String? assignedStaffPhone;
  final String? resolutionNotes;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final List<MaintenanceAttachmentModel> attachments;

  MaintenanceRequestModel({
    required this.id,
    required this.apartmentId,
    this.apartmentNumber,
    required this.residentId,
    this.residentName,
    this.residentPhone,
    required this.title,
    required this.description,
    required this.priority,
    required this.status,
    this.assignedStaffId,
    this.assignedStaffName,
    this.assignedStaffPhone,
    this.resolutionNotes,
    required this.createdAt,
    this.resolvedAt,
    this.attachments = const [],
  });

  factory MaintenanceRequestModel.fromJson(Map<String, dynamic> json) {
    var rawAttachments = json['attachments'] ?? json['maintenanceAttachments'];
    List<MaintenanceAttachmentModel> attachmentList = [];
    if (rawAttachments is List) {
      attachmentList = rawAttachments
          .map((item) => MaintenanceAttachmentModel.fromJson(item))
          .toList();
    }

    return MaintenanceRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'],
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId'].toString()) ?? 0,
      residentName: json['residentName'],
      residentPhone: json['residentPhone'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'Normal',
      status: json['status'] ?? 'Pending',
      assignedStaffId: json['assignedStaffId'] is int ? json['assignedStaffId'] : int.tryParse(json['assignedStaffId']?.toString() ?? ''),
      assignedStaffName: json['assignedStaffName'] ?? json['staffName'],
      assignedStaffPhone: json['assignedStaffPhone'],
      resolutionNotes: json['resolutionNotes'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : (json['completedAt'] != null ? DateTime.tryParse(json['completedAt'].toString()) : null),
      attachments: attachmentList,
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isProcessing => status.toLowerCase() == 'processing';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';
  bool get isClosed => status.toLowerCase() == 'closed';
}
