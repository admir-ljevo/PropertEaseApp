import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class PropertyTypeProvider extends BaseProvider<PropertyType> {
  PropertyTypeProvider() : super("PropertyType") {}

  @override
  PropertyType fromJson(data) {
    return PropertyType.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(PropertyType data) => {
    'id': data.id ?? 0,
    'name': data.name,
  };
}
