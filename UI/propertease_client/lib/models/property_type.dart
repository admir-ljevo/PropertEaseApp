import 'package:json_annotation/json_annotation.dart';

part 'property_type.g.dart';

@JsonSerializable()
class PropertyType {
  int? id;
  String? name;

  PropertyType(this.id, this.name);

  factory PropertyType.fromJson(Map<String, dynamic> json) =>
      _$PropertyTypeFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyType &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  /// Connect the generated [_$PropertyToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PropertyTypeToJson(this);
}
