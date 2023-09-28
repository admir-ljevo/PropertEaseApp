import 'package:json_annotation/json_annotation.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/property_type.dart';

part 'property.g.dart';

@JsonSerializable()
class Property {
  int? id;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  bool? isDeleted;
  String? name;
  int? propertyTypeId;
  int? cityId;
  int? applicationUserId;
  String? address;
  String? description;
  int? numberOfRooms;
  int? numberOfBathrooms;
  int? squareMeters;
  int? capacity;
  double? monthlyPrice;
  double? dailyPrice;
  bool? isMonthly;
  bool? isDaily;
  bool? hasWiFi;
  bool? isFurnished;
  bool? hasBalcony;
  int? numberOfGarages;
  bool? hasPool;
  bool? hasAirCondition;
  bool? hasAlarm;
  bool? hasCableTV;
  bool? hasTV;
  bool? hasSurveilance;
  bool? hasParking;
  bool? hasGarage;
  bool? hasOwnHeatingSystem;
  int? gardenSize;
  int? garageSize;
  int? parkingSize;
  double? latitude;
  double? longitude;
  double? averageRating;
  bool? isAvailable;
  PropertyType? propertyType;
  City? city;
  Property({
    this.id = 0,
    this.createdAt,
    this.modifiedAt,
    this.totalRecordsCount = 0,
    this.isDeleted = false,
    this.name = "",
    this.propertyTypeId = 0,
    this.cityId = 0,
    this.applicationUserId = 1,
    this.address = "",
    this.description = "",
    this.numberOfRooms = 0,
    this.numberOfBathrooms = 0,
    this.squareMeters = 0,
    this.capacity = 0,
    this.monthlyPrice = 0,
    this.dailyPrice = 0,
    this.isMonthly = true,
    this.isDaily = false,
    this.hasWiFi = false,
    this.isFurnished = false,
    this.hasBalcony = false,
    this.numberOfGarages = 0,
    this.hasPool = false,
    this.hasAirCondition = false,
    this.hasAlarm = false,
    this.hasCableTV = false,
    this.hasTV = false,
    this.hasSurveilance = false,
    this.hasParking = false,
    this.hasGarage = false,
    this.hasOwnHeatingSystem = false,
    this.gardenSize = 0,
    this.garageSize = 0,
    this.parkingSize = 0,
    this.latitude = 0,
    this.longitude = 0,
    this.averageRating = 0,
    this.isAvailable = true,
  });

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  /// Connect the generated [_$PropertyToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PropertyToJson(this);
  // Map<String, dynamic> toJson(Property data) => _$PropertyToJson(this);
}


/*
{
  "id": 0,
  "createdAt": "2023-07-10T08:22:09.950Z",
  "modifiedAt": "2023-07-10T08:22:09.950Z",d
  "totalRecordsCount": 0,
  "isDeleted": true,
  "name": "string",
  "propertyTypeId": 0,
  "cityId": 0,
  "applicationUserId": 0,
  "address": "string",
  "description": "string",
  "numberOfRooms": 0,
  "numberOfBathrooms": 0,
  "squareMeters": 0,
  "capacity": 0,
  "monthlyPrice": 0,
  "dailyPrice": 0,
  "isMonthly": true,
  "isDaily": true,
  "hasWiFi": true,
  "isFurnished": true,
  "hasBalcony": true,
  "numberOfGarages": 0,
  "hasPool": true,
  "hasAirCondition": true,
  "hasAlarm": true,
  "hasCableTV": true,
  "hasOwnHeatingSystem": true,
  "gardenSize": 0,
  "garageSize": 0,
  "parkingSize": 0,
  "latitude": 0,
  "longitude": 0,
  "averageRating": 0,
  "isAvailable": true
}
 */