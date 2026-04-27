import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/models/user_rating.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class UserRatingProvider extends BaseProvider<UserRating> {
  UserRatingProvider() : super('UserRating');

  @override
  UserRating fromJson(data) =>
      UserRating.fromJson(data as Map<String, dynamic>);

  Future<SearchResult<UserRating>> getByRenterPaged(
      int renterId, int page, int pageSize) async {
    return await getFiltered(filter: {
      'RenterId': renterId,
      'page': page,
      'pageSize': pageSize,
    });
  }
}
