import 'package:json_annotation/json_annotation.dart';
import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/property.dart';

part 'property_rating.g.dart';

@JsonSerializable()
class PropertyRating {
  int? id;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  bool? isDeleted;
  Property? property;
  int? propertyId;
  int? reviewerId;
  ApplicationUser? reviewer;
  String? reviewerName;
  double? rating;
  String? description;

  PropertyRating({
    this.id = 0,
    this.createdAt,
    this.modifiedAt,
    this.totalRecordsCount = 0,
    this.isDeleted = false,
    this.propertyId,
    this.reviewerId,
    this.reviewerName,
    this.rating,
    this.description,
  });

  factory PropertyRating.fromJson(Map<String, dynamic> json) =>
      _$PropertyRatingFromJson(json);

  Map<String, dynamic> toJson() => _$PropertyRatingToJson(this);
}
