import 'package:json_annotation/json_annotation.dart';

part 'gender_enum.g.dart';

@JsonEnum()
enum Gender {
  @JsonValue('Male')
  Male,
  @JsonValue('Female')
  Female,
}
