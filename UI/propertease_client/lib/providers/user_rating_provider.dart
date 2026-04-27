import 'dart:convert';
import '../models/user_rating.dart';
import 'base_provider.dart';

class UserRatingProvider extends BaseProvider<UserRating> {
  UserRatingProvider() : super('UserRating');

  @override
  UserRating fromJson(data) => UserRating.fromJson(data);

  @override
  Map<String, dynamic> toJson(UserRating data) => data.toJson();

  Future<List<UserRating>> getByRenter(int renterId,
      {int page = 1, int pageSize = 10}) async {
    final url = Uri.parse(
        '${BaseProvider.baseUrl}UserRating/GetFilteredData?RenterId=$renterId&Page=$page&PageSize=$pageSize');
    final response = await http!.get(url, headers: createHeaders());
    if (!isValidResponse(response)) {
      throw Exception('Failed to load ratings');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? [])
        .map((e) => UserRating.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }

  Future<int> getTotalCount(int renterId) async {
    final url = Uri.parse(
        '${BaseProvider.baseUrl}UserRating/GetFilteredData?RenterId=$renterId&Page=1&PageSize=1');
    final response = await http!.get(url, headers: createHeaders());
    if (!isValidResponse(response)) return 0;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['totalCount'] as int? ?? 0;
  }

  Future<double> getAverageRating(int renterId) async {
    final url = Uri.parse(
        '${BaseProvider.baseUrl}UserRating/GetAverageRating/$renterId');
    final response = await http!.get(url, headers: createHeaders());
    if (!isValidResponse(response)) return 0;
    return (jsonDecode(response.body) as num).toDouble();
  }

  Future<UserRating?> getByReservation({
    required int renterId,
    required int reviewerId,
    required int reservationId,
  }) async {
    final url = Uri.parse(
        '${BaseProvider.baseUrl}UserRating/GetFilteredData?RenterId=$renterId&ReviewerId=$reviewerId&ReservationId=$reservationId&Page=1&PageSize=1');
    final response = await http!.get(url, headers: createHeaders());
    if (!isValidResponse(response)) return null;
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List? ?? []);
    if (items.isEmpty) return null;
    return UserRating.fromJson(items.first as Map<String, dynamic>);
  }

  Future<void> addRating(UserRating rating) async {
    final url = Uri.parse('${BaseProvider.baseUrl}UserRating');
    final body = {
      ...rating.toJson(),
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
    final response = await http!.post(
      url,
      headers: createHeaders(),
      body: jsonEncode(body),
    );
    if (!isValidResponse(response)) {
      throw Exception('Failed to submit rating');
    }
  }

}
