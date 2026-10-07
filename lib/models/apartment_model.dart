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
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      apartmentNumber: json['apartmentNumber']?.toString() ?? '',
      area: (json['area'] is num) ? (json['area'] as num).toDouble() : 0.0,
      rentPrice: json['rentPrice'] != null ? (json['rentPrice'] as num).toDouble() : null,
      maxCapacity: json['maxCapacity'] is int ? json['maxCapacity'] : int.tryParse(json['maxCapacity']?.toString() ?? '1') ?? 1,
      status: json['status']?.toString() ?? 'Occupied',
      floorId: json['floorId'] is int ? json['floorId'] : int.tryParse(json['floorId']?.toString() ?? '0') ?? 0,
      floorNumber: json['floorNumber'] is int ? json['floorNumber'] : int.tryParse(json['floorNumber']?.toString() ?? ''),
      buildingName: json['buildingName']?.toString() ?? (json['building'] != null ? json['building']['name']?.toString() : null),
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
  final String? citizenId;
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
    this.citizenId,
    this.email,
    required this.relationship,
    required this.isOwner,
    this.joinedAt,
    this.isActive = true,
  });

  factory ApartmentMemberModel.fromJson(Map<String, dynamic> json) {
    return ApartmentMemberModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId']?.toString() ?? '0') ?? 0,
      apartmentNumber: json['apartmentNumber']?.toString(),
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId']?.toString() ?? '0') ?? 0,
      fullName: json['residentName']?.toString() ?? json['fullName']?.toString() ?? '',
      phoneNumber: json['residentPhone']?.toString() ?? json['phoneNumber']?.toString(),
      citizenId: json['residentCitizenId']?.toString() ?? json['citizenId']?.toString() ?? json['identityCard']?.toString(),
      email: json['email']?.toString(),
      relationship: json['relationship']?.toString() ?? 'Thành viên',
      isOwner: json['isOwner'] == true,
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
  final String? residentPhone;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double depositAmount;
  final String status;
  final String? documentUrl;
  final String? notes;

  ContractModel({
    required this.id,
    required this.contractNumber,
    required this.apartmentId,
    this.apartmentNumber,
    required this.residentId,
    this.residentName,
    this.residentPhone,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.depositAmount,
    required this.status,
    this.documentUrl,
    this.notes,
  });

  factory ContractModel.fromJson(Map<String, dynamic> json) {
    final rawRent = json['rentAmount'] ?? json['rentPrice'] ?? json['monthlyRent'] ?? 0;
    final rent = (rawRent is num) ? rawRent.toDouble() : double.tryParse(rawRent.toString()) ?? 0.0;
    final rawDeposit = json['depositAmount'] ?? 0;
    final deposit = (rawDeposit is num) ? rawDeposit.toDouble() : double.tryParse(rawDeposit.toString()) ?? 0.0;
    final docUrl = json['documentUrl']?.toString() ?? json['contractFileUrl']?.toString();

    return ContractModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      contractNumber: json['contractNumber']?.toString() ?? 'HD-${json['id']}',
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId']?.toString() ?? '0') ?? 0,
      apartmentNumber: json['apartmentNumber']?.toString(),
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId']?.toString() ?? '0') ?? 0,
      residentName: json['residentName']?.toString() ?? json['fullName']?.toString(),
      residentPhone: json['residentPhone']?.toString() ?? json['phoneNumber']?.toString(),
      startDate: DateTime.tryParse(json['startDate']?.toString() ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate']?.toString() ?? '') ?? DateTime.now(),
      monthlyRent: rent,
      depositAmount: deposit,
      status: json['status']?.toString() ?? 'Active',
      documentUrl: (docUrl != null && docUrl.isNotEmpty) ? docUrl : null,
      notes: json['notes']?.toString(),
    );
  }

  bool get isActive => status.toLowerCase() == 'active' || status.toLowerCase() == 'đang hiệu lực';
}
