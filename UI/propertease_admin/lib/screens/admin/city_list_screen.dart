import 'package:flutter/material.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/country.dart';
import 'package:propertease_admin/providers/city_provider.dart';
import 'package:propertease_admin/providers/country_provider.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

class CityListScreen extends StatefulWidget {
  const CityListScreen({super.key});

  @override
  State<CityListScreen> createState() => _CityListScreenState();
}

class _CityListScreenState extends State<CityListScreen> {
  late CityProvider _cityProvider;
  late CountryProvider _countryProvider;
  List<City> _cities = [];
  List<Country> _countries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _cityProvider = context.read<CityProvider>();
    _countryProvider = context.read<CountryProvider>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _cityProvider.get(),
        _countryProvider.get(),
      ]);
      if (mounted) {
        setState(() {
          _cities = results[0].result as List<City>;
          _countries = results[1].result as List<Country>;
        });
      }
    } catch (e) {
      _showError('Failed to load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({City? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    Country? selectedCountry = item?.countryId != null
        ? _countries.where((c) => c.id == item!.countryId).isEmpty
            ? null
            : _countries.firstWhere((c) => c.id == item!.countryId)
        : null;
    final isEdit = item != null;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: Text(isEdit ? 'Edit City' : 'Add City'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Country>(
                value: selectedCountry,
                decoration: const InputDecoration(labelText: 'Country'),
                items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
                onChanged: (v) => setDlg(() => selectedCountry = v),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty || selectedCountry == null) {
      _showError('Name and country are required.');
      return;
    }

    try {
      final city = City(item?.id, name, selectedCountry!.id);
      if (isEdit) {
        await _cityProvider.updateAsync(item.id, city);
      } else {
        await _cityProvider.addAsync(city);
      }
      await _load();
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _delete(City item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Delete city "${item.name}"?'),
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
      await _cityProvider.deleteById(item.id);
      await _load();
    } catch (e) {
      _showError('Error deleting: $e');
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  String _countryName(int? countryId) {
    if (countryId == null) return '';
    final matches = _countries.where((c) => c.id == countryId);
    return matches.isEmpty ? '' : matches.first.name ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title: 'Cities',
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Cities', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF115892))),
                ElevatedButton.icon(
                  onPressed: () => _showForm(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add City'),
                ),
              ],
            ),
            const Divider(thickness: 1.5, height: 32),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_cities.isEmpty)
              const Expanded(child: Center(child: Text('No cities found.')))
            else
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Country')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _cities.map((c) => DataRow(cells: [
                      DataCell(Text(c.name ?? '')),
                      DataCell(Text(_countryName(c.countryId))),
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
