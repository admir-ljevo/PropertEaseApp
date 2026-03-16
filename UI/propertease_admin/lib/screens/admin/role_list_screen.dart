import 'package:flutter/material.dart';
import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/providers/application_role_provider.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

class RoleListScreen extends StatefulWidget {
  const RoleListScreen({super.key});

  @override
  State<RoleListScreen> createState() => _RoleListScreenState();
}

class _RoleListScreenState extends State<RoleListScreen> {
  late RoleProvider _provider;
  List<ApplicationRole> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<RoleProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _provider.get();
      if (mounted) setState(() => _items = result.result);
    } catch (e) {
      _showError('Failed to load roles: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showAddForm() async {
    final nameCtrl = TextEditingController();
    final levelCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Role Name'),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: levelCtrl,
              decoration: const InputDecoration(labelText: 'Role Level (optional)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
        ],
      ),
    );

    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      await _provider.addAsync(ApplicationRole(
        name: name,
        roleLevel: int.tryParse(levelCtrl.text.trim()),
      ));
      await _load();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _delete(ApplicationRole item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete role "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _provider.deleteById(item.id);
      await _load();
    } catch (e) {
      _showError('Error deleting: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title: 'Roles',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Roles', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF115892))),
                ElevatedButton.icon(
                  onPressed: _showAddForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Role'),
                ),
              ],
            ),
            const Divider(thickness: 1.5, height: 32),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_items.isEmpty)
              const Expanded(child: Center(child: Text('No roles found.')))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Level')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _items.map((r) => DataRow(cells: [
                      DataCell(Text(r.name ?? '')),
                      DataCell(Text(r.roleLevel?.toString() ?? '')),
                      DataCell(
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _delete(r),
                        ),
                      ),
                    ])).toList(),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
