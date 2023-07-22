import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'property_type.g.dart';

@JsonSerializable()
class PropertyType {
  int? Id;
  String? Name;

  PropertyType(this.Id, this.Name);

  factory PropertyType.fromJson(Map<String, dynamic> json) =>
      _$PropertyTypeFromJson(json);

  /// Connect the generated [_$PropertyToJson] function to the `toJson` method.
  Map<String, dynamic> toJson() => _$PropertyTypeToJson(this);
}
