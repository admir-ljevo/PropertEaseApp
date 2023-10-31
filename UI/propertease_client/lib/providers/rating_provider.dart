import 'package:propertease_client/models/property_rating.dart';

import 'base_provider.dart';

class RatingProvider extends BaseProvider<PropertyRating> {
  RatingProvider() : super("PropertyRatings") {}
  @override
  PropertyRating fromJson(data) {
    return PropertyRating.fromJson(data);
  }

  @override
  Map<String, dynamic> toJson(PropertyRating data) {
    return data.toJson();
  }
}
