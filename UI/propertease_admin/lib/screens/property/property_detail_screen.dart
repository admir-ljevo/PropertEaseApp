import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/providers/property_provider.dart';
import '../../models/photo.dart';
import '../../models/property.dart';
import 'property_edit_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property? property;
  const PropertyDetailScreen({super.key, this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  List<Photo> _images = [];
  List<Property> _recommended = [];
  int _currentPage = 0;
  bool _initialized = false;
  bool _loading = true;
  Property? _property;

  @override
  void initState() {
    super.initState();
    _property = widget.property;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      // Full property (with photos) and recommendations fire in parallel.
      _loadFullProperty();
      _loadRecommendations();
    }
  }

  Future<void> _loadFullProperty() async {
    if (widget.property?.id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final full = await context.read<PropertyProvider>().getById(widget.property!.id!);
      final validImages = (full.photos ?? [])
          .where((p) => p.url != null && p.url!.isNotEmpty && p.url != 'a')
          .toList();
      if (mounted) {
        setState(() {
          _property = full;
          _images = validImages;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadRecommendations() async {
    if (widget.property?.id == null) return;
    try {
      final result = await context.read<PropertyProvider>().getRecommendations(widget.property!.id!);
      if (mounted) setState(() => _recommended = result);
    } catch (_) {}
  }

  // Called after the edit screen returns so the carousel stays fresh.
  Future<void> _refreshImages() async {
    if (widget.property?.id == null) return;
    try {
      final fetched = await context.read<PhotoProvider>().getImagesByProperty(widget.property!.id);
      final valid = fetched
          .where((p) => p.url != null && p.url!.isNotEmpty && p.url != 'a')
          .toList();
      if (mounted) setState(() => _images = valid);
    } catch (_) {}
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.property?.name ?? 'Detalji nekretnine')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final property = _property ?? widget.property;
    if (property == null) {
      return const Scaffold(
          body: Center(child: Text('Nekretnina nije pronađena')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(property.name ?? 'Detalji nekretnine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Uredi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PropertyEditScreen(property: property),
              ),
            ).then((_) => _refreshImages()),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildCarousel()),
                const SizedBox(width: 16),
                Expanded(
                  child: (property.latitude ?? 0) != 0 && (property.longitude ?? 0) != 0
                      ? _buildMapSection(property)
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildHeader(property),
            const SizedBox(height: 16),
            _buildPricingSection(property),
            const SizedBox(height: 16),
            _buildStatsSection(property),
            const SizedBox(height: 16),
            _buildAmenitiesSection(property),
            const SizedBox(height: 16),
            _buildDescriptionSection(property),
            if (_recommended.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildRecommendationsSection(),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _openFullscreen(int startIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FullscreenViewer(images: _images, initialIndex: startIndex),
    );
  }

  // ── Image carousel ─────────────────────────────────────────────────────────

  Widget _buildCarousel() {
    if (_images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.asset(
            'assets/images/house_placeholder.jpg',
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _openFullscreen(_currentPage),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: SizedBox.expand(
                      key: ValueKey(_currentPage),
                      child: Image.network(
                        '${AppConfig.serverBase}${_images[_currentPage].url}',
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/images/house_placeholder.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_images.length > 1) ...[
              Positioned(
                left: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _arrowButton(
                    icon: Icons.chevron_left,
                    onPressed: _currentPage > 0
                        ? () => setState(() => _currentPage--)
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: 6,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _arrowButton(
                    icon: Icons.chevron_right,
                    onPressed: _currentPage < _images.length - 1
                        ? () => setState(() => _currentPage++)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 8,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _images.length,
                    (i) => GestureDetector(
                      onTap: () => setState(() => _currentPage = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _currentPage ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _currentPage
                              ? Colors.white
                              : Colors.white.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_currentPage + 1} / ${_images.length}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _arrowButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.black45,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 26),
        ),
      ),
    );
  }

  // ── Content sections ───────────────────────────────────────────────────────

  Widget _buildHeader(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.name ?? '',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.location_on, size: 15, color: Colors.blue),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                [property.city?.name, property.address]
                    .where((s) => s != null && s.isNotEmpty)
                    .join(', '),
                style:
                    const TextStyle(fontSize: 14, color: Colors.black54),
              ),
            ),
          ],
        ),
        if ((property.averageRating ?? 0) > 0) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Colors.amber),
              const SizedBox(width: 4),
              Text(
                property.averageRating!.toStringAsFixed(1),
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPricingSection(Property property) {
    final hasDaily =
        property.isDaily == true && (property.dailyPrice ?? 0) > 0;
    final hasMonthly =
        property.isMonthly == true && (property.monthlyPrice ?? 0) > 0;
    if (!hasDaily && !hasMonthly) return const SizedBox.shrink();

    return Row(
      children: [
        if (hasDaily)
          _PriceChip(
            label: '${property.dailyPrice!.round()} KM',
            sublabel: 'po danu',
            icon: Icons.today,
          ),
        if (hasDaily && hasMonthly) const SizedBox(width: 12),
        if (hasMonthly)
          _PriceChip(
            label: '${property.monthlyPrice!.round()} KM',
            sublabel: 'po mjesecu',
            icon: Icons.calendar_month,
          ),
      ],
    );
  }

  Widget _buildStatsSection(Property property) {
    final stats = <_StatData>[
      _StatData(Icons.bed, 'Sobe', '${property.numberOfRooms ?? 0}'),
      _StatData(Icons.bathtub, 'Kupatila',
          '${property.numberOfBathrooms ?? 0}'),
      _StatData(
          Icons.square_foot, 'Površina', '${property.squareMeters ?? 0} m²'),
      _StatData(Icons.people, 'Kapacitet', '${property.capacity ?? 0}'),
      if ((property.garageSize ?? 0) > 0)
        _StatData(Icons.garage, 'Garaža', '${property.garageSize}'),
      if ((property.gardenSize ?? 0) > 0)
        _StatData(Icons.grass, 'Dvorište', '${property.gardenSize} m²'),
      if ((property.parkingSize ?? 0) > 0)
        _StatData(
            Icons.local_parking, 'Parking', '${property.parkingSize}'),
    ];

    return _SectionCard(
      title: 'Karakteristike',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: stats.map((s) => _StatTile(data: s)).toList(),
      ),
    );
  }

  Widget _buildAmenitiesSection(Property property) {
    final amenities = <_AmenityData>[
      _AmenityData(Icons.wifi, 'Wi-Fi', property.hasWiFi),
      _AmenityData(Icons.ac_unit, 'Klima', property.hasAirCondition),
      _AmenityData(Icons.chair, 'Namješteno', property.isFurnished),
      _AmenityData(Icons.thermostat, 'Centralno grijanje',
          property.hasOwnHeatingSystem),
      _AmenityData(Icons.pool, 'Bazen', property.hasPool),
      _AmenityData(Icons.balcony, 'Balkon', property.hasBalcony),
      _AmenityData(Icons.alarm, 'Alarm', property.hasAlarm),
      _AmenityData(Icons.videocam, 'Video nadzor', property.hasSurveilance),
      _AmenityData(Icons.tv, 'TV', property.hasTV),
      _AmenityData(Icons.cable, 'Kablovska', property.hasCableTV),
      _AmenityData(Icons.local_parking, 'Parking', property.hasParking),
      _AmenityData(Icons.garage, 'Garaža', property.hasGarage),
    ];

    return _SectionCard(
      title: 'Sadržaj',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.map((a) => _AmenityChip(data: a)).toList(),
      ),
    );
  }

  Widget _buildRecommendationsSection() {
    return _SectionCard(
      title: 'Slične nekretnine',
      child: SizedBox(
        height: 130,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _recommended.length,
          itemBuilder: (context, index) {
            final rec = _recommended[index];
            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PropertyDetailScreen(property: rec),
                ),
              ),
              child: Container(
                width: 200,
                margin: const EdgeInsets.only(right: 10),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.blue.shade50,
                ),
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.house, size: 18, color: Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            rec.name ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.blue.shade900,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (rec.city?.name != null)
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: Colors.blue.shade400),
                          const SizedBox(width: 4),
                          Text(
                            rec.city!.name ?? '',
                            style: TextStyle(fontSize: 11, color: Colors.blue.shade600),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      rec.isMonthly == true
                          ? '${rec.monthlyPrice?.round() ?? 0} KM/mj.'
                          : '${rec.dailyPrice?.round() ?? 0} KM/dan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMapSection(Property property) {
    final point = LatLng(property.latitude!, property.longitude!);
    return _SectionCard(
      title: 'Lokacija',
      child: SizedBox(
        height: 250,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: FlutterMap(
            options: MapOptions(
              center: point,
              zoom: 14.0,
              interactiveFlags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.propertease.admin',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    builder: (ctx) => const Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
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

  Widget _buildDescriptionSection(Property property) {
    if (property.description == null || property.description!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _SectionCard(
      title: 'Opis',
      child: Text(
        property.description!,
        style: const TextStyle(fontSize: 15, height: 1.5),
      ),
    );
  }
}

// ─── Fullscreen image viewer ──────────────────────────────────────────────────

class _FullscreenViewer extends StatefulWidget {
  final List<Photo> images;
  final int initialIndex;
  const _FullscreenViewer({required this.images, required this.initialIndex});

  @override
  State<_FullscreenViewer> createState() => _FullscreenViewerState();
}

class _FullscreenViewerState extends State<_FullscreenViewer> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            // Tap background to close
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.transparent, width: size.width, height: size.height),
            ),
            // Image (centered, contain)
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  '${AppConfig.serverBase}${widget.images[_idx].url}',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  },
                  errorBuilder: (_, __, ___) => Image.asset(
                    'assets/images/house_placeholder.jpg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            // Navigation arrows
            if (widget.images.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navBtn(
                    icon: Icons.chevron_left,
                    onPressed: _idx > 0 ? () => setState(() => _idx--) : null,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navBtn(
                    icon: Icons.chevron_right,
                    onPressed: _idx < widget.images.length - 1
                        ? () => setState(() => _idx++)
                        : null,
                  ),
                ),
              ),
              // Counter
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_idx + 1} / ${widget.images.length}',
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navBtn({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: onPressed != null ? Colors.black54 : Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}

// ─── Reusable helper widgets ──────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
        const Divider(height: 12, thickness: 1),
        child,
      ],
    );
  }
}

class _StatData {
  final IconData icon;
  final String label;
  final String value;
  _StatData(this.icon, this.label, this.value);
}

class _StatTile extends StatelessWidget {
  final _StatData data;
  const _StatTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(data.icon, size: 15, color: Colors.blue.shade700),
          const SizedBox(width: 6),
          Text('${data.label}: ',
              style: TextStyle(
                  fontSize: 13, color: Colors.blue.shade700)),
          Text(data.value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _AmenityData {
  final IconData icon;
  final String label;
  final bool? available;
  _AmenityData(this.icon, this.label, this.available);
}

class _AmenityChip extends StatelessWidget {
  final _AmenityData data;
  const _AmenityChip({required this.data});

  @override
  Widget build(BuildContext context) {
    final on = data.available == true;
    return Chip(
      avatar: Icon(data.icon,
          size: 15,
          color: on ? Colors.green.shade700 : Colors.grey.shade500),
      label: Text(data.label,
          style: TextStyle(
              fontSize: 12,
              color: on
                  ? Colors.green.shade800
                  : Colors.grey.shade600)),
      backgroundColor:
          on ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(
          color: on ? Colors.green.shade300 : Colors.grey.shade300),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String label;
  final String sublabel;
  final IconData icon;
  const _PriceChip(
      {required this.label,
      required this.sublabel,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blue, Color(0xFF1A237E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white70),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              Text(sublabel,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}
