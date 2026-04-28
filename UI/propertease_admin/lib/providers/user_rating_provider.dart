import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/models/user_rating.dart';
import 'package:propertease_admin/providers/base_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';

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

  Future<double> getAverageRating(int renterId) async {
    final url = Uri.parse(
        '${AppConfig.apiBase}UserRating/GetAverageRating/$renterId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer ${Authorization.token}',
    });
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as num).toDouble();
    }
    return 0;
  }
}
