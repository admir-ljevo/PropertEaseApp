// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'photo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Photo _$PhotoFromJson(Map<String, dynamic> json) => Photo(
      json['id'] as int?,
      json['url'] as String?,
      json['propertyId'] as int?,
      const FileConverter().fromJson(json['file'] as String?),
      json['imageBytes'] as String?,
    )
      ..isDeleted = json['isDeleted'] as bool?
      ..totalRecordsCount = json['totalRecordsCount'] as int?
      ..createdAt = json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String);

Map<String, dynamic> _$PhotoToJson(Photo instance) => <String, dynamic>{
      'id': instance.id,
      'url': instance.url,
      'propertyId': instance.propertyId,
      'isDeleted': instance.isDeleted,
      'totalRecordsCount': instance.totalRecordsCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'imageBytes': instance.imageBytes,
      'file': const FileConverter().toJson(instance.file),
    };
