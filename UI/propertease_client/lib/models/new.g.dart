// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

New _$NewFromJson(Map<String, dynamic> json) => New(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String?,
      userId: json['userId'] as int? ?? 1,
      image: json['image'] as String?,
      imageBytes: json['imageBytes'] as String?,
      text: json['text'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
    )
      ..user = json['user'] == null
          ? null
          : ApplicationUser.fromJson(json['user'] as Map<String, dynamic>)
      ..file = const FileConverter().fromJson(json['file'] as String?);

Map<String, dynamic> _$NewToJson(New instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'userId': instance.userId,
      'user': instance.user,
      'image': instance.image,
      'imageBytes': instance.imageBytes,
      'text': instance.text,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'isDeleted': instance.isDeleted,
      'file': const FileConverter().toJson(instance.file),
    };
