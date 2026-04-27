import 'package:json_annotation/json_annotation.dart';
import 'package:propertease_admin/models/application_user.dart';

import 'property.dart';

part 'property_reservation.g.dart';

@JsonSerializable()
class PropertyReservation {
  int? id;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  bool? isDeleted;
  Property? property;
  int? propertyId;
  int? clientId;
  int? renterId;
  int? numberOfGuests;
  DateTime? dateOfOccupancyStart;
  DateTime? dateOfOccupancyEnd;
  int? numberOfDays;
  int? numberOfMonths;
  double? totalPrice;
  bool? isMonthly;
  bool? isDaily;
  bool? isActive;
  int? status;
  String? reservationNumber;
  ApplicationUser? client;
  String? description;
  String? cancellationReason;
  DateTime? cancelledAt;
  String? cancelledByName;
  DateTime? confirmedAt;
  String? confirmedByName;

  PropertyReservation({
    this.id = 0,
    this.totalRecordsCount = 0,
    this.isDeleted = false,
    this.property,
    this.propertyId = 0,
    this.clientId = 1,
    this.renterId,
    this.numberOfGuests = 0,
    this.dateOfOccupancyStart,
    this.dateOfOccupancyEnd,
    this.numberOfDays = 0,
    this.numberOfMonths = 0,
    this.totalPrice = 0,
    this.isMonthly = true,
    this.isDaily = false,
    this.isActive = true,
    this.status,
    this.reservationNumber = '',
    this.client,
    this.description,
    this.cancellationReason,
    this.cancelledAt,
    this.cancelledByName,
    this.confirmedAt,
    this.confirmedByName,
  });

  factory PropertyReservation.fromJson(Map<String, dynamic> json) =>
      _$PropertyReservationFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyReservationToJson(this);
}
