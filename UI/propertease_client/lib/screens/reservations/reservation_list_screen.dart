import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/models/property_reservation.dart';
import 'package:propertease_client/models/search_result.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:propertease_client/utils/reservation_status.dart';
import 'package:propertease_client/widgets/master_screen.dart';
import 'package:provider/provider.dart';
import 'reservation_detail_screen.dart';

class ReservationListScreen extends StatefulWidget {
  const ReservationListScreen({super.key});

  @override
  State<StatefulWidget> createState() => ReservationListScreenState();
}

class ReservationListScreenState extends State<ReservationListScreen> {
  late PropertyReservationProvider _reservationProvider;

  SearchResult<PropertyReservation>? _result;
  bool _loading = true;
  String? _error;

  int _currentPage = 1;
  static const int _pageSize = 5;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  DateTime? _selectedDateStart;
  DateTime? _selectedDateEnd;
  int? _selectedStatus;

  int? get userId => Authorization.userId;

  @override
  void initState() {
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _fetchReservations();
  }

  Future<void> _fetchReservations({int page = 1}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _reservationProvider.getFiltered(filter: {
        'clientId': userId,
        'propertyName': _nameController.text.isNotEmpty ? _nameController.text : null,
        'totalPriceFrom': _minPriceController.text.isNotEmpty ? double.tryParse(_minPriceController.text) : null,
        'totalPriceTo': _maxPriceController.text.isNotEmpty ? double.tryParse(_maxPriceController.text) : null,
        'dateOccupancyStartedStart': _selectedDateStart,
        'dateOccupancyStartedEnd': _selectedDateEnd,
        'status': _selectedStatus,
        'page': page,
        'pageSize': _pageSize,
      });
      setState(() {
        _result = result;
        _currentPage = page;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter reservations'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Property name',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _minPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Min price'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _maxPriceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Max price'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text('From: '),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (d != null) setState(() => _selectedDateStart = d);
                    },
                    child: Text(_selectedDateStart != null
                        ? DateFormat('dd.MM.yyyy').format(_selectedDateStart!)
                        : 'Select'),
                  ),
                ],
              ),
              Row(
                children: [
                  const Text('To:   '),
                  TextButton(
                    onPressed: () async {
                      final d = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (d != null) setState(() => _selectedDateEnd = d);
                    },
                    child: Text(_selectedDateEnd != null
                        ? DateFormat('dd.MM.yyyy').format(_selectedDateEnd!)
                        : 'Select'),
                  ),
                ],
              ),
              DropdownButtonFormField<int?>(
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi statusi')),
                  DropdownMenuItem(value: 0, child: Text('Na čekanju')),
                  DropdownMenuItem(value: 1, child: Text('Potvrđena')),
                  DropdownMenuItem(value: 2, child: Text('Završena')),
                  DropdownMenuItem(value: 3, child: Text('Otkazana')),
                  DropdownMenuItem(value: 4, child: Text('Plaćena')),
                ],
                onChanged: (v) => setState(() => _selectedStatus = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _nameController.clear();
              _minPriceController.clear();
              _maxPriceController.clear();
              setState(() {
                _selectedDateStart = null;
                _selectedDateEnd = null;
                _selectedStatus = null;
              });
              Navigator.of(ctx).pop();
              _fetchReservations();
            },
            child: const Text('Clear'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _fetchReservations();
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = _result == null || _result!.count == 0
        ? 1
        : ((_result!.count) / _pageSize).ceil();

    return MasterScreenWidget(
      currentIndex: 1,
      titleWidget: Row(
        children: [
          const Text('Rezervacije'),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Expanded(child: _buildList()),
                    _buildPagination(totalPages),
                  ],
                ),
    );
  }

  Widget _buildList() {
    final items = _result?.result ?? [];
    if (items.isEmpty) {
      return const Center(child: Text('No reservations found.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (ctx, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(PropertyReservation r) {
    final photos = r.property?.photos;
    final rawUrl = (photos != null && photos.isNotEmpty) ? photos.first.url : null;
    final photoUrl = (rawUrl != null && rawUrl.isNotEmpty) ? '${AppConfig.serverBase}$rawUrl' : null;
    final startFmt = r.dateOfOccupancyStart != null
        ? DateFormat('dd.MM.yyyy').format(r.dateOfOccupancyStart!)
        : '-';
    final endFmt = r.dateOfOccupancyEnd != null
        ? DateFormat('dd.MM.yyyy').format(r.dateOfOccupancyEnd!)
        : '-';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ReservationDetailsScreen(reservationId: r.id!),
          ));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: photoUrl != null
                  ? Image.network(
                      photoUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.property?.name ?? '-',
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                      ),
                      ReservationStatus.chip(r.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_city, size: 14,
                          color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(r.property?.city?.name ?? '-',
                          style: const TextStyle(
                              fontSize: 13, color: Colors.grey)),
                      const SizedBox(width: 12),
                      const Icon(Icons.place, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(r.property?.address ?? '-',
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.blueGrey),
                      const SizedBox(width: 4),
                      Text('$startFmt – $endFmt',
                          style: const TextStyle(fontSize: 13)),
                      const Spacer(),
                      Text(
                        '\$${r.totalPrice?.toStringAsFixed(2) ?? '0.00'}',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      height: 160,
      width: double.infinity,
      color: Colors.grey.shade200,
      child: const Icon(Icons.home, size: 60, color: Colors.grey),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _currentPage > 1
                ? () => _fetchReservations(page: _currentPage - 1)
                : null,
          ),
          Text('Page $_currentPage of $totalPages',
              style: const TextStyle(fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages
                ? () => _fetchReservations(page: _currentPage + 1)
                : null,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }
}
