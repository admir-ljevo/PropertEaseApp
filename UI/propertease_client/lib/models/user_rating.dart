import 'package:json_annotation/json_annotation.dart';
import 'application_user.dart';

part 'user_rating.g.dart';

@JsonSerializable()
class UserRating {
  int? id;
  DateTime? createdAt;
  DateTime? modifiedAt;
  bool? isDeleted;
  int? renterId;
  int? reviewerId;
  ApplicationUser? reviewer;
  String? reviewerName;
  double? rating;
  String? description;

  UserRating({
    this.id = 0,
    this.createdAt,
    this.modifiedAt,
    this.isDeleted = false,
    this.renterId,
    this.reviewerId,
    this.reviewerName,
    this.rating,
    this.description,
  });

  factory UserRating.fromJson(Map<String, dynamic> json) =>
      _$UserRatingFromJson(json);

  Map<String, dynamic> toJson() => _$UserRatingToJson(this);
}
