import 'package:propertease_admin/providers/base_provider.dart';

import '../models/city.dart';

class CityProvider extends BaseProvider<City> {
  CityProvider() : super("City") {}
  @override
  City fromJson(data) {
    return City.fromJson(data);
  }
}
