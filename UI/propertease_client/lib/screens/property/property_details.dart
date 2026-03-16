import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/providers/conversation_provider.dart';
import 'package:propertease_client/providers/property_provider.dart';
import 'package:propertease_client/screens/conversations/messaging_screen.dart';
import 'package:propertease_client/screens/property/reviews/review_list.dart';
import 'package:propertease_client/screens/reservations/reservation_add_screen.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:provider/provider.dart';

import '../../models/conversation.dart';
import '../../models/photo.dart';
import '../../models/property.dart';
import '../users/renter_profile_screen.dart';
import 'property_compare_screen.dart';

const _kPrimary = Color(0xFF115892);

// ignore: must_be_immutable
class PropertyDetailsScreen extends StatefulWidget {
  Property? property;

  PropertyDetailsScreen({super.key, this.property});

  @override
  State<StatefulWidget> createState() => PropertyDetailsScreenState();
}

class PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  late ConversationProvider _conversationProvider;
  late PropertyProvider _propertyProvider;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  Conversation conversation = Conversation();
  Conversation? newConversation;
  final TextEditingController _descriptionController = TextEditingController();

  int? get userId => Authorization.userId;

  bool _loading = true;
  bool _chatLoading = false;
  Property? _property;
  List<Photo> images = [];
  List<Property> recommendedProperties = [];

  // ── lifecycle ────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _conversationProvider = context.read<ConversationProvider>();
    _propertyProvider = context.read<PropertyProvider>();
    _loadFullProperty();
    _fetchRecommendations();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ── data loading ──────────────────────────────────────────────────────────

  Future<void> _loadFullProperty() async {
    final id = widget.property?.id;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final full = await _propertyProvider.getById(id);
      final validImages = (full.photos ?? [])
          .where((p) => p.url != null && p.url!.isNotEmpty && p.url != 'a')
          .toList();
      if (mounted) {
        setState(() {
          _property = full;
          images = validImages;
          _currentPage = 0;
          _descriptionController.text = full.description ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('loadFullProperty error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  void _fetchRecommendations() async {
    final id = widget.property?.id;
    if (id == null) return;
    try {
      final result = await _propertyProvider.getRecommendations(id);
      if (mounted) setState(() => recommendedProperties = result);
    } catch (e) {
      debugPrint('Recommendations error: $e');
    }
  }

  Future<void> addConversation() async {
    try {
      final existing = await _conversationProvider.getByPropertyAndRenter(
        _property!.id!,
        _property!.applicationUserId!,
      );
      final mine = existing.where((c) => c.clientId == userId).firstOrNull;
      if (mine != null) {
        newConversation = mine;
        return;
      }

      final conv = Conversation()
        ..renterId = _property?.applicationUserId
        ..createdAt = DateTime.now()
        ..propertyId = _property?.id
        ..clientId = userId;

      try {
        newConversation = await _conversationProvider.addAsync(conv);
      } catch (_) {}

      if (newConversation == null || (newConversation!.id ?? 0) == 0) {
        final afterCreate = await _conversationProvider.getByPropertyAndRenter(
          _property!.id!,
          _property!.applicationUserId!,
        );
        newConversation =
            afterCreate.where((c) => c.clientId == userId).firstOrNull;
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          title: const Text('Detalji nekretnine',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final p = _property;
    if (p == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: _kPrimary,
          foregroundColor: Colors.white,
          title: const Text('Detalji nekretnine'),
        ),
        body: const Center(child: Text('Nekretnina nije pronađena.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Text(
          p.name ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (images.isNotEmpty) _buildPhotoCarousel(),
            _buildHeaderCard(p),
            _buildStatsCard(p),
            _buildAmenitiesCard(p),
            if ((p.latitude ?? 0) != 0 && (p.longitude ?? 0) != 0)
              _buildMapSection(p),
            _buildDescriptionCard(),
            _buildActions(p),
            if (recommendedProperties.isNotEmpty) _buildRecommended(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── Photo carousel ────────────────────────────────────────────────────────

  Widget _buildPhotoCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => Image.network(
              '${AppConfig.serverBase}${images[i].url ?? ''}',
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) =>
                  progress == null ? child : _photoPlaceholder(),
              errorBuilder: (_, __, ___) => _photoPlaceholder(),
            ),
          ),
        ),
        // Dots + counter row
        Container(
          color: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (images.length > 1) ...[
                ...List.generate(
                  images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: _currentPage == i ? 16 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white38,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Text(
                '${_currentPage + 1} / ${images.length}',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _photoPlaceholder() => Container(
        color: Colors.grey.shade300,
        child: const Icon(Icons.home_work,
            size: 72, color: Colors.grey),
      );

  // ── Header card ───────────────────────────────────────────────────────────

  Widget _buildHeaderCard(Property p) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name + availability
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  p.name ?? '',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),
              const SizedBox(width: 8),
              _AvailabilityBadge(available: p.isAvailable ?? false, availableFrom: p.availableFrom),
            ],
          ),
          const SizedBox(height: 10),
          // Location row
          _InfoRow(
              icon: Icons.location_city,
              text:
                  '${p.city?.name ?? ''}  •  ${p.propertyType?.name ?? ''}'),
          if ((p.address ?? '').isNotEmpty)
            _InfoRow(icon: Icons.place_outlined, text: p.address!),
          if (p.applicationUser != null)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        RenterProfileScreen(renter: p.applicationUser, renterId: p.applicationUserId)),
              ),
              child: _InfoRow(
                  icon: Icons.person_outline,
                  text:
                      'Izdavač: ${p.applicationUser!.userName ?? ''}  ›'),
            ),
          const SizedBox(height: 12),
          // Price chips
          Wrap(
            spacing: 8,
            children: [
              if (p.isMonthly == true)
                _PriceChip(
                    '${p.monthlyPrice?.toStringAsFixed(0) ?? '—'} BAM/mj.'),
              if (p.isDaily == true)
                _PriceChip(
                    '${p.dailyPrice?.toStringAsFixed(0) ?? '—'} BAM/dan'),
              if ((p.averageRating ?? 0) > 0)
                _RatingChip(p.averageRating!),
            ],
          ),
        ],
      ),
    );
  }

  // ── Stats card ────────────────────────────────────────────────────────────

  Widget _buildStatsCard(Property p) {
    final stats = <_StatItem>[
      _StatItem(Icons.bed_outlined, '${p.numberOfRooms ?? 0}', 'Sobe'),
      _StatItem(Icons.bathtub_outlined, '${p.numberOfBathrooms ?? 0}',
          'Kupaonice'),
      _StatItem(Icons.aspect_ratio, '${p.squareMeters ?? 0} m²', 'Površina'),
      _StatItem(Icons.people_outline, '${p.capacity ?? 0}', 'Gosti'),
      if ((p.gardenSize ?? 0) > 0)
        _StatItem(Icons.park_outlined, '${p.gardenSize} m²', 'Vrt'),
      if ((p.numberOfGarages ?? 0) > 0)
        _StatItem(Icons.garage_outlined, '${p.numberOfGarages}', 'Garaže'),
      if ((p.parkingSize ?? 0) > 0)
        _StatItem(Icons.local_parking, '${p.parkingSize}', 'Parking'),
    ];

    return _DetailCard(
      title: 'Karakteristike',
      titleIcon: Icons.info_outline,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 2.2,
        children: stats
            .map((s) => _StatCell(icon: s.icon, value: s.value, label: s.label))
            .toList(),
      ),
    );
  }

  // ── Amenities card ────────────────────────────────────────────────────────

  Widget _buildAmenitiesCard(Property p) {
    final amenities = <_AmenityItem>[
      _AmenityItem(Icons.wifi, 'Wi-Fi', p.hasWiFi == true),
      _AmenityItem(Icons.chair_outlined, 'Namješteno', p.isFurnished == true),
      _AmenityItem(Icons.balcony_outlined, 'Balkon', p.hasBalcony == true),
      _AmenityItem(Icons.pool, 'Bazen', p.hasPool == true),
      _AmenityItem(Icons.ac_unit, 'Klima', p.hasAirCondition == true),
      _AmenityItem(Icons.security, 'Alarm', p.hasAlarm == true),
      _AmenityItem(Icons.tv, 'TV', p.hasTV == true),
      _AmenityItem(Icons.cable, 'Kabelska TV', p.hasCableTV == true),
      _AmenityItem(
          Icons.videocam_outlined, 'Nadzor', p.hasSurveilance == true),
      _AmenityItem(Icons.local_parking, 'Parking', p.hasParking == true),
      _AmenityItem(Icons.garage_outlined, 'Garaža', p.hasGarage == true),
      _AmenityItem(
          Icons.heat_pump_outlined, 'Grijanje', p.hasOwnHeatingSystem == true),
    ];

    return _DetailCard(
      title: 'Sadržaji',
      titleIcon: Icons.checklist_outlined,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: amenities.map((a) => _AmenityChip(a)).toList(),
      ),
    );
  }

  // ── Map section ───────────────────────────────────────────────────────────

  Widget _buildMapSection(Property p) {
    final point = LatLng(p.latitude!, p.longitude!);
    return _DetailCard(
      title: 'Lokacija',
      titleIcon: Icons.map_outlined,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: 220,
          child: FlutterMap(
            options: MapOptions(
              center: point,
              zoom: 14.0,
              interactiveFlags:
                  InteractiveFlag.pinchZoom | InteractiveFlag.drag,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.propertease.client',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    builder: (_) => const Icon(Icons.location_pin,
                        color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Description card ──────────────────────────────────────────────────────

  Widget _buildDescriptionCard() {
    if (_descriptionController.text.isEmpty) return const SizedBox.shrink();
    return _DetailCard(
      title: 'Opis',
      titleIcon: Icons.notes_outlined,
      child: TextField(
        controller: _descriptionController,
        minLines: 3,
        maxLines: 12,
        readOnly: true,
        style: const TextStyle(fontSize: 14, height: 1.6),
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          filled: true,
          fillColor: Colors.grey.shade50,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────────

  Widget _buildActions(Property p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      child: Column(
        children: [
          // Top row: Reserve + Chat
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.calendar_month,
                  label: 'Rezerviši',
                  color: _kPrimary,
                  textColor: Colors.white,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReservationAddScreen(property: p),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.message_outlined,
                  label: 'Pitanje',
                  color: Colors.white,
                  textColor: _kPrimary,
                  borderColor: _kPrimary,
                  isLoading: _chatLoading,
                  onTap: _chatLoading
                      ? null
                      : () async {
                          setState(() => _chatLoading = true);
                          await addConversation();
                          setState(() => _chatLoading = false);
                          if (newConversation == null ||
                              newConversation!.id == null ||
                              newConversation!.id == 0) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Nije moguće otvoriti chat. Pokušajte ponovo.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                            return;
                          }
                          if (!context.mounted) return;
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => MessageListScreen(
                              conversationId: newConversation?.id,
                              recipientId: p.applicationUserId,
                              chatTitle: p.name ?? 'Chat',
                              otherUserPhotoBytes:
                                  p.applicationUser?.person?.profilePhotoBytes,
                              myPhotoBytes: Authorization.profilePhotoBytes,
                            ),
                          ));
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Bottom row: Compare + Reviews
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.compare_arrows,
                  label: 'Usporedi',
                  color: Colors.white,
                  textColor: _kPrimary,
                  borderColor: _kPrimary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PropertyCompareScreen(propertyA: p),
                  )),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.star_outline,
                  label: 'Recenzije',
                  color: Colors.white,
                  textColor: _kPrimary,
                  borderColor: _kPrimary,
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ReviewListScreen(id: p.id),
                  )),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // ── Recommended ───────────────────────────────────────────────────────────

  Widget _buildRecommended() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          child: Row(
            children: [
              const Icon(Icons.recommend, color: _kPrimary, size: 20),
              const SizedBox(width: 8),
              const Text('Možda vas zanima',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        SizedBox(
          height: 170,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: recommendedProperties.length,
            itemBuilder: (_, i) {
              final rec = recommendedProperties[i];
              final rawUrl = (rec.firstPhotoUrl != null &&
                      rec.firstPhotoUrl!.isNotEmpty)
                  ? rec.firstPhotoUrl
                  : (rec.photos != null && rec.photos!.isNotEmpty
                      ? rec.photos!.first.url
                      : null);
              final photoUrl = (rawUrl != null && rawUrl.isNotEmpty)
                  ? '${AppConfig.serverBase}$rawUrl'
                  : null;
              return GestureDetector(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => PropertyDetailsScreen(property: rec),
                )),
                child: Container(
                  width: 165,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black12,
                          blurRadius: 6,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(14)),
                        child: SizedBox(
                          height: 90,
                          width: 165,
                          child: photoUrl != null
                              ? Image.network(photoUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                      color: Colors.blue.shade50,
                                      child: const Icon(Icons.house,
                                          size: 40,
                                          color: _kPrimary)))
                              : Container(
                                  color: Colors.blue.shade50,
                                  child: const Icon(Icons.house,
                                      size: 40, color: _kPrimary)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rec.name ?? '',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(rec.city?.name ?? '',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              rec.isMonthly == true
                                  ? '${rec.monthlyPrice?.toStringAsFixed(0) ?? ''} BAM/mj.'
                                  : '${rec.dailyPrice?.toStringAsFixed(0) ?? ''} BAM/dan',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _kPrimary,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ── Small data classes ─────────────────────────────────────────────────────────

class _StatItem {
  final IconData icon;
  final String value;
  final String label;
  const _StatItem(this.icon, this.value, this.label);
}

class _AmenityItem {
  final IconData icon;
  final String label;
  final bool available;
  const _AmenityItem(this.icon, this.label, this.available);
}

// ── Reusable widgets ───────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final String? title;
  final IconData? titleIcon;
  final Widget child;

  const _DetailCard({this.title, this.titleIcon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (titleIcon != null) ...[
                    Icon(titleIcon, size: 18, color: _kPrimary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kPrimary,
                        letterSpacing: 0.3),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 13.5, color: Colors.grey.shade700),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCell(
      {required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: _kPrimary),
            const SizedBox(width: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
      ],
    );
  }
}

class _AmenityChip extends StatelessWidget {
  final _AmenityItem item;
  const _AmenityChip(this.item);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: item.available
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              item.available ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            item.available ? Icons.check_circle : Icons.cancel_outlined,
            size: 14,
            color: item.available ? Colors.green : Colors.grey.shade400,
          ),
          const SizedBox(width: 5),
          Text(
            item.label,
            style: TextStyle(
                fontSize: 12,
                color: item.available
                    ? Colors.green.shade800
                    : Colors.grey.shade500,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final bool available;
  final DateTime? availableFrom;
  const _AvailabilityBadge({required this.available, this.availableFrom});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final String label;

    if (available) {
      color = Colors.green;
      label = 'Dostupno';
    } else if (availableFrom != null) {
      color = Colors.orange;
      final d = availableFrom!;
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
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _PriceChip extends StatelessWidget {
  final String text;
  const _PriceChip(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: _kPrimary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip(this.rating);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star, size: 14, color: Colors.amber),
          const SizedBox(width: 4),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final Color? borderColor;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.borderColor,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1.5)
                : null,
          ),
          child: isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: textColor, size: 22),
                    const SizedBox(height: 4),
                    Text(label,
                        style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
        ),
      ),
    );
  }
}
