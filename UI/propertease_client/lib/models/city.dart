import 'package:json_annotation/json_annotation.dart';

part 'city.g.dart';

@JsonSerializable()
class City {
  int? id;
  String? name;
  int? countryId;

  City(this.id, this.name, this.countryId);

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

  /// Connect the generated [_$CityToJson] function to the `toJson` method.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  // Override hashCode to generate a unique hash code based on the 'id' property
  @override
  int get hashCode => id.hashCode;
  Map<String, dynamic> toJson() => _$CityToJson(this);
}
