// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyReservation _$PropertyReservationFromJson(Map<String, dynamic> json) =>
    PropertyReservation(
      id: json['id'] as int? ?? 0,
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      property: json['property'] == null
          ? null
          : Property.fromJson(json['property'] as Map<String, dynamic>),
      propertyId: json['propertyId'] as int? ?? 0,
      clientId: json['clientId'] as int? ?? 1,
      numberOfGuests: json['numberOfGuests'] as int? ?? 0,
      dateOfOccupancyStart: json['dateOfOccupancyStart'] == null
          ? null
          : DateTime.parse(json['dateOfOccupancyStart'] as String),
      dateOfOccupancyEnd: json['dateOfOccupancyEnd'] == null
          ? null
          : DateTime.parse(json['dateOfOccupancyEnd'] as String),
      numberOfDays: json['numberOfDays'] as int? ?? 0,
      numberOfMonths: json['numberOfMonths'] as int? ?? 0,
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      isMonthly: json['isMonthly'] as bool? ?? true,
      isDaily: json['isDaily'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      reservationNumber: json['reservationNumber'] as String? ?? '',
      client: json['client'] == null
          ? null
          : ApplicationUser.fromJson(json['client'] as Map<String, dynamic>),
      description: json['description'] as String?,
    )
      ..createdAt = json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String)
      ..modifiedAt = json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String);

Map<String, dynamic> _$PropertyReservationToJson(
        PropertyReservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'isDeleted': instance.isDeleted,
      'property': instance.property,
      'propertyId': instance.propertyId,
      'clientId': instance.clientId,
      'numberOfGuests': instance.numberOfGuests,
      'dateOfOccupancyStart': instance.dateOfOccupancyStart?.toIso8601String(),
      'dateOfOccupancyEnd': instance.dateOfOccupancyEnd?.toIso8601String(),
      'numberOfDays': instance.numberOfDays,
      'numberOfMonths': instance.numberOfMonths,
      'totalPrice': instance.totalPrice,
      'isMonthly': instance.isMonthly,
      'isDaily': instance.isDaily,
      'isActive': instance.isActive,
      'reservationNumber': instance.reservationNumber,
      'client': instance.client,
      'description': instance.description,
    };
