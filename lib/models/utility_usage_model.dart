class UtilityUsageModel {
  final int id;
  final int apartmentId;
  final String apartmentNumber;
  final int utilityId;
  final String utilityName;
  final int month;
  final int year;
  final double oldIndicator;
  final double newIndicator;
  final double usageAmount;

  UtilityUsageModel({
    required this.id,
    required this.apartmentId,
    required this.apartmentNumber,
    required this.utilityId,
    required this.utilityName,
    required this.month,
    required this.year,
    required this.oldIndicator,
    required this.newIndicator,
    required this.usageAmount,
  });

  factory UtilityUsageModel.fromJson(Map<String, dynamic> json) {
    return UtilityUsageModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId']?.toString() ?? '0') ?? 0,
      apartmentNumber: json['apartmentNumber']?.toString() ?? '',
      utilityId: json['utilityId'] is int ? json['utilityId'] : int.tryParse(json['utilityId']?.toString() ?? '0') ?? 0,
      utilityName: json['utilityName']?.toString() ?? 'Dịch vụ',
      month: json['month'] is int ? json['month'] : int.tryParse(json['month']?.toString() ?? '1') ?? 1,
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '2026') ?? 2026,
      oldIndicator: (json['oldIndicator'] is num) ? (json['oldIndicator'] as num).toDouble() : 0.0,
      newIndicator: (json['newIndicator'] is num) ? (json['newIndicator'] as num).toDouble() : 0.0,
      usageAmount: (json['usageAmount'] is num) ? (json['usageAmount'] as num).toDouble() : 0.0,
    );
  }

  bool get isElectricity =>
      utilityName.toLowerCase().contains('điện') || utilityName.toLowerCase().contains('electric');

  bool get isWater =>
      utilityName.toLowerCase().contains('nước') || utilityName.toLowerCase().contains('water');

  String get unit => isElectricity ? 'kWh' : (isWater ? 'm³' : 'đơn vị');
}
