class Payment {
  final int? id;
  final int? clientId;
  final String? clientUsername;
  final String? clientName;
  final int? reservationId;
  final String? reservationNumber;
  final String? payPalPaymentId;
  final double? amount;
  final String? currency;
  final int? status;
  final String? statusName;
  final String? description;
  final DateTime? createdAt;

  Payment({
    this.id,
    this.clientId,
    this.clientUsername,
    this.clientName,
    this.reservationId,
    this.reservationNumber,
    this.payPalPaymentId,
    this.amount,
    this.currency,
    this.status,
    this.statusName,
    this.description,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) => Payment(
        id: json['id'],
        clientId: json['clientId'],
        clientUsername: json['clientUsername'],
        clientName: json['clientName'],
        reservationId: json['reservationId'],
        reservationNumber: json['reservationNumber'],
        payPalPaymentId: json['payPalPaymentId'],
        amount: (json['amount'] as num?)?.toDouble(),
        currency: json['currency'],
        status: json['status'],
        statusName: json['statusName'],
        description: json['description'],
        createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
      );
}
