import 'package:flutter/material.dart';
import 'package:propertease_admin/models/city.dart';
import 'package:propertease_admin/models/property.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/city_provider.dart';

import 'package:propertease_admin/providers/property_provider.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/utils/debounce.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'property_add_screen.dart';
import 'property_detail_screen.dart';
import 'property_edit_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});
  @override
  State<PropertyListWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  // Providers resolved once in initState
  late final PropertyProvider _propertyProvider;
  late final PropertyTypeProvider _propertyTypeProvider;
  late final CityProvider _cityProvider;

  SearchResult<Property>? _result;
  // Reference data loaded ONCE per screen lifetime, not on every search call
  List<PropertyType> _propertyTypes = [];
  List<City> _cities = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  City? _selectedCity;
  PropertyType? _selectedType;
  bool? _isAvailable;
  bool _isLoading = false;
  String? _error;
  final _debounce = Debounce(); // 400 ms — prevents firing on every keystroke

  // ── lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Resolved here once — no didChangeDependencies needed (removed double-init)
    _propertyProvider = context.read<PropertyProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _cityProvider = context.read<CityProvider>();
    _loadReferenceDataThenProperties();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  // ── data loading ───────────────────────────────────────────────────────────

  Future<void> _loadReferenceDataThenProperties() async {
    try {
      final typesResult = await _propertyTypeProvider.get();
      final citiesResult = await _cityProvider.get();
      if (!mounted) return;
      setState(() {
        _propertyTypes = typesResult.result;
        _cities = citiesResult.result;
      });
    } catch (_) {}
    await _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _propertyProvider.getFiltered(filter: {
        'name': _nameController.text.trim(),
        'cityId': _selectedCity?.id,
        'propertyTypeId': _selectedType?.id,
        'isAvailable': _isAvailable,
        'priceFrom': double.tryParse(_minPriceController.text),
        'priceTo': double.tryParse(_maxPriceController.text),
      });
      if (!mounted) return;
      setState(() => _result = result);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Greška pri učitavanju nekretnina.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFilters() {
    setState(() {
      _selectedCity = null;
      _selectedType = null;
      _isAvailable = null;
    });
    _nameController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    _fetchProperties();
  }

  Future<void> _deleteProperty(int id) async {
    // Capture before any await to avoid using BuildContext across async gaps
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _propertyProvider.deleteById(id);
      nav.pop();
      await _fetchProperties();
      messenger.showSnackBar(const SnackBar(
          content: Text('Nekretnina uspješno obrisana.'),
          backgroundColor: Colors.green));
    } catch (_) {
      nav.pop();
      messenger.showSnackBar(const SnackBar(
          content: Text('Greška pri brisanju.'),
          backgroundColor: Colors.red));
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      titleWidget: const Text('Nekretnine'),
      child: Column(children: [
        _buildHeader(),
        _buildSearchBar(),
        const Divider(height: 1),
        Expanded(child: _buildBody()),
      ]),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(children: [
        const Text('Lista nekretnina',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF115892))),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: () async {
            await Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => PropertyAddScreen()));
            await _fetchProperties(); // auto-refresh after add
          },
          icon: const Icon(Icons.add),
          label: const Text('Dodaj nekretninu'),
        ),
      ]),
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
              width: 200,
              child: TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                    labelText: 'Naziv',
                    prefixIcon: Icon(Icons.search),
                    isDense: true),
                onChanged: (_) => _debounce.run(_fetchProperties),
              )),
          SizedBox(
              width: 160,
              child: DropdownButtonFormField<City?>(
                value: _selectedCity,
                decoration:
                    const InputDecoration(labelText: 'Grad', isDense: true),
                items: [
                  const DropdownMenuItem<City?>(
                      value: null, child: Text('Svi gradovi')),
                  ..._cities.map((c) => DropdownMenuItem<City?>(
                      value: c, child: Text(c.name ?? ''))),
                ],
                onChanged: (v) {
                  setState(() => _selectedCity = v);
                  _fetchProperties();
                },
              )),
          SizedBox(
              width: 160,
              child: DropdownButtonFormField<PropertyType?>(
                value: _selectedType,
                decoration:
                    const InputDecoration(labelText: 'Tip', isDense: true),
                items: [
                  const DropdownMenuItem<PropertyType?>(
                      value: null, child: Text('Svi tipovi')),
                  ..._propertyTypes.map((t) => DropdownMenuItem<PropertyType?>(
                      value: t, child: Text(t.name ?? ''))),
                ],
                onChanged: (v) {
                  setState(() => _selectedType = v);
                  _fetchProperties();
                },
              )),
          SizedBox(
              width: 140,
              child: DropdownButtonFormField<bool?>(
                value: _isAvailable,
                decoration:
                    const InputDecoration(labelText: 'Status', isDense: true),
                items: const [
                  DropdownMenuItem<bool?>(value: null, child: Text('Sve')),
                  DropdownMenuItem<bool?>(
                      value: true, child: Text('Dostupno')),
                  DropdownMenuItem<bool?>(
                      value: false, child: Text('Iznajmljeno')),
                ],
                onChanged: (v) {
                  setState(() => _isAvailable = v);
                  _fetchProperties();
                },
              )),
          SizedBox(
              width: 120,
              child: TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cijena od', isDense: true),
                onChanged: (_) => _debounce.run(_fetchProperties),
              )),
          SizedBox(
              width: 120,
              child: TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Cijena do', isDense: true),
                onChanged: (_) => _debounce.run(_fetchProperties),
              )),
          TextButton.icon(
            onPressed: _clearFilters,
            icon: const Icon(Icons.clear),
            label: const Text('Očisti'),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, style: const TextStyle(color: Colors.red)),
        const SizedBox(height: 12),
        ElevatedButton(
            onPressed: _fetchProperties,
            child: const Text('Pokušaj ponovo')),
      ]));
    }
    final rows = _result?.result ?? [];
    if (rows.isEmpty) {
      return const Center(child: Text('Nema pronađenih nekretnina.'));
    }

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor:
              MaterialStateProperty.all(const Color(0xFFE3F2FD)),
          columns: const [
            DataColumn(label: Text('Tip')),
            DataColumn(label: Text('Naziv')),
            DataColumn(label: Text('Grad')),
            DataColumn(label: Text('Adresa')),
            DataColumn(label: Text('Cijena')),
            DataColumn(label: Text('Status')),
            DataColumn(label: Text('Akcije')),
          ],
          rows: rows.map((e) {
            // FIXED: always exactly 7 cells, no conditional if inside cells list
            final priceLabel = e.isDaily == true
                ? '${e.dailyPrice} BAM/dan'
                : e.isMonthly == true
                    ? '${e.monthlyPrice} BAM/mj.'
                    : '/';
            final statusLabel =
                e.isAvailable == true ? 'Dostupno' : 'Iznajmljeno';
            final statusColor =
                e.isAvailable == true ? Colors.green : Colors.orange;
            return DataRow(cells: [
              DataCell(Text(e.propertyType?.name ?? '/')),
              DataCell(Text(e.name ?? '/')),
              DataCell(Text(e.city?.name ?? '/')),
              DataCell(Text(e.address ?? '/')),
              DataCell(Text(priceLabel)),
              DataCell(Text(statusLabel,
                  style: TextStyle(
                      color: statusColor, fontWeight: FontWeight.w600))),
              DataCell(_buildActions(e)),
            ]);
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildActions(Property e) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
          icon: const Icon(Icons.edit, size: 20),
          tooltip: 'Uredi',
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => PropertyEditScreen(property: e)));
            await _fetchProperties(); // auto-refresh after edit
          }),
      IconButton(
          icon: const Icon(Icons.delete, size: 20, color: Colors.red),
          tooltip: 'Obriši',
          onPressed: () => _showDeleteDialog(e)),
      IconButton(
          icon: const Icon(Icons.info_outline, size: 20),
          tooltip: 'Detalji',
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => PropertyDetailScreen(property: e)))),
    ]);
  }

  void _showDeleteDialog(Property e) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Potvrda brisanja'),
        content: Text(
            'Jeste li sigurni da želite obrisati "${e.name ?? "ovu nekretninu"}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Odustani')),
          TextButton(
            onPressed: () => _deleteProperty(e.id!),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }
}
