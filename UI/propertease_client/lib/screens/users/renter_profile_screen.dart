import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:provider/provider.dart';

import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/property.dart';
import 'package:propertease_client/models/user_rating.dart';
import 'package:propertease_client/providers/application_user_provider.dart';
import 'package:propertease_client/providers/property_provider.dart';
import 'package:propertease_client/providers/property_reservation_provider.dart';
import 'package:propertease_client/providers/user_rating_provider.dart';
import 'package:propertease_client/screens/property/property_details.dart';

const _kPrimary = Color(0xFF115892);
const _kPageSize = 10;

class RenterProfileScreen extends StatefulWidget {
  final ApplicationUser? renter;
  final int? renterId;
  const RenterProfileScreen({super.key, this.renter, this.renterId});

  @override
  State<RenterProfileScreen> createState() => _RenterProfileScreenState();
}

class _RenterProfileScreenState extends State<RenterProfileScreen> {
  ApplicationUser? _fetchedRenter;

  // Properties
  List<Property> _properties = [];
  bool _propsLoading = true;
  int _propsPage = 1;
  int _propsTotalCount = 0;

  // Reservations
  List<ReservationSummary> _reservations = [];
  bool _resLoading = true;
  int _resPage = 1;
  int _resTotalCount = 0;

  // Ratings
  List<UserRating> _ratings = [];
  bool _ratingsLoading = true;
  int _ratingsPage = 1;
  int _ratingsTotalCount = 0;
  double _averageRating = 0;

  ApplicationUser? get _renter => _fetchedRenter ?? widget.renter;

  @override
  void initState() {
    super.initState();
    final hasFullData = widget.renter != null &&
        widget.renter!.userName?.isNotEmpty == true &&
        widget.renter!.email?.isNotEmpty == true;
    if (!hasFullData) _loadRenter();
    _loadProperties(page: 1);
    _loadReservations(page: 1);
    _loadRatings(page: 1);
  }

  Future<void> _loadRenter() async {
    final id = _effectiveRenterId;
    if (id == null) return;
    try {
      final r = await context.read<UserProvider>().getRenterById(id);
      if (mounted) setState(() => _fetchedRenter = r);
    } catch (_) {}
  }

  int? get _effectiveRenterId {
    if (widget.renterId != null && widget.renterId! > 0) return widget.renterId;
    final rid = widget.renter?.id;
    if (rid != null && rid > 0) return rid;
    return null;
  }

  Future<void> _loadProperties({required int page}) async {
    final id = _effectiveRenterId;
    if (id == null) {
      if (mounted) setState(() => _propsLoading = false);
      return;
    }
    if (mounted) setState(() => _propsLoading = true);
    try {
      final result = await context.read<PropertyProvider>().getFiltered(filter: {
        'ApplicationUserId': id,
        'Page': page,
        'PageSize': _kPageSize,
      });
      if (mounted) {
        setState(() {
          _properties = result.result;
          _propsTotalCount = result.count;
          _propsPage = page;
          _propsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _propsLoading = false);
    }
  }

  Future<void> _loadReservations({required int page}) async {
    final id = _effectiveRenterId;
    if (id == null) {
      if (mounted) setState(() => _resLoading = false);
      return;
    }
    if (mounted) setState(() => _resLoading = true);
    try {
      final result = await context
          .read<PropertyReservationProvider>()
          .getRenterSummaries(id, page: page, pageSize: _kPageSize);
      if (mounted) {
        setState(() {
          _reservations = result.items;
          _resTotalCount = result.totalCount;
          _resPage = page;
          _resLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _resLoading = false);
    }
  }

  Future<void> _loadRatings({required int page}) async {
    final id = _effectiveRenterId;
    if (id == null) {
      if (mounted) setState(() => _ratingsLoading = false);
      return;
    }
    if (mounted) setState(() => _ratingsLoading = true);
    try {
      final provider = context.read<UserRatingProvider>();
      final ratings =
          await provider.getByRenter(id, page: page, pageSize: _kPageSize);
      final avg = page == 1 ? await provider.getAverageRating(id) : _averageRating;
      final total = page == 1 ? await provider.getTotalCount(id) : _ratingsTotalCount;
      if (mounted) {
        setState(() {
          _ratings = ratings;
          _averageRating = avg;
          _ratingsTotalCount = total;
          _ratingsPage = page;
          _ratingsLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _ratingsLoading = false);
    }
  }

  void _showReviewerInfo(UserRating r, String reviewerName) {
    final date = r.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(r.createdAt!)
        : null;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: _kPrimary.withOpacity(0.12),
              child: Text(
                reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
              ),
            ),
            const SizedBox(height: 12),
            Text(reviewerName,
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold)),
            if (date != null) ...[
              const SizedBox(height: 4),
              Text(
                'Ocjenio/la dana $date',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final r = _renter;
    final name =
        '${r?.person?.firstName ?? ''} ${r?.person?.lastName ?? ''}'.trim();
    final displayName = name.isNotEmpty ? name : (r?.userName ?? 'Izdavač');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        title: Text(displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildProfileCard(_renter, displayName),
            const SizedBox(height: 12),
            _buildRatingsCard(),
            const SizedBox(height: 12),
            _buildPropertiesCard(),
            const SizedBox(height: 12),
            _buildReservationsCard(),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(ApplicationUser? r, String displayName) {
    final photoPath = r?.person?.profilePhoto;
    final photoUrl = (photoPath != null && photoPath.isNotEmpty)
        ? '${AppConfig.serverBase}$photoPath'
        : null;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blue.shade50,
              backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? const Icon(Icons.person, size: 48, color: _kPrimary)
                  : null,
            ),
            const SizedBox(height: 12),
            Text(displayName,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            if (r?.userName != null)
              Text('@${r!.userName}',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade600)),
            const SizedBox(height: 8),
            // Average rating badge
            if (!_ratingsLoading && _averageRating > 0)
              _buildAverageBadge(),
            const Divider(height: 24),
            if (r?.email?.isNotEmpty == true)
              _infoRow(Icons.email_outlined, r!.email!),
            if (r?.phoneNumber?.isNotEmpty == true)
              _infoRow(Icons.phone_outlined, r!.phoneNumber!),
            if (r?.person?.placeOfResidence?.name != null)
              _infoRow(
                  Icons.location_city, r!.person!.placeOfResidence!.name!),
          ],
        ),
      ),
    );
  }

  Widget _buildAverageBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 18, color: Colors.amber),
          const SizedBox(width: 4),
          Text(
            _averageRating.toStringAsFixed(1),
            style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.amber),
          ),
          Text(
            ' / 5  ($_ratingsTotalCount ${_ratingsTotalCount == 1 ? 'ocjena' : 'ocjena'})',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingsCard() {
    final totalPages = (_ratingsTotalCount / _kPageSize).ceil().clamp(1, 9999);
    return _SectionCard(
      icon: Icons.star_outline_rounded,
      title: 'Ocjene',
      count: _ratingsLoading ? null : _ratingsTotalCount,
      loading: _ratingsLoading,
      empty: !_ratingsLoading && _ratings.isEmpty,
      emptyText: 'Još nema ocjena.',
      pagination: _ratingsTotalCount > _kPageSize
          ? _PaginationRow(
              page: _ratingsPage,
              totalPages: totalPages,
              onPrev: _ratingsPage > 1
                  ? () => _loadRatings(page: _ratingsPage - 1)
                  : null,
              onNext: _ratingsPage < totalPages
                  ? () => _loadRatings(page: _ratingsPage + 1)
                  : null,
            )
          : null,
      children: _ratings.map((rating) => _buildRatingTile(rating)).toList(),
    );
  }

  Widget _buildRatingTile(UserRating r) {
    final date = r.createdAt != null
        ? DateFormat('dd.MM.yyyy').format(r.createdAt!)
        : '';
    final reviewerName = r.reviewerName?.isNotEmpty == true
        ? r.reviewerName!
        : (r.reviewer?.person?.firstName != null
            ? '${r.reviewer!.person!.firstName} ${r.reviewer!.person!.lastName ?? ''}'.trim()
            : 'Korisnik');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _showReviewerInfo(r, reviewerName),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: _kPrimary.withOpacity(0.12),
              child: Text(
                reviewerName.isNotEmpty ? reviewerName[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => _showReviewerInfo(r, reviewerName),
                      child: Text(reviewerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: _kPrimary,
                              decoration: TextDecoration.underline,
                              decorationColor: _kPrimary)),
                    ),
                    const Spacer(),
                    Text(date,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ],
                ),
                const SizedBox(height: 3),
                _buildStars(r.rating ?? 0),
                if (r.description?.isNotEmpty == true) ...[
                  const SizedBox(height: 4),
                  Text(
                    r.description!,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade700, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (rating >= i + 1) {
          return const Icon(Icons.star_rounded, size: 15, color: Colors.amber);
        } else if (rating > i) {
          return const Icon(Icons.star_half_rounded,
              size: 15, color: Colors.amber);
        }
        return Icon(Icons.star_outline_rounded,
            size: 15, color: Colors.grey.shade300);
      }),
    );
  }

  Widget _buildPropertiesCard() {
    final totalPages = (_propsTotalCount / _kPageSize).ceil();
    return _SectionCard(
      icon: Icons.home_work_outlined,
      title: 'Nekretnine',
      count: _propsLoading ? null : _propsTotalCount,
      loading: _propsLoading,
      empty: !_propsLoading && _properties.isEmpty,
      emptyText: 'Nema nekretnina.',
      pagination: _propsTotalCount > _kPageSize
          ? _PaginationRow(
              page: _propsPage,
              totalPages: totalPages,
              onPrev: _propsPage > 1
                  ? () => _loadProperties(page: _propsPage - 1)
                  : null,
              onNext: _propsPage < totalPages
                  ? () => _loadProperties(page: _propsPage + 1)
                  : null,
            )
          : null,
      children: _properties.map((p) {
        final rawUrl = p.firstPhotoUrl ??
            (p.photos?.isNotEmpty == true ? p.photos!.first.url : null);
        final pUrl = rawUrl != null && rawUrl.isNotEmpty
            ? '${AppConfig.serverBase}$rawUrl'
            : null;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: pUrl != null
                  ? Image.network(pUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
            ),
          ),
          title: Text(p.name ?? '—',
              style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Row(
            children: [
              Text(p.city?.name ?? '—',
                  style: const TextStyle(fontSize: 12)),
              if ((p.averageRating ?? 0) > 0) ...[
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 12, color: Colors.amber),
                Text(' ${p.averageRating?.toStringAsFixed(1)}',
                    style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
          trailing: Text(
            p.isMonthly == true
                ? '${p.monthlyPrice?.toStringAsFixed(0)} BAM/mj.'
                : '${p.dailyPrice?.toStringAsFixed(0)} BAM/dan',
            style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PropertyDetailsScreen(property: p))),
        );
      }).toList(),
    );
  }

  Widget _buildReservationsCard() {
    final totalPages = (_resTotalCount / _kPageSize).ceil();
    return _SectionCard(
      icon: Icons.receipt_long,
      title: 'Historija rezervacija',
      count: _resLoading ? null : _resTotalCount,
      loading: _resLoading,
      empty: !_resLoading && _reservations.isEmpty,
      emptyText: 'Nema rezervacija.',
      pagination: _resTotalCount > _kPageSize
          ? _PaginationRow(
              page: _resPage,
              totalPages: totalPages,
              onPrev:
                  _resPage > 1 ? () => _loadReservations(page: _resPage - 1) : null,
              onNext: _resPage < totalPages
                  ? () => _loadReservations(page: _resPage + 1)
                  : null,
            )
          : null,
      children: _reservations.map((r) {
        final fmt = DateFormat('dd.MM.yy');
        final dateRange =
            r.dateOfOccupancyStart != null && r.dateOfOccupancyEnd != null
                ? '${fmt.format(r.dateOfOccupancyStart!)} – ${fmt.format(r.dateOfOccupancyEnd!)}'
                : null;
        return ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor:
                r.isActive == true ? Colors.green.shade50 : Colors.grey.shade100,
            child: Icon(Icons.receipt_long,
                color: r.isActive == true ? Colors.green : Colors.grey,
                size: 20),
          ),
          title: Text(r.propertyName ?? '—',
              style:
                  const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: dateRange != null
              ? Text(dateRange,
                  style: const TextStyle(fontSize: 12, color: Colors.grey))
              : null,
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${r.totalPrice?.toStringAsFixed(0) ?? '—'} BAM',
                style: const TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              Text(
                r.isActive == true ? 'Aktivna' : 'Završena',
                style: TextStyle(
                    fontSize: 11,
                    color: r.isActive == true ? Colors.green : Colors.grey),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
        ]),
      );

  Widget _placeholder() => Container(
      color: Colors.blue.shade50,
      child: const Icon(Icons.home, color: _kPrimary));
}

// ── Reusable section card ──────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final int? count;
  final bool loading;
  final bool empty;
  final String emptyText;
  final Widget? pagination;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.count,
    required this.loading,
    required this.empty,
    required this.emptyText,
    this.pagination,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: _kPrimary),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (loading)
                const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else if (count != null)
                Text('$count',
                    style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 16),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (empty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(child: Text(emptyText)),
              )
            else
              ...children,
            if (pagination != null) pagination!,
          ],
        ),
      ),
    );
  }
}

// ── Pagination row ─────────────────────────────────────────────────────────────

class _PaginationRow extends StatelessWidget {
  final int page;
  final int totalPages;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  const _PaginationRow({
    required this.page,
    required this.totalPages,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: onPrev,
              padding: EdgeInsets.zero),
          Text('$page / $totalPages',
              style: const TextStyle(fontSize: 13)),
          IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: onNext,
              padding: EdgeInsets.zero),
        ],
      ),
    );
  }
}
