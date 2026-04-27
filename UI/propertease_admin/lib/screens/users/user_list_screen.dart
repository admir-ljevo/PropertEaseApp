import 'package:flutter/material.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/screens/users/client_add_screen.dart';
import 'package:propertease_admin/screens/users/user_detail_screen.dart';
import 'package:propertease_admin/screens/users/user_edit_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
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
  List<ApplicationUser> users = [];
  List<City> cities = [];
  SearchResult<City>? fetchedCities;
  TextEditingController _searchController = TextEditingController();
  City? selectedCity;
  String? selectedRole;
  int? cityId;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _pageSize = 10;

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      titleWidget: const Text('Korisnici'),
      child: Column(
        children: [
          _buildContent(),
          _buildSearchBar(),
          const Divider(height: 1),
          Expanded(child: _buildDataListView()),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _cityProvider = context.read<CityProvider>();
    fetchData();
  }

  Widget _buildContent() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1976D2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Row(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Korisnici',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 2),
              Text('Lista i upravljanje korisnicima',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context)
                  .push(MaterialPageRoute(
                      builder: (context) => const UserAddScreen()))
                  .then((_) => fetchUsers());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF1565C0),
            ),
            icon: const Icon(Icons.person_add_outlined),
            label: const Text('Dodaj korisnika'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              controller: _searchController,
              onChanged: (value) async {
                setState(() => _currentPage = 1);
                await fetchUsers();
              },
              decoration: const InputDecoration(
                hintText: 'Pretraži po imenu ili emailu',
                prefixIcon: Icon(Icons.search),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<String?>(
              value: selectedRole,
              isExpanded: true,
              onChanged: (value) {
                setState(() { selectedRole = value; _currentPage = 1; });
                fetchUsers();
              },
              items: const [
                DropdownMenuItem<String?>(value: null, child: Text('Sve uloge')),
                DropdownMenuItem<String?>(value: 'Client', child: Text('Klijent')),
                DropdownMenuItem<String?>(value: 'Employee', child: Text('Izdavač')),
              ],
              decoration: const InputDecoration(labelText: 'Uloga', isDense: true),
            ),
          ),
          SizedBox(
            width: 160,
            child: DropdownButtonFormField<City?>(
              value: selectedCity,
              isExpanded: true,
              onChanged: (City? newValue) async {
                setState(() {
                  selectedCity = newValue;
                  cityId = newValue?.id;
                  _currentPage = 1;
                });
                await fetchUsers();
              },
              items: [
                const DropdownMenuItem<City?>(value: null, child: Text('Svi gradovi')),
                ...cities.where((c) => c.name != null).map(
                    (c) => DropdownMenuItem<City?>(value: c, child: Text(c.name!))),
              ],
              decoration: const InputDecoration(labelText: 'Grad', isDense: true),
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _searchController.text = '';
                selectedCity = null;
                cityId = null;
                selectedRole = null;
                _currentPage = 1;
              });
              fetchUsers();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Očisti'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataListView() {
    if (users.isEmpty) {
      return const Center(child: Text('Nema pronađenih korisnika.'));
    }
    final totalPages = (_totalCount / _pageSize).ceil();
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: users.length,
            itemBuilder: (_, i) => _buildUserCard(users[i]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () { setState(() => _currentPage--); fetchUsers(); }
                    : null,
              ),
              Text('$_currentPage / ${totalPages > 0 ? totalPages : 1}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages
                    ? () { setState(() => _currentPage++); fetchUsers(); }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(ApplicationUser e) {
    final cs = Theme.of(context).colorScheme;
    final roleName = e.userRoles != null && e.userRoles!.isNotEmpty
        ? e.userRoles![0].role?.name ?? ''
        : '';
    final initials = [e.person?.firstName, e.person?.lastName]
        .where((s) => s != null && s.isNotEmpty)
        .map((s) => s![0].toUpperCase())
        .join();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: cs.primaryContainer,
              child: Text(
                initials.isNotEmpty ? initials : '?',
                style: TextStyle(
                    color: cs.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(e.userName ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      const SizedBox(width: 8),
                      if (roleName.isNotEmpty)
                        Chip(
                          label: Text(roleName,
                              style: const TextStyle(fontSize: 11)),
                          backgroundColor: cs.primaryContainer,
                          side: BorderSide.none,
                          labelStyle: TextStyle(color: cs.primary),
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(e.email ?? '',
                      style: TextStyle(
                          color: Colors.grey.shade600, fontSize: 12)),
                  if ((e.person?.placeOfResidence?.name ?? '').isNotEmpty ||
                      (e.phoneNumber ?? '').isNotEmpty)
                    Text(
                      [
                        if ((e.person?.placeOfResidence?.name ?? '').isNotEmpty)
                          e.person!.placeOfResidence!.name!,
                        if ((e.phoneNumber ?? '').isNotEmpty) e.phoneNumber!,
                      ].join(' · '),
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 12),
                    ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.info_outline, size: 20, color: cs.primary),
                  tooltip: 'Detalji',
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => UserDetailScreen(user: e)))
                      .then((_) => fetchUsers()),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, size: 20, color: cs.primary),
                  tooltip: 'Uredi',
                  onPressed: () => Navigator.of(context)
                      .push(MaterialPageRoute(
                          builder: (_) => UserEditScreen(user: e)))
                      .then((_) => fetchUsers()),
                ),
                IconButton(
                  icon: const Icon(Icons.lock_reset, size: 20, color: Colors.orange),
                  tooltip: 'Resetuj lozinku',
                  onPressed: () => _showResetPasswordDialog(e),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                  tooltip: 'Obriši',
                  onPressed: () => showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Potvrdi brisanje'),
                      content: Text(
                          'Jeste li sigurni da želite obrisati "${e.userName ?? "ovog korisnika"}"?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Odustani')),
                        TextButton(
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                          onPressed: () => _handleDeleteUser(e.id),
                          child: const Text('Obriši'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
      final result = await _userProvider.get(filter: {
        'SearchField': _searchController.text,
        'CityId': cityId,
        'Role': selectedRole,
        'Page': _currentPage,
        'PageSize': _pageSize,
      });
      setState(() {
        users = result.result;
        _totalCount = result.totalCount;
      });
    } catch (error) {
      print("Error fetching data: $error");
    }
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

  Future<void> _showResetPasswordDialog(ApplicationUser user) async {
    final controller = TextEditingController();
    bool obscure = true;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          title: Text('Reset password – ${user.userName ?? ''}'),
          content: TextField(
            controller: controller,
            obscureText: obscure,
            decoration: InputDecoration(
              labelText: 'New password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setDlgState(() => obscure = !obscure),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPwd = controller.text.trim();
                if (newPwd.isEmpty) return;
                Navigator.pop(ctx);
                try {
                  await _userProvider.adminResetPassword(user.id!, newPwd);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password reset successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Reset'),
            ),
          ],
        ),
      ),
    );

    controller.dispose();
  }

  Future<void> fetchData() async {
    try {
      await fetchUsers();
      fetchedCities = await _cityProvider.get();
    } catch (error) {
      print("Error fetching data: $error");
    }
    setState(() {
      cities = fetchedCities?.result ?? [];
    });
  }
}
