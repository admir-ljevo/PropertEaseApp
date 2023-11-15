// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as int? ?? 0,
      isDeleted: json['isDeleted'] as bool? ?? false,
      totalRecordsCount: json['totalRecordsCount'] as int? ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      modifiedAt: json['modifiedAt'] == null
          ? null
          : DateTime.parse(json['modifiedAt'] as String),
      sender: json['sender'] == null
          ? null
          : ApplicationUser.fromJson(json['sender'] as Map<String, dynamic>),
      senderId: json['senderId'] as int?,
      recipient: json['recipient'] == null
          ? null
          : ApplicationUser.fromJson(json['recipient'] as Map<String, dynamic>),
      recipientId: json['recipientId'] as int?,
      conversation: json['conversation'] == null
          ? null
          : Conversation.fromJson(json['conversation'] as Map<String, dynamic>),
      conversationId: json['conversationId'] as int?,
      content: json['content'] as String?,
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'isDeleted': instance.isDeleted,
      'totalRecordsCount': instance.totalRecordsCount,
      'createdAt': instance.createdAt?.toIso8601String(),
      'modifiedAt': instance.modifiedAt?.toIso8601String(),
      'sender': instance.sender,
      'senderId': instance.senderId,
      'recipient': instance.recipient,
      'recipientId': instance.recipientId,
      'conversation': instance.conversation,
      'conversationId': instance.conversationId,
      'content': instance.content,
    };
