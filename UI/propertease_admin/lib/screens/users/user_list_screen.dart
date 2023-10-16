import 'package:flutter/material.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/screens/users/client_add_screen.dart';
import 'package:propertease_admin/screens/users/user_detail_screen.dart';
import 'package:propertease_admin/screens/users/user_edit_screen.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

import '../../providers/city_provider.dart';

class UserListWidget extends StatefulWidget {
  const UserListWidget({super.key});

  @override
  State<StatefulWidget> createState() => UserListWidgetState();
}

class UserListWidgetState extends State<UserListWidget> {
  late UserProvider _userProvider;
  late CityProvider _cityProvider;
  late List<ApplicationUser> users = [];
  late List<ApplicationUser> fetchedUsers = [];
  late List<City> cities = [];
  late SearchResult<City> fetchedCities;
  TextEditingController _searchController = TextEditingController();
  String searchQuery = ''; // To store the search query
  City? selectedCity;
  String? selectedRole;
  int? cityId;
  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
        title_widget: const Text("Users list"),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildContent(),
              _buildSearchBar(),
              _buildDataListView(),
            ],
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _cityProvider = context.read<CityProvider>();
    fetchData();
  }

  Widget _buildContent() {
    return Column(
      children: [
        const Row(
          children: [
            SizedBox(
              width: 100,
            ),
            Text(
              "Users",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            Spacer(),
            Icon(
              Icons.person,
              size: 80,
              color: Color(0xFF115892),
            ),
            SizedBox(
              width: 100,
            ),
          ],
        ),
        const Divider(
          thickness: 2,
          color: Colors.blue,
        ),
        const SizedBox(
          height: 50,
        ),
        Row(
          children: [
            const SizedBox(
              width: 100,
            ),
            const Text(
              "Users list view",
              style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF115892)),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      // Add your button's onPressed logic here
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add), // Add your desired icon
                        SizedBox(width: 8), // Adjust the width as needed
                        Text("Add new renter"), // Text for the button
                      ],
                    ),
                  ),
                ),
                const SizedBox(
                  width: 15,
                ),
                Container(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ClientAddScreen(),
                        ),
                      );
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add), // Add your desired icon
                        SizedBox(width: 8), // Adjust the width as needed
                        Text("Add new client"), // Text for the button
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              width: 100,
            ),
          ],
        ),
        const SizedBox(
          height: 50,
        ),
        const Divider(
          thickness: 2,
          color: Colors.blue,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) async {
              await fetchUsers();
            },
            decoration: const InputDecoration(
              hintText: 'Search by user name or email',
              prefixIcon: Icon(Icons.search), // Add a search icon
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: selectedRole,
                  onChanged: (value) {
                    selectedRole = value;
                    fetchUsers();
                  },
                  items: <String>['Client', 'Employee'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'Select Role',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<City?>(
                  value: selectedCity,
                  onChanged: (City? newValue) async {
                    setState(() {
                      selectedCity = newValue;
                      cityId = newValue?.id;
                      fetchUsers();
                    });
                  },
                  items:
                      (cities ?? []).map<DropdownMenuItem<City?>>((City? city) {
                    if (city != null && city.name != null) {
                      return DropdownMenuItem<City?>(
                        value: city,
                        child: Text(city.name!),
                      );
                    } else {
                      return const DropdownMenuItem<City?>(
                        value: null,
                        child: Text('Undefined'),
                      );
                    }
                  }).toList(),
                  decoration: const InputDecoration(
                    labelText: 'City',
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                onPressed: () {
                  _searchController.text = '';
                  selectedCity = null;
                  cityId = null;
                  selectedRole = null;
                  fetchUsers();
                },
                child: const Row(
                  children: [
                    Icon(Icons.close), // Close (X) icon
                    SizedBox(width: 8), // Adjust the width as needed
                    Text('Clear filters'),
                  ],
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataListView() {
    return Column(
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
                    .where((user) {
                      final username = user.userName ?? '';
                      final email = user.email ?? '';
                      final role =
                          user.userRoles != null && user.userRoles!.isNotEmpty
                              ? user.userRoles![0].role?.name ?? ''
                              : '';
                      return username.contains(searchQuery) ||
                          email.contains(searchQuery) ||
                          (selectedRole!.isNotEmpty && role == selectedRole);
                    })
                    .map((ApplicationUser e) => DataRow(cells: [
                          DataCell(Text(e.userName ?? '')),
                          DataCell(
                            Text(e.userRoles != null && e.userRoles!.isNotEmpty
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
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserDetailScreen(
                                          user: e,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.info),
                                ),
                                const SizedBox(width: 16),
                                InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => UserEditScreen(
                                          user: e,
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Icon(Icons.edit),
                                ),
                                const SizedBox(width: 16),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: const Text("Confirm Delete"),
                                          content: const Text(
                                              "Are you sure you want to delete this user?"),
                                          actions: <Widget>[
                                            TextButton(
                                              child: const Text("Cancel"),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: const Text("Delete"),
                                              onPressed: () async {
                                                _handleDeleteUser(e.id);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: const Icon(Icons.delete),
                                ),
                              ],
                            ),
                          )
                        ]))
                    .toList() ??
                [],
          ),
        ),
      ],
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _userProvider = context.read<UserProvider>();
    _cityProvider = context.read<CityProvider>();
    fetchData();
  }

  Future<void> fetchUsers() async {
    try {
      fetchedUsers = await _userProvider.get(filter: {
        'SearchField': _searchController.text,
        'CityId': cityId,
        'Role': selectedRole
      });
    } catch (error) {
      print("Error fetching data: $error");
    }
    setState(() {
      users = fetchedUsers;
    });
  }

  Future<void> _handleDeleteUser(int? userId) async {
    try {
      await _userProvider.deleteById(userId);
      await fetchUsers();
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print("Error deleting user: $e ");
    }
  }

  Future<void> fetchData() async {
    try {
      await fetchUsers();
      fetchedCities = await _cityProvider.get();
    } catch (error) {
      print("Error fetching data: $error");
    }
    setState(() {
      cities = fetchedCities.result ?? [];
    });
  }
}
