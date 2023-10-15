import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class RoleProvider extends BaseProvider<ApplicationRole> {
  RoleProvider() : super("Role") {}
  @override
  ApplicationRole fromJson(data) {
    return ApplicationRole.fromJson(data);
  }
}
