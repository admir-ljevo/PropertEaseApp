import 'package:propertease_admin/models/person.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class PersonProvider extends BaseProvider<Person> {
  PersonProvider() : super("Person") {}

  @override
  Person fromJson(data) {
    return Person.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(Person data) {
    return data.toJson();
  }
}
