import 'package:json_annotation/json_annotation.dart';
import 'application_user.dart';
import 'property.dart';

part 'conversation.g.dart';

@JsonSerializable()
class Conversation {
  int? id;
  bool? isDeleted;
  DateTime? createdAt;
  DateTime? modifiedAt;
  int? totalRecordsCount;
  Property? property;
  int? propertyId;
  ApplicationUser? client;
  int? clientId;
  ApplicationUser? renter;
  String? lastMessage;
  DateTime? lastSent;
  int? renterId;
  int? unreadCount;

  Conversation({
    this.id = 0,
    this.isDeleted = false,
    this.createdAt,
    this.modifiedAt,
    this.totalRecordsCount = 0,
    this.property,
    this.propertyId,
    this.client,
    this.clientId,
    this.renter,
    this.renterId,
    this.lastMessage,
    this.lastSent,
    this.unreadCount,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}
