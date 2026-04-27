import 'package:propertease_admin/models/application_user.dart';

class PropertyRating {
  int? id;
  DateTime? createdAt;
  int? propertyId;
  int? reviewerId;
  ApplicationUser? reviewer;
  String? reviewerName;
  double? rating;
  String? description;

  PropertyRating({
    this.id,
    this.createdAt,
    this.propertyId,
    this.reviewerId,
    this.reviewer,
    this.reviewerName,
    this.rating,
    this.description,
  });

  factory PropertyRating.fromJson(Map<String, dynamic> json) {
    return PropertyRating(
      id: json['id'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      propertyId: json['propertyId'] as int?,
      reviewerId: json['reviewerId'] as int?,
      reviewer: json['reviewer'] != null
          ? ApplicationUser.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      reviewerName: json['reviewerName'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      description: json['description'] as String?,
    );
  }
}
