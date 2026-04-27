import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/payment.dart';
import 'package:propertease_admin/providers/payment_provider.dart';
import 'package:propertease_admin/utils/debounce.dart';
import 'package:propertease_admin/widgets/master_screen.dart';
import 'package:provider/provider.dart';

class PaymentListScreen extends StatefulWidget {
  const PaymentListScreen({super.key});

  @override
  State<PaymentListScreen> createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  late PaymentProvider _provider;
  List<Payment> _items = [];
  bool _loading = true;
  int _currentPage = 1;
  int _totalCount = 0;
  static const int _pageSize = 10;

  final TextEditingController _searchCtrl = TextEditingController();
  final _debounce = Debounce();
  int? _selectedStatus;
  DateTime? _dateFrom;
  DateTime? _dateTo;

  static const _statuses = [
    {'label': 'All statuses', 'value': null},
    {'label': 'Pending', 'value': 0},
    {'label': 'Completed', 'value': 1},
    {'label': 'Refunded', 'value': 2},
    {'label': 'Failed', 'value': 3},
  ];

  @override
  void initState() {
    super.initState();
    _provider = context.read<PaymentProvider>();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final result = await _provider.getFiltered(filter: {
        'search': _searchCtrl.text.trim(),
        if (_selectedStatus != null) 'status': _selectedStatus,
        if (_dateFrom != null) 'dateFrom': DateFormat('yyyy-MM-dd').format(_dateFrom!),
        if (_dateTo != null) 'dateTo': DateFormat('yyyy-MM-dd').format(_dateTo!),
        'page': _currentPage,
        'pageSize': _pageSize,
      });
      if (mounted) setState(() { _items = result.result; _totalCount = result.totalCount; });
    } catch (e) {
      _showError('Failed to load payments: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _resetFilters() {
    setState(() {
      _searchCtrl.clear();
      _selectedStatus = null;
      _dateFrom = null;
      _dateTo = null;
      _currentPage = 1;
    });
    _load();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) _dateFrom = picked; else _dateTo = picked;
        _currentPage = 1;
      });
      _load();
    }
  }

  int get _totalPages => (_totalCount / _pageSize).ceil().clamp(1, 999);

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Color _statusColor(int? status) {
    switch (status) {
      case 1: return Colors.green;
      case 2: return Colors.orange;
      case 3: return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MasterScreenWidget(
      title: 'Payments',
      child: Column(
        children: [
          Container(
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
                    Text('Payments',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                    SizedBox(height: 2),
                    Text('All payment transactions',
                        style: TextStyle(fontSize: 13, color: Colors.white70)),
                  ],
                ),
                Spacer(),
                Icon(Icons.payment, size: 36, color: Colors.white54),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Search client or PayPal ID...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: (_) {
                      setState(() { _currentPage = 1; });
                      _debounce.run(_load);
                    },
                  ),
                ),
                SizedBox(
                  width: 160,
                  child: DropdownButtonFormField<int?>(
                    initialValue: _selectedStatus,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Status', isDense: true),
                    items: _statuses
                        .map((s) => DropdownMenuItem<int?>(
                              value: s['value'] as int?,
                              child: Text(s['label'] as String),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() { _selectedStatus = v; _currentPage = 1; });
                      _load();
                    },
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateFrom != null
                      ? 'From: ${DateFormat('dd.MM.yyyy').format(_dateFrom!)}'
                      : 'Date from'),
                  onPressed: () => _pickDate(isFrom: true),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.calendar_today, size: 16),
                  label: Text(_dateTo != null
                      ? 'To: ${DateFormat('dd.MM.yyyy').format(_dateTo!)}'
                      : 'Date to'),
                  onPressed: () => _pickDate(isFrom: false),
                ),
                TextButton.icon(
                  onPressed: _resetFilters,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_items.isEmpty) return const Center(child: Text('No payments found.'));

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
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Client')),
                        DataColumn(label: Text('Reservation')),
                        DataColumn(label: Text('PayPal ID')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Status')),
                      ],
                      rows: _items.map((p) {
                        final dateStr = p.createdAt != null
                            ? DateFormat('dd.MM.yyyy HH:mm').format(p.createdAt!)
                            : '/';
                        final client = [p.clientName, p.clientUsername]
                            .where((s) => s != null && s.trim().isNotEmpty)
                            .join(' · ');
                        return DataRow(cells: [
                          DataCell(Text(dateStr, style: const TextStyle(fontSize: 13))),
                          DataCell(Text(client.isNotEmpty ? client : '/', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(p.reservationNumber ?? '/', style: const TextStyle(fontSize: 13))),
                          DataCell(Text(p.payPalPaymentId ?? '/', style: const TextStyle(fontSize: 12, fontFamily: 'monospace'))),
                          DataCell(Text(
                            '${p.amount?.toStringAsFixed(2) ?? '0.00'} ${p.currency ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )),
                          DataCell(Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(p.status).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              p.statusName ?? '',
                              style: TextStyle(
                                color: _statusColor(p.status),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
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
                    ? () { setState(() => _currentPage--); _load(); }
                    : null,
              ),
              Text('$_currentPage / $_totalPages'),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages
                    ? () { setState(() => _currentPage++); _load(); }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
