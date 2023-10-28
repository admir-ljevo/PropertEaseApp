// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      name: json['name'] as String? ?? "",
      propertyTypeId: json['propertyTypeId'] as int? ?? 0,
      cityId: json['cityId'] as int? ?? 0,
      applicationUserId: json['applicationUserId'] as int? ?? 1,
      address: json['address'] as String? ?? "",
      description: json['description'] as String? ?? "",
      numberOfRooms: json['numberOfRooms'] as int? ?? 0,
      numberOfBathrooms: json['numberOfBathrooms'] as int? ?? 0,
      squareMeters: json['squareMeters'] as int? ?? 0,
      capacity: json['capacity'] as int? ?? 0,
      monthlyPrice: (json['monthlyPrice'] as num?)?.toDouble() ?? 0,
      dailyPrice: (json['dailyPrice'] as num?)?.toDouble() ?? 0,
      isMonthly: json['isMonthly'] as bool? ?? true,
      isDaily: json['isDaily'] as bool? ?? false,
      hasWiFi: json['hasWiFi'] as bool? ?? false,
      isFurnished: json['isFurnished'] as bool? ?? false,
      hasBalcony: json['hasBalcony'] as bool? ?? false,
      numberOfGarages: json['numberOfGarages'] as int? ?? 0,
      hasPool: json['hasPool'] as bool? ?? false,
      hasAirCondition: json['hasAirCondition'] as bool? ?? false,
      hasAlarm: json['hasAlarm'] as bool? ?? false,
      hasCableTV: json['hasCableTV'] as bool? ?? false,
      hasTV: json['hasTV'] as bool? ?? false,
      hasSurveilance: json['hasSurveilance'] as bool? ?? false,
      hasParking: json['hasParking'] as bool? ?? false,
      hasGarage: json['hasGarage'] as bool? ?? false,
      hasOwnHeatingSystem: json['hasOwnHeatingSystem'] as bool? ?? false,
      gardenSize: json['gardenSize'] as int? ?? 0,
      garageSize: json['garageSize'] as int? ?? 0,
      parkingSize: json['parkingSize'] as int? ?? 0,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    )
      ..propertyType = json['propertyType'] == null
          ? null
          : PropertyType.fromJson(json['propertyType'] as Map<String, dynamic>)
      ..applicationUser = json['applicationUser'] == null
          ? null
          : ApplicationUser.fromJson(
              json['applicationUser'] as Map<String, dynamic>)
      ..city = json['city'] == null
          ? null
          : City.fromJson(json['city'] as Map<String, dynamic>);

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'isDeleted': instance.isDeleted,
      'name': instance.name,
      'propertyTypeId': instance.propertyTypeId,
      'cityId': instance.cityId,
      'applicationUserId': instance.applicationUserId,
      'address': instance.address,
      'description': instance.description,
      'numberOfRooms': instance.numberOfRooms,
      'numberOfBathrooms': instance.numberOfBathrooms,
      'squareMeters': instance.squareMeters,
      'capacity': instance.capacity,
      'monthlyPrice': instance.monthlyPrice,
      'dailyPrice': instance.dailyPrice,
      'isMonthly': instance.isMonthly,
      'isDaily': instance.isDaily,
      'hasWiFi': instance.hasWiFi,
      'isFurnished': instance.isFurnished,
      'hasBalcony': instance.hasBalcony,
      'numberOfGarages': instance.numberOfGarages,
      'hasPool': instance.hasPool,
      'hasAirCondition': instance.hasAirCondition,
      'hasAlarm': instance.hasAlarm,
      'hasCableTV': instance.hasCableTV,
      'hasTV': instance.hasTV,
      'hasSurveilance': instance.hasSurveilance,
      'hasParking': instance.hasParking,
      'hasGarage': instance.hasGarage,
      'hasOwnHeatingSystem': instance.hasOwnHeatingSystem,
      'gardenSize': instance.gardenSize,
      'garageSize': instance.garageSize,
      'parkingSize': instance.parkingSize,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'averageRating': instance.averageRating,
      'isAvailable': instance.isAvailable,
      'propertyType': instance.propertyType,
      'applicationUser': instance.applicationUser,
      'city': instance.city,
    };
