// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserRating _$UserRatingFromJson(Map<String, dynamic> json) => UserRating(
      id: json['id'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      isDeleted: json['isDeleted'] as bool? ?? false,
      renterId: json['renterId'] as int?,
      reviewerId: json['reviewerId'] as int?,
      reviewerName: json['reviewerName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      description: json['description'] as String?,
      reservationId: json['reservationId'] as int?,
    )..reviewer = json['reviewer'] == null
        ? null
        : ApplicationUser.fromJson(json['reviewer'] as Map<String, dynamic>);

Map<String, dynamic> _$UserRatingToJson(UserRating instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'isDeleted': instance.isDeleted,
      'renterId': instance.renterId,
      'reviewerId': instance.reviewerId,
      'reviewer': instance.reviewer,
      'reviewerName': instance.reviewerName,
      'rating': instance.rating,
      'description': instance.description,
      'reservationId': instance.reservationId,
    };
