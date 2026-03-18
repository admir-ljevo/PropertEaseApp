import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:propertease_admin/providers/report_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

class RenterReservationReportScreen extends StatefulWidget {
  const RenterReservationReportScreen({super.key});

  @override
  State<RenterReservationReportScreen> createState() =>
      _RenterReservationReportScreenState();
}

class _RenterReservationReportScreenState
    extends State<RenterReservationReportScreen> {
  late UserProvider _userProvider;
  final ReportProvider _reportProvider = ReportProvider();

  List<ApplicationUser> _renters = [];
  ApplicationUser? _selectedRenter;

  DateTime? _from;
  DateTime? _to;
  bool _isLoading = false;

  bool get _isAdmin => Authorization.isAdmin;

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    if (_isAdmin) _fetchRenters();
  }

  Future<void> _fetchRenters() async {
    final list = await _userProvider.getRenters();
    setState(() => _renters = list);
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _from : _to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _from = picked;
        } else {
          _to = picked;
        }
      });
    }
  }

  Future<void> _download(String reportType, {int? ownerId}) async {
    setState(() => _isLoading = true);
    try {

      final Uint8List bytes = await _reportProvider.downloadReport(
        reportType,
        ownerId: ownerId,
        from: _from,
        to: _to,
      );

      final dir = await getApplicationDocumentsDirectory();
      final fileName =
          '${reportType}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.pdf';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Preuzeto: ${file.path}'),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'Otvori',
              onPressed: () => _openFile(file.path),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _openFile(String path) {
    if (Platform.isWindows) {
      Process.run('cmd', ['/c', 'start', '', path]);
    } else if (Platform.isMacOS) {
      Process.run('open', [path]);
    } else if (Platform.isLinux) {
      Process.run('xdg-open', [path]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Izvještaji')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Filters ────────────────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filteri',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const Divider(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _DatePickerField(
                            label: 'Datum od',
                            date: _from,
                            onTap: () => _pickDate(true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _DatePickerField(
                            label: 'Datum do',
                            date: _to,
                            onTap: () => _pickDate(false),
                          ),
                        ),
                        if (_isAdmin) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<ApplicationUser?>(
                              value: _selectedRenter,
                              decoration: const InputDecoration(
                                labelText: 'Izdavač (poslovanje)',
                                prefixIcon: Icon(Icons.person),
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<ApplicationUser?>(
                                  value: null,
                                  child: Text('Svi izdavači'),
                                ),
                                ..._renters.map((u) {
                                  return DropdownMenuItem<ApplicationUser?>(
                                    value: u,
                                    child: Text(
                                        '${u.person?.firstName ?? ''} ${u.person?.lastName ?? ''}'
                                            .trim()),
                                  );
                                }),
                              ],
                              onChanged: (v) =>
                                  setState(() => _selectedRenter = v),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Report buttons ─────────────────────────────────────────────
            const Text('Generiši izvještaj',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 12),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_isAdmin)
              Column(
                children: [
                  _ReportCard(
                    icon: Icons.bar_chart,
                    title: 'Poslovanje izdavača',
                    description:
                        'Pregled prihoda po nekretninama — broj rezervacija i ukupni prihod za odabrani period. Filtrirajte po izdavaču ili ostavite prazno za sve.',
                    onTap: () => _download('revenue',
                        ownerId: _selectedRenter?.id),
                  ),
                  const SizedBox(height: 12),
                  _ReportCard(
                    icon: Icons.payments,
                    title: 'Uplate korisnika',
                    description:
                        'Detaljan pregled svih uplata korisnika — rezervacioni broj, nekretnina, klijent i iznos uplate.',
                    onTap: () => _download('payments'),
                  ),
                ],
              )
            else
              _ReportCard(
                icon: Icons.bar_chart,
                title: 'Vlastito poslovanje',
                description:
                    'Pregled vaših prihoda po nekretninama — broj rezervacija i ukupni prihod za odabrani period.',
                onTap: () =>
                    _download('revenue', ownerId: Authorization.userId),
              ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DatePickerField(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_today),
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          date != null ? DateFormat('dd.MM.yyyy').format(date!) : 'Odaberi',
          style: TextStyle(
            fontSize: 14,
            color: date != null ? Colors.black87 : Colors.black38,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _ReportCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.blue, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text(description,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.download, color: Colors.blue.shade400),
            ],
          ),
        ),
      ),
    );
  }
}
