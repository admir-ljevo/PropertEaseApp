import 'package:json_annotation/json_annotation.dart';

import 'city.dart';

part 'person.g.dart';

@JsonSerializable()
class Person {
  int? id;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  bool? isDeleted;
  String? firstName;
  String? lastName;
  DateTime? birthDate;
  int? gender; // Enum values are stored as integers
  String? genderName;
  String? profilePhoto;
  String? profilePhotoThumbnail;
  int? birthPlaceId;
  City? birthPlace;
  String? jmbg;
  String? qualifications;
  int? placeOfResidenceId;
  City? placeOfResidence;
  int? marriageStatus; // Enum values are stored as integers
  String? marriageStatusName;
  String? nationality;
  String? citizenship;
  bool? workExperience;
  String? address;
  String? postCode;
  String? biography;
  int? position;
  String? positionName;
  DateTime? dateOfEmployment;
  double? pay;
  bool? membershipCard;
  int? applicationUserId;

  Person();

  factory Person.fromJson(Map<String, dynamic> json) => _$PersonFromJson(json);
  Map<String, dynamic> toJson() => _$PersonToJson(this);
}

enum Gender { male, female, other }

enum MarriageStatus { single, married, divorced, widowed }
