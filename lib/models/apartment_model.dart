class ApartmentModel {
  final int id;
  final String apartmentNumber;
  final double area;
  final double? rentPrice;
  final int maxCapacity;
  final String status;
  final int floorId;
  final int? floorNumber;
  final String? buildingName;

  ApartmentModel({
    required this.id,
    required this.apartmentNumber,
    required this.area,
    this.rentPrice,
    required this.maxCapacity,
    required this.status,
    required this.floorId,
    this.floorNumber,
    this.buildingName,
  });

  factory ApartmentModel.fromJson(Map<String, dynamic> json) {
    return ApartmentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'] ?? '',
      area: (json['area'] is num) ? (json['area'] as num).toDouble() : 0.0,
      rentPrice: json['rentPrice'] != null ? (json['rentPrice'] as num).toDouble() : null,
      maxCapacity: json['maxCapacity'] is int ? json['maxCapacity'] : int.tryParse(json['maxCapacity'].toString()) ?? 1,
      status: json['status']?.toString() ?? 'Occupied',
      floorId: json['floorId'] is int ? json['floorId'] : int.tryParse(json['floorId'].toString()) ?? 0,
      floorNumber: json['floorNumber'] is int ? json['floorNumber'] : int.tryParse(json['floorNumber']?.toString() ?? ''),
      buildingName: json['buildingName'] ?? (json['building'] != null ? json['building']['name'] : null),
    );
  }
}

class ApartmentMemberModel {
  final int id;
  final int apartmentId;
  final String? apartmentNumber;
  final int residentId;
  final String? fullName;
  final String? phoneNumber;
  final String? email;
  final String relationship;
  final bool isOwner;
  final DateTime? joinedAt;
  final bool isActive;

  ApartmentMemberModel({
    required this.id,
    required this.apartmentId,
    this.apartmentNumber,
    required this.residentId,
    this.fullName,
    this.phoneNumber,
    this.email,
    required this.relationship,
    required this.isOwner,
    this.joinedAt,
    this.isActive = true,
  });

  factory ApartmentMemberModel.fromJson(Map<String, dynamic> json) {
    return ApartmentMemberModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'],
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId'].toString()) ?? 0,
      fullName: json['fullName'] ?? json['residentName'] ?? '',
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      relationship: json['relationship'] ?? 'Member',
      isOwner: json['isOwner'] ?? false,
      joinedAt: json['joinedAt'] != null ? DateTime.tryParse(json['joinedAt'].toString()) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

class ContractModel {
  final int id;
  final String contractNumber;
  final int apartmentId;
  final String? apartmentNumber;
  final int residentId;
  final String? residentName;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status;
  final String? notes;

  ContractModel({
    required this.id,
    required this.contractNumber,
    required this.apartmentId,
    this.apartmentNumber,
    required this.residentId,
    this.residentName,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.notes,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    return ContractModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      contractNumber: json['contractNumber'] ?? '',
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'],
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId'].toString()) ?? 0,
      residentName: json['residentName'],
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      monthlyRent: (json['monthlyRent'] is num) ? (json['monthlyRent'] as num).toDouble() : 0.0,
      depositAmount: (json['depositAmount'] is num) ? (json['depositAmount'] as num).toDouble() : 0.0,
      status: json['status'] ?? 'Active',
      notes: json['notes'],
    );
  }
}
