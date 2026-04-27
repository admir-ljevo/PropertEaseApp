import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/models/property.dart';
import 'package:propertease_client/providers/property_provider.dart';

class PropertyCompareScreen extends StatefulWidget {
  final Property propertyA;
  const PropertyCompareScreen({super.key, required this.propertyA});

  @override
  State<PropertyCompareScreen> createState() => _PropertyCompareScreenState();
}

class _PropertyCompareScreenState extends State<PropertyCompareScreen> {
  late PropertyProvider _propertyProvider;
  Property? _propertyB;

  @override
  void initState() {
    super.initState();
    _propertyProvider = context.read<PropertyProvider>();
  }

  Future<void> _showPropertyPicker() async {
    final selected = await showModalBottomSheet<Property>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PropertyPickerSheet(
        provider: _propertyProvider,
        excludeId: widget.propertyA.id,
      ),
    );
    if (selected != null) {
      try {
        final full = await _propertyProvider.getById(selected.id!);
        if (mounted) setState(() => _propertyB = full);
      } catch (_) {
        if (mounted) setState(() => _propertyB = selected);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.propertyA;
    final b = _propertyB;

    return Scaffold(
      appBar: AppBar(title: const Text('Uporedi nekretnine')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Property header cards ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _PropertyHeaderCard(
                    property: a,
                    label: 'A',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: b != null
                      ? _PropertyHeaderCard(
                          property: b,
                          label: 'B',
                          onTap: _showPropertyPicker,
                        )
                      : _PickerPlaceholder(onTap: _showPropertyPicker),
                ),
              ],
            ),

            if (b == null) ...[
              const SizedBox(height: 32),
              Center(
                child: Text(
                  'Tapni desnu karticu da odabereš nekretninu za poređenje',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              ),
            ],

            if (b != null) ...[
              const SizedBox(height: 24),

              // ── Column header labels ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    const Expanded(flex: 3, child: SizedBox.shrink()),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('A',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.indigo,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text('B',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Prices ─────────────────────────────────────────────────
              _sectionTitle('Cijene'),
              _CompareTable(children: [
                if ((a.isMonthly == true) || (b.isMonthly == true))
                  _NumRow(
                    label: 'Cijena/mjesec',
                    valA: a.monthlyPrice,
                    valB: b.monthlyPrice,
                    lowerIsBetter: true,
                    format: (v) =>
                        v > 0 ? '${v.toStringAsFixed(0)} BAM' : '—',
                    icon: Icons.calendar_month,
                  ),
                if ((a.isDaily == true) || (b.isDaily == true))
                  _NumRow(
                    label: 'Cijena/dan',
                    valA: a.dailyPrice,
                    valB: b.dailyPrice,
                    lowerIsBetter: true,
                    format: (v) =>
                        v > 0 ? '${v.toStringAsFixed(0)} BAM' : '—',
                    icon: Icons.today,
                  ),
              ]),

              const SizedBox(height: 12),

              // ── Key stats ──────────────────────────────────────────────
              _sectionTitle('Karakteristike'),
              _CompareTable(children: [
                _NumRow(
                  label: 'Ocjena',
                  valA: a.averageRating,
                  valB: b.averageRating,
                  lowerIsBetter: false,
                  format: (v) => v > 0 ? v.toStringAsFixed(1) : '—',
                  icon: Icons.star,
                ),
                _NumRow(
                  label: 'Broj soba',
                  valA: (a.numberOfRooms ?? 0).toDouble(),
                  valB: (b.numberOfRooms ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => '${v.toInt()}',
                  icon: Icons.bed,
                ),
                _NumRow(
                  label: 'Kupatila',
                  valA: (a.numberOfBathrooms ?? 0).toDouble(),
                  valB: (b.numberOfBathrooms ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => '${v.toInt()}',
                  icon: Icons.bathtub,
                ),
                _NumRow(
                  label: 'Površina',
                  valA: (a.squareMeters ?? 0).toDouble(),
                  valB: (b.squareMeters ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => '${v.toInt()} m²',
                  icon: Icons.aspect_ratio,
                ),
                _NumRow(
                  label: 'Kapacitet',
                  valA: (a.capacity ?? 0).toDouble(),
                  valB: (b.capacity ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => '${v.toInt()} osoba',
                  icon: Icons.people,
                ),
                _NumRow(
                  label: 'Vrt',
                  valA: (a.gardenSize ?? 0).toDouble(),
                  valB: (b.gardenSize ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => v > 0 ? '${v.toInt()} m²' : '—',
                  icon: Icons.park,
                ),
                _NumRow(
                  label: 'Garaža (vel.)',
                  valA: (a.garageSize ?? 0).toDouble(),
                  valB: (b.garageSize ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => v > 0 ? '${v.toInt()} m²' : '—',
                  icon: Icons.garage,
                ),
                _NumRow(
                  label: 'Parking (vel.)',
                  valA: (a.parkingSize ?? 0).toDouble(),
                  valB: (b.parkingSize ?? 0).toDouble(),
                  lowerIsBetter: false,
                  format: (v) => v > 0 ? '${v.toInt()} m²' : '—',
                  icon: Icons.local_parking,
                ),
              ]),

              const SizedBox(height: 12),

              // ── Info ───────────────────────────────────────────────────
              _sectionTitle('Informacije'),
              _CompareTable(children: [
                _TextRow(
                    label: 'Tip',
                    valA: a.propertyType?.name ?? '—',
                    valB: b.propertyType?.name ?? '—',
                    icon: Icons.home),
                _TextRow(
                    label: 'Grad',
                    valA: a.city?.name ?? '—',
                    valB: b.city?.name ?? '—',
                    icon: Icons.location_city),
              ]),

              const SizedBox(height: 12),

              // ── Amenities ─────────────────────────────────────────────
              _sectionTitle('Sadržaji'),
              _CompareTable(children: [
                _BoolRow(
                    label: 'WiFi',
                    valA: a.hasWiFi,
                    valB: b.hasWiFi,
                    icon: Icons.wifi),
                _BoolRow(
                    label: 'Namješteno',
                    valA: a.isFurnished,
                    valB: b.isFurnished,
                    icon: Icons.chair),
                _BoolRow(
                    label: 'Balkon',
                    valA: a.hasBalcony,
                    valB: b.hasBalcony,
                    icon: Icons.balcony),
                _BoolRow(
                    label: 'Bazen',
                    valA: a.hasPool,
                    valB: b.hasPool,
                    icon: Icons.pool),
                _BoolRow(
                    label: 'Klima',
                    valA: a.hasAirCondition,
                    valB: b.hasAirCondition,
                    icon: Icons.ac_unit),
                _BoolRow(
                    label: 'Alarm',
                    valA: a.hasAlarm,
                    valB: b.hasAlarm,
                    icon: Icons.security),
                _BoolRow(
                    label: 'Kabelska TV',
                    valA: a.hasCableTV,
                    valB: b.hasCableTV,
                    icon: Icons.cable),
                _BoolRow(
                    label: 'TV',
                    valA: a.hasTV,
                    valB: b.hasTV,
                    icon: Icons.tv),
                _BoolRow(
                    label: 'Video nadzor',
                    valA: a.hasSurveilance,
                    valB: b.hasSurveilance,
                    icon: Icons.videocam),
                _BoolRow(
                    label: 'Parking',
                    valA: a.hasParking,
                    valB: b.hasParking,
                    icon: Icons.local_parking),
                _BoolRow(
                    label: 'Garaža',
                    valA: a.hasGarage,
                    valB: b.hasGarage,
                    icon: Icons.garage),
                _BoolRow(
                    label: 'Centralno grijanje',
                    valA: a.hasOwnHeatingSystem,
                    valB: b.hasOwnHeatingSystem,
                    icon: Icons.local_fire_department),
              ]),

              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
      );
}

// ── Property header card ─────────────────────────────────────────────────────

class _PropertyHeaderCard extends StatelessWidget {
  final Property property;
  final String label;
  final VoidCallback? onTap;

  const _PropertyHeaderCard({
    required this.property,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoUrl = (property.firstPhotoUrl?.isNotEmpty == true)
        ? '${AppConfig.serverBase}${property.firstPhotoUrl}'
        : null;
    final isB = label == 'B';

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isB ? Colors.indigo.shade200 : Colors.blue.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12)),
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          height: 90,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _placeholder(isB),
                        )
                      : _placeholder(isB),
                ),
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isB ? Colors.indigo : Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                ),
                if (onTap != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white70,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit, size: 14),
                    ),
                  ),
              ],
            ),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.name ?? '',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    property.city?.name ?? '',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(bool isB) => Container(
        height: 90,
        color: isB ? Colors.indigo.shade50 : Colors.blue.shade50,
        child: Center(
          child: Icon(Icons.home,
              color: isB ? Colors.indigo : Colors.blue, size: 36),
        ),
      );
}

// ── Picker placeholder ───────────────────────────────────────────────────────

class _PickerPlaceholder extends StatelessWidget {
  final VoidCallback onTap;
  const _PickerPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: Colors.indigo.shade200,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: SizedBox(
          height: 155,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline,
                  color: Colors.indigo.shade300, size: 40),
              const SizedBox(height: 8),
              Text(
                'Tapni za\nodabir nekretnine',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.indigo.shade400,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Property picker bottom sheet ─────────────────────────────────────────────

class _PropertyPickerSheet extends StatefulWidget {
  final PropertyProvider provider;
  final int? excludeId;

  const _PropertyPickerSheet({
    required this.provider,
    required this.excludeId,
  });

  @override
  State<_PropertyPickerSheet> createState() => _PropertyPickerSheetState();
}

class _PropertyPickerSheetState extends State<_PropertyPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<Property> _results = [];
  bool _loading = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch(String name) async {
    if (mounted) setState(() => _loading = true);
    try {
      final res = await widget.provider
          .getFiltered(filter: {'name': name, 'page': 1, 'pageSize': 20});
      if (mounted) {
        setState(() => _results =
            res.result.where((p) => p.id != widget.excludeId).toList());
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 400), () => _fetch(v));
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Odaberi nekretninu',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextField(
              controller: _searchCtrl,
              onChanged: _onSearch,
              decoration: const InputDecoration(
                hintText: 'Pretraži po nazivu...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? const Center(child: Text('Nema rezultata'))
                      : ListView.separated(
                          controller: scrollCtrl,
                          itemCount: _results.length,
                          separatorBuilder: (_, __) =>
                              Divider(height: 1, color: Colors.grey.shade100),
                          itemBuilder: (_, i) => _tile(_results[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Property p) {
    final photoUrl = (p.firstPhotoUrl?.isNotEmpty == true)
        ? '${AppConfig.serverBase}${p.firstPhotoUrl}'
        : null;

    return ListTile(
      onTap: () => Navigator.of(context).pop(p),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: photoUrl != null
            ? Image.network(photoUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _imgPlaceholder())
            : _imgPlaceholder(),
      ),
      title: Text(p.name ?? '',
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: Text(
          '${p.city?.name ?? ''} • ${p.propertyType?.name ?? ''}',
          style: const TextStyle(fontSize: 12)),
      trailing: Text(
        p.isMonthly == true
            ? '${p.monthlyPrice?.toStringAsFixed(0)} BAM/mj.'
            : p.isDaily == true
                ? '${p.dailyPrice?.toStringAsFixed(0)} BAM/dan'
                : '',
        style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF115892),
            fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
        width: 56,
        height: 56,
        color: Colors.blue.shade50,
        child: const Icon(Icons.home, color: Colors.blue),
      );
}

// ── Comparison table ─────────────────────────────────────────────────────────

class _CompareTable extends StatelessWidget {
  final List<Widget> children;
  const _CompareTable({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(children: children),
    );
  }
}

// ── Row types ────────────────────────────────────────────────────────────────

class _NumRow extends StatelessWidget {
  final String label;
  final double? valA;
  final double? valB;
  final bool lowerIsBetter;
  final String Function(double) format;
  final IconData? icon;

  const _NumRow({
    required this.label,
    required this.valA,
    required this.valB,
    required this.lowerIsBetter,
    required this.format,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final a = valA ?? 0;
    final b = valB ?? 0;
    final aWins =
        lowerIsBetter ? (a > 0 && (a < b || b == 0)) : (a > b && a > 0);
    final bWins =
        lowerIsBetter ? (b > 0 && (b < a || a == 0)) : (b > a && b > 0);

    return _BaseRow(
      label: label,
      icon: icon,
      cellA: _numCell(format(a), aWins, false),
      cellB: _numCell(format(b), bWins, true),
    );
  }

  Widget _numCell(String text, bool highlight, bool isB) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: highlight
              ? Colors.green.shade50
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (highlight)
              const Icon(Icons.check, size: 12, color: Colors.green),
            if (highlight) const SizedBox(width: 2),
            Flexible(
              child: Text(
                text,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: highlight ? Colors.green.shade700 : null,
                ),
              ),
            ),
          ],
        ),
      );
}

class _TextRow extends StatelessWidget {
  final String label;
  final String valA;
  final String valB;
  final IconData? icon;

  const _TextRow({
    required this.label,
    required this.valA,
    required this.valB,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseRow(
      label: label,
      icon: icon,
      cellA: Text(valA,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
      cellB: Text(valB,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12)),
    );
  }
}

class _BoolRow extends StatelessWidget {
  final String label;
  final bool? valA;
  final bool? valB;
  final IconData? icon;

  const _BoolRow({
    required this.label,
    required this.valA,
    required this.valB,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return _BaseRow(
      label: label,
      icon: icon,
      cellA: _boolIcon(valA ?? false),
      cellB: _boolIcon(valB ?? false),
    );
  }

  Widget _boolIcon(bool v) => Icon(
        v ? Icons.check_circle : Icons.cancel_outlined,
        color: v ? Colors.green : Colors.grey.shade300,
        size: 20,
      );
}

class _BaseRow extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Widget cellA;
  final Widget cellB;

  const _BaseRow({
    required this.label,
    this.icon,
    required this.cellA,
    required this.cellB,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 6),
          ],
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
          Expanded(flex: 2, child: Center(child: cellA)),
          Expanded(flex: 2, child: Center(child: cellB)),
        ],
      ),
    );
  }
}
