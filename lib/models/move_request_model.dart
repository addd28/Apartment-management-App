class MoveRequestModel {
  final int id;
  final int apartmentId;
  final String apartmentNumber;
  final int residentId;
  final String residentName;
  final String residentPhone;
  final String type; // MoveIn, MoveOut
  final String status; // Pending, Approved, Rejected, InProgress, Completed, Cancelled
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final String description;
  final String? vehicleLicensePlate;
  final String? driverName;
  final String? driverPhone;
  final String? rejectionReason;
  final String? notes;
  final DateTime createdAt;

  MoveRequestModel({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.residentId,
    required this.residentName,
    required this.residentPhone,
    required this.type,
    required this.status,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.description,
    this.vehicleLicensePlate,
    this.driverName,
    this.driverPhone,
    this.rejectionReason,
    this.notes,
    required this.createdAt,
  });

  factory MoveRequestModel.fromJson(Map<String, dynamic> json) {
    return MoveRequestModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'] ?? '',
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId'].toString()) ?? 0,
      residentName: json['residentName'] ?? '',
      residentPhone: json['residentPhone'] ?? '',
      type: json['type'] ?? 'MoveIn',
      status: json['status'] ?? 'Pending',
      scheduledDate: DateTime.tryParse(json['scheduledDate']?.toString() ?? '') ?? DateTime.now(),
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '11:00',
      description: json['description'] ?? '',
      vehicleLicensePlate: json['vehicleLicensePlate'],
      driverName: json['driverName'],
      driverPhone: json['driverPhone'],
      rejectionReason: json['rejectionReason'],
      notes: json['notes'],
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isApproved => status.toLowerCase() == 'approved';
  bool get isRejected => status.toLowerCase() == 'rejected';
  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get typeLabel => type.toLowerCase() == 'movein' ? 'Chuyển vào' : 'Chuyển đi';
}
