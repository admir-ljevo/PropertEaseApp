// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Property _$PropertyFromJson(Map<String, dynamic> json) => Property(
      json['id'] as int?,
      json['name'] as String?,
      (json['averageRating'] as num?)?.toDouble(),
      (json['dailyPrice'] as num?)?.toDouble(),
      (json['monthlyPrice'] as num?)?.toDouble(),
      json['address'] as String?,
    );

Map<String, dynamic> _$PropertyToJson(Property instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'averageRating': instance.averageRating,
      'dailyPrice': instance.dailyPrice,
      'monthlyPrice': instance.monthlyPrice,
      'address': instance.address,
    };
