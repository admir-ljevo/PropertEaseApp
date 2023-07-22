import 'package:json_annotation/json_annotation.dart';

part 'photo.g.dart';

@JsonSerializable()
class Photo {
  int? id;
  String? url;
  int? propertyId;

  Photo(this.id, this.url, this.propertyId);

  factory Photo.fromJson(Map<String, dynamic> json) => _$PhotoFromJson(json);

  /// Connect the generated [_$PropertyToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PhotoToJson(this);
}
