import 'package:propertease_admin/models/application_user.dart';

class UserRating {
  int? id;
  DateTime? createdAt;
  int? renterId;
  int? reviewerId;
  ApplicationUser? reviewer;
  String? reviewerName;
  double? rating;
  String? description;

  UserRating({
    this.id,
    this.createdAt,
    this.renterId,
    this.reviewerId,
    this.reviewer,
    this.reviewerName,
    this.rating,
    this.description,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) {
    return UserRating(
      id: json['id'] as int?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      renterId: json['renterId'] as int?,
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
