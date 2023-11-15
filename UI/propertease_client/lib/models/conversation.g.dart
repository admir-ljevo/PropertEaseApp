// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Conversation _$ConversationFromJson(Map<String, dynamic> json) => Conversation(
      id: json['id'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      property: json['property'] == null
          ? null
          : Property.fromJson(json['property'] as Map<String, dynamic>),
      propertyId: json['propertyId'] as int?,
      client: json['client'] == null
          ? null
          : ApplicationUser.fromJson(json['client'] as Map<String, dynamic>),
      clientId: json['clientId'] as int?,
      renter: json['renter'] == null
          ? null
          : ApplicationUser.fromJson(json['renter'] as Map<String, dynamic>),
      renterId: json['renterId'] as int?,
      lastMessage: json['lastMessage'] as String?,
      lastSent: json['lastSent'] == null
          ? null
          : DateTime.parse(json['lastSent'] as String),
    );

Map<String, dynamic> _$ConversationToJson(Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'isDeleted': instance.isDeleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'totalRecordsCount': instance.totalRecordsCount,
      'property': instance.property,
      'propertyId': instance.propertyId,
      'client': instance.client,
      'clientId': instance.clientId,
      'renter': instance.renter,
      'lastMessage': instance.lastMessage,
      'lastSent': instance.lastSent?.toIso8601String(),
      'renterId': instance.renterId,
    };
