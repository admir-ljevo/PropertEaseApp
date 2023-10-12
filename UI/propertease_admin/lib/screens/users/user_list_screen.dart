import 'package:flutter/material.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

class UserListWidget extends StatefulWidget {
  const UserListWidget({super.key});

  @override
  State<StatefulWidget> createState() => UserListWidgetState();
}

class UserListWidgetState extends State<UserListWidget> {
  late UserProvider _userProvider;
  late List<ApplicationUser> users = [];
  late List<ApplicationUser> fetchedUsers = [];
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MasterScreenWidget(
      title_widget: const Text("Users list"),
      child: Column(children: [
        _buildContent(),
        _buildDataListView(),
      ]),
    );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _userProvider = context.read<UserProvider>();
    fetchData();
  }

  Widget _buildContent() {
    return const Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 100,
            ),
            Text(
              "Users list view",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            Spacer(), // To push the icon to the right side
            Icon(
              Icons
                  .person, // You can replace this with the building icon you want
              size: 80,
              color: Color(0xFF115892),
            ),
            SizedBox(
              width: 100,
            ),
          ],
        ),
        Divider(
          thickness: 2,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildDataListView() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SingleChildScrollView(
          child: DataTable(
              columns: const [
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "User name",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Role",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Email",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "City",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Phone number",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Address",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
                DataColumn(
                  label: Expanded(
                    child: Text(
                      "Actions",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ),
                ),
              ],
              rows: users
                      .map((ApplicationUser e) => DataRow(cells: [
                            DataCell(Text(e.userName ?? '')),
                            DataCell(
                              Text(
                                  e.userRoles != null && e.userRoles!.isNotEmpty
                                      ? e.userRoles![0].role?.name ?? ''
                                      : ''),
                            ),
                            DataCell(Text(e.email ?? '')),
                            DataCell(
                                Text(e.person?.placeOfResidence?.name ?? '')),
                            DataCell(
                              Text(e.phoneNumber ?? '225-883'),
                            ),
                            DataCell(
                              Text(e.person?.address ?? ''),
                            ),
                            DataCell(
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  InkWell(
                                    onTap: () {
                                      // Add your Details action here
                                      print('Details');
                                    },
                                    child: const Icon(Icons.info),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      // Add your Edit action here
                                      print('Edit');
                                    },
                                    child: const Icon(Icons.edit),
                                  ),
                                  const SizedBox(width: 16),
                                  InkWell(
                                    onTap: () {
                                      // Add your Delete action here
                                      print('Delete');
                                    },
                                    child: const Icon(Icons.delete),
                                  ),
                                ],
                              ),
                            )
                          ]))
                      .toList() ??
                  []),
        )
      ],
    );
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      fetchedUsers = await _userProvider.getAllUsers();
    } catch (error) {
      print("Error fetching data: $error");
    }
    setState(() {
      users = fetchedUsers;
    });
  }
}
