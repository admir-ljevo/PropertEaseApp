// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'property_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PropertyRating _$PropertyRatingFromJson(Map<String, dynamic> json) =>
    PropertyRating(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      propertyId: json['propertyId'] as int?,
      reviewerId: json['reviewerId'] as int?,
      reviewerName: json['reviewerName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      description: json['description'] as String?,
    )
      ..property = json['property'] == null
          ? null
          : Property.fromJson(json['property'] as Map<String, dynamic>)
      ..reviewer = json['reviewer'] == null
          ? null
          : ApplicationUser.fromJson(json['reviewer'] as Map<String, dynamic>);

Map<String, dynamic> _$PropertyRatingToJson(PropertyRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'isDeleted': instance.isDeleted,
      'property': instance.property,
      'propertyId': instance.propertyId,
      'reviewerId': instance.reviewerId,
      'reviewer': instance.reviewer,
      'reviewerName': instance.reviewerName,
      'rating': instance.rating,
      'description': instance.description,
    };
