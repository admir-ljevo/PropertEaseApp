import 'package:json_annotation/json_annotation.dart';
import 'application_user.dart';
import 'conversation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  int? id;
  bool? isDeleted;
  int? totalRecordsCount;
  DateTime? createdAt;
  DateTime? modifiedAt;

  ApplicationUser? sender;
  int? senderId;
  ApplicationUser? recipient;
  int? recipientId;
  Conversation? conversation;
  int? conversationId;
  String? content;

  // Constructor
  Message({
    this.id = 0,
    this.isDeleted = false,
    this.totalRecordsCount = 0,
    this.createdAt,
    this.modifiedAt,
    this.sender,
    this.senderId,
    this.recipient,
    this.recipientId,
    this.conversation,
    this.conversationId,
    this.content,
  });

  // Factory constructor to create an instance from a JSON object
  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  // Convert the instance to a JSON object
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}
