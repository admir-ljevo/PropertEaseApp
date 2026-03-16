import 'package:flutter/material.dart';
import 'package:propertease_admin/models/country.dart';
import 'package:propertease_admin/providers/country_provider.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

class CountryListScreen extends StatefulWidget {
  const CountryListScreen({super.key});

  @override
  State<CountryListScreen> createState() => _CountryListScreenState();
}

class _CountryListScreenState extends State<CountryListScreen> {
  late CountryProvider _provider;
  List<Country> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _provider = context.read<CountryProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _provider.get();
      if (mounted) setState(() => _items = result.result);
    } catch (e) {
      _showError('Failed to load countries: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({Country? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    final isEdit = item != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit Country' : 'Add Country'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    try {
      if (isEdit) {
        await _provider.updateAsync(item.id, Country(id: item.id, name: name));
      } else {
        await _provider.addAsync(Country(name: name));
      }
      await _load();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _delete(Country item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete country "${item.name}"?'),
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
      title: 'Countries',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Countries', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF115892))),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Country'),
                ),
              ],
            ),
            const Divider(thickness: 1.5, height: 32),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_items.isEmpty)
              const Expanded(child: Center(child: Text('No countries found.')))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _items.map((c) => DataRow(cells: [
                      DataCell(Text(c.name ?? '')),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Color(0xFF115892)), onPressed: () => _showForm(item: c)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(c)),
                      ])),
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
