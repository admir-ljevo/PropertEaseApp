// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'person.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Person _$PersonFromJson(Map<String, dynamic> json) => Person()
  ..id = json['id'] as int?
  ..createdAt = json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String)
  ..modifiedAt = json['modifiedAt'] == null
      ? null
      : DateTime.parse(json['modifiedAt'] as String)
  ..totalRecordsCount = json['totalRecordsCount'] as int?
  ..isDeleted = json['isDeleted'] as bool?
  ..firstName = json['firstName'] as String?
  ..lastName = json['lastName'] as String?
  ..birthDate = json['birthDate'] == null
      ? null
      : DateTime.parse(json['birthDate'] as String)
  ..gender = json['gender'] as int?
  ..genderName = json['genderName'] as String?
  ..profilePhoto = json['profilePhoto'] as String?
  ..profilePhotoThumbnail = json['profilePhotoThumbnail'] as String?
  ..birthPlaceId = json['birthPlaceId'] as int?
  ..birthPlace = json['birthPlace'] == null
      ? null
      : City.fromJson(json['birthPlace'] as Map<String, dynamic>)
  ..jmbg = json['jmbg'] as String?
  ..qualifications = json['qualifications'] as String?
  ..placeOfResidenceId = json['placeOfResidenceId'] as int?
  ..placeOfResidence = json['placeOfResidence'] == null
      ? null
      : City.fromJson(json['placeOfResidence'] as Map<String, dynamic>)
  ..marriageStatus = json['marriageStatus'] as int?
  ..marriageStatusName = json['marriageStatusName'] as String?
  ..nationality = json['nationality'] as String?
  ..citizenship = json['citizenship'] as String?
  ..workExperience = json['workExperience'] as bool?
  ..address = json['address'] as String?
  ..postCode = json['postCode'] as String?
  ..biography = json['biography'] as String?
  ..position = json['position'] as int?
  ..positionName = json['positionName'] as String?
  ..dateOfEmployment = json['dateOfEmployment'] == null
      ? null
      : DateTime.parse(json['dateOfEmployment'] as String)
  ..pay = (json['pay'] as num?)?.toDouble()
  ..membershipCard = json['membershipCard'] as bool?
  ..applicationUserId = json['applicationUserId'] as int?;

Map<String, dynamic> _$PersonToJson(Person instance) => <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'isDeleted': instance.isDeleted,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'birthDate': instance.birthDate?.toIso8601String(),
      'gender': instance.gender,
      'genderName': instance.genderName,
      'profilePhoto': instance.profilePhoto,
      'profilePhotoThumbnail': instance.profilePhotoThumbnail,
      'birthPlaceId': instance.birthPlaceId,
      'birthPlace': instance.birthPlace,
      'jmbg': instance.jmbg,
      'qualifications': instance.qualifications,
      'placeOfResidenceId': instance.placeOfResidenceId,
      'placeOfResidence': instance.placeOfResidence,
      'marriageStatus': instance.marriageStatus,
      'marriageStatusName': instance.marriageStatusName,
      'nationality': instance.nationality,
      'citizenship': instance.citizenship,
      'workExperience': instance.workExperience,
      'address': instance.address,
      'postCode': instance.postCode,
      'biography': instance.biography,
      'position': instance.position,
      'positionName': instance.positionName,
      'dateOfEmployment': instance.dateOfEmployment?.toIso8601String(),
      'pay': instance.pay,
      'membershipCard': instance.membershipCard,
      'applicationUserId': instance.applicationUserId,
    };
