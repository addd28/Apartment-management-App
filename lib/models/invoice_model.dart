class InvoiceDetailModel {
  final int id;
  final String serviceName;
  final String? description;
  final double quantity;
  final double unitPrice;
  final double amount;

  InvoiceDetailModel({
    required this.id,
    required this.serviceName,
    this.description,
    required this.quantity,
    required this.unitPrice,
    required this.amount,
  });

  factory InvoiceDetailModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDetailModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      serviceName: json['serviceName'] ?? json['feeType'] ?? 'Dịch vụ',
      description: json['description'],
      quantity: (json['quantity'] is num) ? (json['quantity'] as num).toDouble() : 1.0,
      unitPrice: (json['unitPrice'] is num) ? (json['unitPrice'] as num).toDouble() : 0.0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
    );
  }
}

class PaymentModel {
  final int id;
  final int invoiceId;
  final double amount;
  final String paymentMethod;
  final String? transactionRef;
  final DateTime paymentDate;
  final String? notes;

  PaymentModel({
    required this.id,
    required this.invoiceId,
    required this.amount,
    required this.paymentMethod,
    this.transactionRef,
    required this.paymentDate,
    this.notes,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      invoiceId: json['invoiceId'] is int ? json['invoiceId'] : int.tryParse(json['invoiceId'].toString()) ?? 0,
      amount: (json['amount'] is num) ? (json['amount'] as num).toDouble() : 0.0,
      paymentMethod: json['paymentMethod'] ?? 'Transfer',
      transactionRef: json['transactionRef'] ?? json['referenceCode'],
      paymentDate: DateTime.tryParse(json['paymentDate']?.toString() ?? '') ?? DateTime.now(),
      notes: json['notes'],
    );
  }
}

class InvoiceModel {
  final int id;
  final int apartmentId;
  final String? apartmentNumber;
  final String invoiceNumber;
  final String? title;
  final int month;
  final int year;
  final DateTime dueDate;
  final double totalAmount;
  final double paidAmount;
  final String status; // Pending, Paid, Overdue, Cancelled
  final List<InvoiceDetailModel> details;
  final List<PaymentModel> payments;

  InvoiceModel({
    required this.id,
    required this.apartmentId,
    this.apartmentNumber,
    required this.invoiceNumber,
    this.title,
    required this.month,
    required this.year,
    required this.dueDate,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.status,
    this.details = const [],
    this.payments = const [],
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    var rawDetails = json['invoiceDetails'] ?? json['details'];
    List<InvoiceDetailModel> detailList = [];
    if (rawDetails is List) {
      detailList = rawDetails.map((e) => InvoiceDetailModel.fromJson(e)).toList();
    }

    var rawPayments = json['payments'];
    List<PaymentModel> paymentList = [];
    if (rawPayments is List) {
      paymentList = rawPayments.map((e) => PaymentModel.fromJson(e)).toList();
    }

    return InvoiceModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      apartmentId: json['apartmentId'] is int ? json['apartmentId'] : int.tryParse(json['apartmentId'].toString()) ?? 0,
      apartmentNumber: json['apartmentNumber'],
      invoiceNumber: json['invoiceNumber'] ?? '',
      title: json['title'] ?? 'Hóa đơn T${json['month']}/${json['year']}',
      month: json['month'] is int ? json['month'] : int.tryParse(json['month']?.toString() ?? '') ?? DateTime.now().month,
      year: json['year'] is int ? json['year'] : int.tryParse(json['year']?.toString() ?? '') ?? DateTime.now().year,
      dueDate: DateTime.tryParse(json['dueDate']?.toString() ?? '') ?? DateTime.now(),
      totalAmount: (json['totalAmount'] is num) ? (json['totalAmount'] as num).toDouble() : 0.0,
      paidAmount: (json['paidAmount'] is num) ? (json['paidAmount'] as num).toDouble() : 0.0,
      status: json['status']?.toString() ?? 'Pending',
      details: detailList,
      payments: paymentList,
    );
  }

  bool get isPaid => status.toLowerCase() == 'paid';
  bool get isOverdue => status.toLowerCase() == 'overdue';
  bool get isPending => status.toLowerCase() == 'pending' || status.toLowerCase() == 'unpaid';
  double get remainingAmount => (totalAmount - paidAmount) > 0 ? (totalAmount - paidAmount) : 0.0;
}
