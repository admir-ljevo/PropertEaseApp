import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/providers/base_provider.dart';

class RoleProvider extends BaseProvider<ApplicationRole> {
  RoleProvider() : super("Role");

  @override
  ApplicationRole fromJson(data) => ApplicationRole.fromJson(data);

  @override
  Map<String, dynamic> toJson(ApplicationRole data) => {
    'id': data.id ?? 0,
    'name': data.name,
    'roleLevel': data.roleLevel,
  };
}
