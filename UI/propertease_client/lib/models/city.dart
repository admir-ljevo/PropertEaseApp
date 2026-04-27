import 'package:json_annotation/json_annotation.dart';

part 'city.g.dart';

@JsonSerializable()
class City {
  int? id;
  String? name;
  int? countryId;

  City(this.id, this.name, this.countryId);

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is City && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
  Map<String, dynamic> toJson() => _$CityToJson(this);
}
