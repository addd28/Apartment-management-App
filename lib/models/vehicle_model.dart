class VehicleModel {
  final int id;
  final int apartmentId;
  final String apartmentNumber;
  final int residentId;
  final String residentName;
  final String residentPhone;
  final String type; // Motorbike, Car, ElectricBike, Bicycle, Other
  final String? licensePlate;
  final String? brand;
  final String? color;
  final String? parkingCardNumber;
  final bool isActive;
  final DateTime registeredAt;
  final String? notes;

  VehicleModel({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.residentId,
    required this.residentName,
    required this.residentPhone,
    required this.type,
    this.licensePlate,
    this.brand,
    this.color,
    this.parkingCardNumber,
    this.isActive = true,
    required this.registeredAt,
    this.notes,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'] ?? '',
      residentId: json['residentId'] is int ? json['residentId'] : int.tryParse(json['residentId'].toString()) ?? 0,
      residentName: json['residentName'] ?? '',
      residentPhone: json['residentPhone'] ?? '',
      type: json['type'] ?? 'Motorbike',
      licensePlate: json['licensePlate'],
      brand: json['brand'],
      color: json['color'],
      parkingCardNumber: json['parkingCardNumber'],
      isActive: json['isActive'] ?? true,
      registeredAt: DateTime.tryParse(json['registeredAt']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
  }

  String get typeLabel {
    switch (type.toLowerCase()) {
      case 'car':
        return 'Ô tô';
      case 'motorbike':
        return 'Xe máy';
      case 'electricbike':
        return 'Xe máy điện';
      case 'bicycle':
        return 'Xe đạp';
      default:
        return type;
    }
  }
}
