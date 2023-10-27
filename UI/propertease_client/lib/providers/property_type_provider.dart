import '../models/property_type.dart';
import 'base_provider.dart';

class PropertyTypeProvider extends BaseProvider<PropertyType> {
  PropertyTypeProvider() : super("PropertyType") {}

  @override
  PropertyType fromJson(data) {
    // TODO: implement fromJson
    return PropertyType.fromJson(data);
  }
}
