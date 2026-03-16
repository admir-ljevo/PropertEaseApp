import '../models/country.dart';
import 'base_provider.dart';

class CountryProvider extends BaseProvider<Country> {
  CountryProvider() : super('Country');

  @override
  Country fromJson(data) => Country.fromJson(data);

  @override
  Map<String, dynamic> toJson(Country data) => {
    'id': data.id ?? 0,
    'name': data.name,
  };
}
