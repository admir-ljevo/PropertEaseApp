import 'package:json_annotation/json_annotation.dart';

part 'property.g.dart';

@JsonSerializable()
class Property {
  int? id;
  String? name;
  double? averageRating;
  double? dailyPrice;
  double? monthlyPrice;
  String? address;

  Property(this.id, this.name, this.averageRating, this.dailyPrice,
      this.monthlyPrice, this.address);

  factory Property.fromJson(Map<String, dynamic> json) =>
      _$PropertyFromJson(json);

  /// Connect the generated [_$PropertyToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PropertyToJson(this);
}


/*
{
  "id": 0,
  "createdAt": "2023-07-10T08:22:09.950Z",
  "modifiedAt": "2023-07-10T08:22:09.950Z",
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