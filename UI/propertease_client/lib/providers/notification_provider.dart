import 'package:propertease_client/models/new.dart';
import 'package:propertease_client/providers/base_provider.dart';

class NotificationProvider extends BaseProvider<New> {
  NotificationProvider() : super('Notification');

  @override
  New fromJson(data) => New.fromJson(data as Map<String, dynamic>);

  @override
  Map<String, dynamic> toJson(New data) => data.toJson();
}
