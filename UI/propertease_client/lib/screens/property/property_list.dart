import 'dart:async';

import 'package:flutter/material.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/providers/city_provider.dart';
import 'package:propertease_client/providers/property_provider.dart';
import 'package:propertease_client/providers/property_type_provider.dart';
import 'package:propertease_client/widgets/master_screen.dart';
import 'package:provider/provider.dart';

import '../../models/city.dart';
import '../../models/property.dart';
import '../../models/property_type.dart';
import 'property_details.dart';

class PropertyListWidget extends StatefulWidget {
  const PropertyListWidget({super.key});

  @override
  State<StatefulWidget> createState() => PropertyListWidgetState();
}

class PropertyListWidgetState extends State<PropertyListWidget> {
  late PropertyProvider _propertyProvider;
  late PropertyTypeProvider _propertyTypeProvider;
  late CityProvider _cityProvider;

  List<Property> _properties = [];
  List<PropertyType> _propertyTypes = [];
  List<City> _cities = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();

  City? _selectedCity;
  PropertyType? _selectedPropertyType;
  bool? _isAvailable;

  int _page = 1;
  static const int _pageSize = 10;
  int _totalCount = 0;
  bool _isLoading = false;

  Timer? _searchDebounce;
  @override
  void initState() {
    super.initState();
    _propertyProvider = context.read<PropertyProvider>();
    _cityProvider = context.read<CityProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _loadDropdowns();
    _fetchProperties();
  }

  Future<void> _loadDropdowns() async {
    final typeResult = await _propertyTypeProvider.get();
    final cityResult = await _cityProvider.get();
    if (mounted) {
      setState(() {
        _propertyTypes = typeResult.result;
        _cities = cityResult.result;
      });
    }
  }

  Future<void> _fetchProperties({int page = 1}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final minPrice = double.tryParse(_minPriceController.text);
      final maxPrice = double.tryParse(_maxPriceController.text);

      final result = await _propertyProvider.getFiltered(filter: {
        'name': _nameController.text,
        'cityId': _selectedCity?.id,
        'propertyTypeId': _selectedPropertyType?.id,
        'isAvailable': _isAvailable,
        'priceFrom': minPrice,
        'priceTo': maxPrice,
        'page': page,
        'pageSize': _pageSize,
      });

      if (mounted) {
        setState(() {
          _properties = result.result;
          _totalCount = result.count;
          _page = page;
        });
      }
    } catch (e) {
      debugPrint('fetchProperties error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Debounced search — waits 400 ms after the last keystroke before fetching.
  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      _fetchProperties();
    });
  }

  void _resetFilters() {
    setState(() {
      _selectedCity = null;
      _selectedPropertyType = null;
      _isAvailable = null;
      _nameController.clear();
      _minPriceController.clear();
      _maxPriceController.clear();
    });
    _fetchProperties();
  }

  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 9999);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      currentIndex: 0,
      titleWidget: const Text('Nekretnine'),
      child: Column(
        children: [
          _buildSearchBar(),
          const Divider(thickness: 2, color: Color(0xFF115892)),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_properties.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Nema dostupnih nekretnina.')),
            )
          else ...[
            Expanded(child: _buildList()),
            _buildPagination(),
          ],
        ],
      ),
    );
  }

  int get _activeFilterCount {
    int count = 0;
    if (_selectedCity != null) count++;
    if (_selectedPropertyType != null) count++;
    if (_isAvailable != null) count++;
    if (_minPriceController.text.isNotEmpty) count++;
    if (_maxPriceController.text.isNotEmpty) count++;
    return count;
  }

  Widget _buildSearchBar() {
    final filterCount = _activeFilterCount;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'Pretraži po nazivu...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          const SizedBox(width: 8),
          Badge(
            label: filterCount > 0 ? Text('$filterCount') : null,
            isLabelVisible: filterCount > 0,
            child: IconButton(
              tooltip: 'Filtri',
              icon: const Icon(Icons.tune, color: Color(0xFF115892)),
              onPressed: _showAdvancedFilter,
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedFilter() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<City?>(
                value: _selectedCity,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Grad'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Svi gradovi')),
                  ..._cities.map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.name ?? ''))),
                ],
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _selectedCity = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<PropertyType?>(
                value: _selectedPropertyType,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tip nekretnine'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Svi tipovi')),
                  ..._propertyTypes.map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.name ?? ''))),
                ],
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _selectedPropertyType = v);
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<bool?>(
                value: _isAvailable,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Dostupnost'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Sve')),
                  DropdownMenuItem(value: true, child: Text('Dostupno')),
                  DropdownMenuItem(value: false, child: Text('Zauzeto')),
                ],
                onChanged: (v) {
                  setSheetState(() {});
                  setState(() => _isAvailable = v);
                },
              ),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cijena od',
                        prefixIcon: Icon(Icons.euro)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Cijena do',
                        prefixIcon: Icon(Icons.euro)),
                  ),
                ),
              ]),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.clear),
                      label: const Text('Poništi'),
                      onPressed: () {
                        Navigator.pop(context);
                        _resetFilters();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Primijeni'),
                      onPressed: () {
                        Navigator.pop(context);
                        _fetchProperties();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _properties.length,
      itemBuilder: (context, index) => _buildCard(_properties[index]),
    );
  }

  Widget _buildCard(Property p) {
    final photoUrl = (p.firstPhotoUrl != null && p.firstPhotoUrl!.isNotEmpty)
        ? '${AppConfig.serverBase}${p.firstPhotoUrl}'
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => PropertyDetailsScreen(property: p))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image — URL included in list payload; no extra API call per item
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                      loadingBuilder: (_, child, progress) =>
                          progress == null ? child : _photoLoading(),
                    )
                  : _photoPlaceholder(),
            ),

            // Name + availability badge
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      p.name ?? '',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: _buildAvailabilityBadge(p.isAvailable ?? false, p.availableFrom),
                  ),
                ],
              ),
            ),

            // City & type
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Text(
                '${p.city?.name ?? ''}  •  ${p.propertyType?.name ?? ''}',
                style:
                    TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),

            // Stats row
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  _stat(Icons.bed, '${p.numberOfRooms ?? 0}'),
                  const SizedBox(width: 16),
                  _stat(Icons.bathtub, '${p.numberOfBathrooms ?? 0}'),
                  const SizedBox(width: 16),
                  _stat(Icons.aspect_ratio, '${p.squareMeters ?? 0} m²'),
                  const Spacer(),
                  if ((p.averageRating ?? 0) > 0)
                    Row(children: [
                      const Icon(Icons.star,
                          size: 16, color: Colors.amber),
                      Text(
                        ' ${p.averageRating!.toStringAsFixed(1)}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ]),
                ],
              ),
            ),

            // Price chips
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: [
                  if (p.isMonthly == true)
                    _priceChip('${p.monthlyPrice} BAM/mj.'),
                  if (p.isDaily == true) ...[
                    if (p.isMonthly == true) const SizedBox(width: 8),
                    _priceChip('${p.dailyPrice} BAM/dan'),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityBadge(bool available, DateTime? availableFrom) {
    final Color color;
    final String label;
    if (available) {
      color = Colors.green;
      label = 'Dostupno';
    } else if (availableFrom != null) {
      color = Colors.orange;
      final d = availableFrom;
      label = 'Dostupno od: ${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
    } else {
      color = Colors.red;
      label = 'Zauzeto';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _photoPlaceholder() => Container(
        height: 180,
        color: Colors.grey.shade200,
        child: const Center(
            child: Icon(Icons.home_work, size: 60, color: Colors.grey)),
      );

  Widget _photoLoading() => const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );

  Widget _stat(IconData icon, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700)),
        ],
      );

  Widget _priceChip(String text) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF115892),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      );

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _page > 1 ? () => _fetchProperties(page: _page - 1) : null,
          ),
          Text('$_page / $_totalPages',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _page < _totalPages
                ? () => _fetchProperties(page: _page + 1)
                : null,
          ),
          Text('Ukupno: $_totalCount',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }
}
