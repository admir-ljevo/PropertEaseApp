import '../models/property.dart';
import 'base_provider.dart';

class PropertyProvider extends BaseProvider<Property> {
  PropertyProvider() : super("Property") {}

  @override
  Property fromJson(data) {
    // TODO: implement fromJson
    return Property.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(Property data) {
    return data.toJson();
  }
}
