import 'package:propertease_admin/models/property_rating.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class PropertyRatingProvider extends BaseProvider<PropertyRating> {
  PropertyRatingProvider() : super('PropertyRatings');

  @override
  PropertyRating fromJson(data) =>
      PropertyRating.fromJson(data as Map<String, dynamic>);

  Future<SearchResult<PropertyRating>> getByPropertyPaged(
      int propertyId, int page, int pageSize) async {
    return await getFiltered(filter: {
      'propertyId': propertyId,
      'page': page,
      'pageSize': pageSize,
    });
  }
}
