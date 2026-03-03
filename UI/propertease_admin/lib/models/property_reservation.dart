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
  int? numberOfGuests;
  DateTime? dateOfOccupancyStart;
  DateTime? dateOfOccupancyEnd;
  int? numberOfDays;
  int? numberOfMonths;
  double? totalPrice;
  bool? isMonthly;
  bool? isDaily;
  bool? isActive;
  String? reservationNumber;
  ApplicationUser? client;
  String? description;

  PropertyReservation({
    this.id = 0,
    this.totalRecordsCount = 0,
    this.isDeleted = false,
    this.property,
    this.propertyId = 0,
    this.clientId = 1,
    this.numberOfGuests = 0,
    this.dateOfOccupancyStart,
    this.dateOfOccupancyEnd,
    this.numberOfDays = 0,
    this.numberOfMonths = 0,
    this.totalPrice = 0,
    this.isMonthly = true,
    this.isDaily = false,
    this.isActive = true,
    this.reservationNumber = '',
    this.client,
    this.description,
  });

  factory PropertyReservation.fromJson(Map<String, dynamic> json) =>
      _$PropertyReservationFromJson(json);

  /// Connect the generated [_$PropertyReservationToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PropertyReservationToJson(this);
}
