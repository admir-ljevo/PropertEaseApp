class ReservationNotification {
  final int? id;
  final int? userId;
  final int? reservationId;
  final String? title;
  final String? message;
  final bool? isSeen;
  final String? reservationNumber;
  final String? propertyName;
  final String? propertyPhotoUrl;
  final DateTime? createdAt;

  const ReservationNotification({
    this.id,
    this.userId,
    this.reservationId,
    this.title,
    this.message,
    this.isSeen,
    this.reservationNumber,
    this.propertyName,
    this.propertyPhotoUrl,
    this.createdAt,
  });

  factory ReservationNotification.fromJson(Map<String, dynamic> json) =>
      ReservationNotification(
        id:               json['id'] as int?,
        userId:           json['userId'] as int?,
        reservationId:    json['reservationId'] as int?,
        title:            json['title'] as String?,
        message:          json['message'] as String?,
        isSeen:           json['isSeen'] as bool?,
        reservationNumber: json['reservationNumber'] as String?,
        propertyName:     json['propertyName'] as String?,
        propertyPhotoUrl: json['propertyPhotoUrl'] as String?,
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
      );
}
