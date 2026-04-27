import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/property_reservation.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_reservation_provider.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:propertease_admin/screens/reservation/reservation_detail_screen.dart';
import 'package:propertease_admin/utils/debounce.dart';
import 'package:propertease_admin/utils/reservation_status.dart';
import 'package:provider/provider.dart';

import '../../models/property_type.dart';
import '../../widgets/master_screen.dart';
import 'reservation_edit_screen.dart';

class ReservationListWidget extends StatefulWidget {
  const ReservationListWidget({super.key});

  @override
  State<ReservationListWidget> createState() => ReservationListWidgetState();
}

class ReservationListWidgetState extends State<ReservationListWidget> {
  late final PropertyReservationProvider _reservationProvider;
  late final PropertyTypeProvider _propertyTypeProvider;

  SearchResult<PropertyReservation>? _result;
  List<PropertyType> _propertyTypes = [];

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  final _debounce = Debounce();

  String? _formattedEndDate;
  String? _formattedStartDate;
  int? _propertyTypeId;
  DateTime? _selectedDateStart;
  DateTime? _selectedDateEnd;
  int? _statusFilter;
  PropertyType? _selectedPropertyType;

  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    _reservationProvider = context.read<PropertyReservationProvider>();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _loadReferenceDataThenReservations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _loadReferenceDataThenReservations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final typesResult = await _propertyTypeProvider.get();
      _propertyTypes = typesResult.result;
      await _fetchReservations();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchReservations() async {
    setState(() => _isLoading = true);
    try {
      double? minPrice = _minPriceController.text.isNotEmpty
          ? double.tryParse(_minPriceController.text)
          : null;
      double? maxPrice = _maxPriceController.text.isNotEmpty
          ? double.tryParse(_maxPriceController.text)
          : null;

      final reservations =
          await _reservationProvider.getFiltered(filter: {
        'propertyName': _nameController.text,
        'propertyTypeId': _propertyTypeId,
        'dateOccupancyStarted': _formattedStartDate,
        'dateOccupancyEnded': _formattedEndDate,
        'totalPriceFrom': minPrice,
        'totalPriceTo': maxPrice,
        if (_statusFilter != null) 'status': _statusFilter,
        'page': _currentPage,
        'pageSize': _pageSize,
        if (Authorization.roleId == 2) 'renterId': Authorization.userId,
      });

      if (mounted) {
        setState(() {
          _result = reservations;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDateStart(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _selectedDateStart = picked;
      _formattedStartDate = DateFormat('yyyy-MM-dd').format(picked);
      _fetchReservations();
    }
  }

  Future<void> _selectDateEnd(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _selectedDateEnd = picked;
      _formattedEndDate = DateFormat('yyyy-MM-dd').format(picked);
      _fetchReservations();
    }
  }

  Future<void> _handleDeleteReservation(int? reservationId) async {
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _reservationProvider.deleteById(reservationId);
      await _fetchReservations();
      nav.pop();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Reservation deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      titleWidget: const Text('Reservation List'),
      child: Column(
        children: [
          _buildHeader(),
          _buildSearch(context),
          const Divider(height: 1),
          Expanded(child: _buildDataListView()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
      child: const Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rezervacije',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              SizedBox(height: 2),
              Text('Lista i upravljanje rezervacijama',
                  style: TextStyle(fontSize: 13, color: Colors.white70)),
            ],
          ),
          Spacer(),
          Icon(Icons.calendar_month, size: 36, color: Colors.white54),
        ],
      ),
    );
  }

  Widget _buildSearch(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(
                labelText: 'Property name',
                prefixIcon: Icon(Icons.search),
              ),
              controller: _nameController,
              onChanged: (_) => _debounce.run(_fetchReservations),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<PropertyType?>(
              value: _selectedPropertyType,
              onChanged: (PropertyType? newValue) async {
                setState(() {
                  _selectedPropertyType = newValue;
                  _propertyTypeId = newValue?.id;
                });
                await _fetchReservations();
              },
              items: _propertyTypes
                  .map<DropdownMenuItem<PropertyType?>>(
                    (pt) => DropdownMenuItem<PropertyType?>(
                      value: pt,
                      child: Text(pt.name ?? 'Undefined'),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(labelText: 'Property type'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              onPressed: () => _selectDateStart(context),
              child: Text(
                _selectedDateStart != null
                    ? DateFormat('dd.MM.yyyy').format(_selectedDateStart!)
                    : 'Reservation start',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextButton(
              onPressed: () => _selectDateEnd(context),
              child: Text(
                _selectedDateEnd != null
                    ? DateFormat('dd.MM.yyyy').format(_selectedDateEnd!)
                    : 'Reservation end',
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              decoration:
                  const InputDecoration(labelText: 'Price range from'),
              keyboardType: TextInputType.number,
              controller: _minPriceController,
              onChanged: (_) => _debounce.run(_fetchReservations),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              decoration: const InputDecoration(labelText: 'Price range to'),
              keyboardType: TextInputType.number,
              controller: _maxPriceController,
              onChanged: (_) => _debounce.run(_fetchReservations),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: _statusFilter,
              onChanged: (int? newValue) {
                setState(() => _statusFilter = newValue);
                _fetchReservations();
              },
              items: const [
                DropdownMenuItem<int?>(value: null, child: Text('All statuses')),
                DropdownMenuItem<int?>(value: 0, child: Text('Na čekanju')),
                DropdownMenuItem<int?>(value: 1, child: Text('Potvrđena')),
                DropdownMenuItem<int?>(value: 2, child: Text('Završena')),
                DropdownMenuItem<int?>(value: 3, child: Text('Otkazana')),
              ],
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ),
          const SizedBox(width: 15),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _selectedPropertyType = null;
                _statusFilter = null;
                _propertyTypeId = null;
                _selectedDateStart = null;
                _selectedDateEnd = null;
                _formattedStartDate = null;
                _formattedEndDate = null;
                _currentPage = 1;
              });
              _maxPriceController.clear();
              _minPriceController.clear();
              _nameController.clear();
              _fetchReservations();
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataListView() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Error: $_error',
                style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _fetchReservations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final rows = _result?.result ?? [];
    if (rows.isEmpty) {
      return const Center(child: Text('No reservations found.'));
    }

    final totalPages = ((_result?.totalCount ?? 0) / _pageSize).ceil();
    return Column(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFE8EAF6)),
          columns: const [
            DataColumn(
              label: Expanded(
                child: Text('Property name',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Property type',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('City',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Reservation start',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Reservation end',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Total price',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Status',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
            DataColumn(
              label: Expanded(
                child: Text('Actions',
                    style: TextStyle(fontStyle: FontStyle.italic)),
              ),
            ),
          ],
          rows: rows.map((PropertyReservation e) {
            return DataRow(cells: [
              DataCell(Text(e.property?.name ?? '/')),
              DataCell(Text(e.property?.propertyType?.name ?? '/')),
              DataCell(Text(e.property?.city?.name ?? '/')),
              DataCell(Text(DateFormat('dd-MM-yyyy')
                  .format(e.dateOfOccupancyStart ?? DateTime.now()))),
              DataCell(Text(DateFormat('dd-MM-yyyy')
                  .format(e.dateOfOccupancyEnd ?? DateTime.now()))),
              DataCell(Text(e.totalPrice?.toString() ?? '0')),
              DataCell(ReservationStatus.chip(e.status)),
              DataCell(Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Tooltip(
                    message: 'Detalji',
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ReservationDetailsScreen(reservation: e),
                          ),
                        );
                        await _fetchReservations();
                      },
                      child: const Icon(Icons.info_outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Tooltip(
                    message: 'Uredi',
                    child: InkWell(
                      onTap: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ReservationEditScreen(reservation: e),
                          ),
                        );
                        await _fetchReservations();
                      },
                      child: const Icon(Icons.edit, color: Colors.blue),
                    ),
                  ),
                  if (e.status == ReservationStatus.completed || e.status == ReservationStatus.cancelled) ...[
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Obriši',
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext ctx) {
                              return AlertDialog(
                                title: const Text('Potvrdi brisanje'),
                                content: const Text(
                                    'Da li ste sigurni da želite obrisati ovu rezervaciju?'),
                                actions: [
                                  TextButton(
                                    child: const Text('Odustani'),
                                    onPressed: () => Navigator.of(ctx).pop(),
                                  ),
                                  TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.red),
                                    child: const Text('Obriši'),
                                    onPressed: () =>
                                        _handleDeleteReservation(e.id),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                    ),
                  ],
                ],
              )),
            ]);
          }).toList(),
                    ),    // DataTable
                  ),      // horizontal scroll
                ),        // vertical scroll
              ),          // ClipRRect
            ),            // Card
          ),              // Padding
        ),                // Expanded
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 1
                    ? () {
                        setState(() => _currentPage--);
                        _fetchReservations();
                      }
                    : null,
              ),
              Text('$_currentPage / ${totalPages > 0 ? totalPages : 1}'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages
                    ? () {
                        setState(() => _currentPage++);
                        _fetchReservations();
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
