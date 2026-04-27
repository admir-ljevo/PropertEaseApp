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
  int _currentPage = 1;
  int _totalCount = 0;
  static const int _pageSize = 10;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cityProvider = context.read<CityProvider>();
    _countryProvider = context.read<CountryProvider>();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _cityProvider.getFiltered(filter: {
          'search': _searchCtrl.text.trim(),
          'page': _currentPage,
          'pageSize': _pageSize,
        }),
        _countryProvider.get(),
      ]);
      if (mounted) {
        setState(() {
          _cities = results[0].result as List<City>;
          _totalCount = results[0].totalCount;
          _countries = results[1].result as List<Country>;
        });
      }
    } catch (e) {
      _showError('Failed to load: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadCities() async {
    setState(() => _loading = true);
    try {
      final result = await _cityProvider.getFiltered(filter: {
        'search': _searchCtrl.text.trim(),
        'page': _currentPage,
        'pageSize': _pageSize,
      });
      if (mounted) setState(() { _cities = result.result; _totalCount = result.totalCount; });
    } catch (e) {
      _showError('Failed to load cities: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _showForm({City? item}) async {
    final nameCtrl = TextEditingController(text: item?.name ?? '');
    
    final formKey = GlobalKey<FormState>();

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
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField( 
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Name'),
                  autofocus: true,
                  validator: (v) => (v == null || v.isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Country>(
                  value: selectedCountry,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c.name ?? ''))).toList(),
                  onChanged: (v) => setDlg(() => selectedCountry = v),
                  validator: (v) => v == null ? 'Country is required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(ctx, true);
                }
              }, 
              child: Text(isEdit ? 'Save' : 'Add')
            ),
          ],
        ),
      ),
    );


    if (confirmed != true) return;
    final name = nameCtrl.text.trim();
    if (name.isEmpty || selectedCountry == null) { _showError('Name and country are required.'); return; }

    try {
      final city = City(item?.id, name, selectedCountry!.id);
      if (isEdit) {
        await _cityProvider.updateAsync(item.id, city);
      } else {
        await _cityProvider.addAsync(city);
        setState(() => _currentPage = 1);
      }
      await _loadCities();
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
      if (_cities.length == 1 && _currentPage > 1) setState(() => _currentPage--);
      await _loadCities();
    } catch (e) {
      _showError('Error deleting: $e');
    }
  }

  String _countryName(int? countryId) {
    if (countryId == null) return '';
    final match = _countries.where((c) => c.id == countryId);
    return match.isEmpty ? '' : match.first.name ?? '';
  }

  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 999);

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
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
                ElevatedButton.icon(onPressed: () => _showForm(), icon: const Icon(Icons.add), label: const Text('Add City')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: 300,
              child: TextField(
                controller: _searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search cities...',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
                onChanged: (_) { setState(() => _currentPage = 1); _loadCities(); },
              ),
            ),
            const Divider(thickness: 1.5, height: 24),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_cities.isEmpty)
              const Expanded(child: Center(child: Text('No cities found.')))
            else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFFE8EAF6)),
                    columns: const [
                      DataColumn(label: Text('Name')),
                      DataColumn(label: Text('Country')),
                      DataColumn(label: Text('Actions')),
                    ],
                    rows: _cities.map((c) => DataRow(cells: [
                      DataCell(Text(c.name ?? '')),
                      DataCell(Text(_countryName(c.countryId))),
                      DataCell(Row(children: [
                        IconButton(icon: const Icon(Icons.edit, color: Color(0xFF1565C0)), onPressed: () => _showForm(item: c)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(c)),
                      ])),
                    ])).toList(),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1 ? () { setState(() => _currentPage--); _loadCities(); } : null,
                  ),
                  Text('$_currentPage / $_totalPages'),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages ? () { setState(() => _currentPage++); _loadCities(); } : null,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
