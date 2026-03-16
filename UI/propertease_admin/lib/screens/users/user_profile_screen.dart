import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../models/application_user.dart';
import '../../providers/application_user_provider.dart';
import '../../providers/property_reservation_provider.dart';

const _pageSize = 10;

class UserProfileScreen extends StatefulWidget {
  final ApplicationUser? user;
  final int? userId;
  const UserProfileScreen({super.key, this.user, this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  ApplicationUser? _user;
  List<ReservationSummary> _reservations = [];
  bool _userLoading = true;
  bool _resLoading = true;
  int _resPage = 1;
  int _resTotalCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _user = widget.user;
      _userLoading = false;
    }
    _load();
  }

  Future<void> _load() async {
    final userProvider = context.read<UserProvider>();

    if (_user == null && widget.userId != null) {
      try {
        final user = await userProvider.getById(widget.userId!);
        if (mounted) setState(() { _user = user; _userLoading = false; });
      } catch (_) {
        if (mounted) setState(() => _userLoading = false);
      }
    }

    _loadReservations(page: 1);
  }

  Future<void> _loadReservations({required int page}) async {
    final id = _user?.id ?? widget.userId;
    if (id == null) { if (mounted) setState(() => _resLoading = false); return; }

    if (mounted) setState(() => _resLoading = true);
    try {
      final resProvider = context.read<PropertyReservationProvider>();
      final result = await resProvider.getClientSummaries(id, page: page, pageSize: _pageSize);
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

  @override
  Widget build(BuildContext context) {
    if (_userLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil korisnika')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final u = _user;
    if (u == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profil korisnika')),
        body: const Center(child: Text('Korisnik nije pronađen.')),
      );
    }

    final name = '${u.person?.firstName ?? ''} ${u.person?.lastName ?? ''}'.trim();
    final photoUrl = (u.person?.profilePhoto?.isNotEmpty == true)
        ? '${AppConfig.serverBase}${u.person!.profilePhoto}'
        : null;

    return Scaffold(
      appBar: AppBar(title: Text(name.isNotEmpty ? name : 'Profil korisnika')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(u, photoUrl, name),
            const SizedBox(height: 16),
            _buildReservationsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(ApplicationUser u, String? photoUrl, String name) {
    return _Card(
      title: 'Lični podaci',
      icon: Icons.person,
      child: Column(
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: Colors.blue.shade50,
              backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
              child: photoUrl == null
                  ? Icon(Icons.person, size: 48, color: Colors.blue.shade200)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          if (name.isNotEmpty)
            Center(child: Text(name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          const Divider(height: 24),
          _row(Icons.alternate_email, 'Korisničko ime', u.userName),
          _row(Icons.email_outlined, 'Email', u.email),
          _row(Icons.phone_outlined, 'Telefon', u.phoneNumber),
          _row(Icons.location_city, 'Grad', u.person?.placeOfResidence?.name),
          _row(Icons.home_outlined, 'Adresa', u.person?.address),
          _row(Icons.markunread_mailbox_outlined, 'Poštanski broj', u.person?.postCode),
          _row(Icons.fingerprint, 'JMBG', u.person?.jmbg),
          if (u.person?.birthDate != null)
            _row(Icons.cake_outlined, 'Datum rođenja',
                DateFormat('dd.MM.yyyy').format(u.person!.birthDate!)),
          if (u.person?.gender != null)
            _row(Icons.wc, 'Spol', u.person!.gender == 0 ? 'Muški' : 'Ženski'),
        ],
      ),
    );
  }

  Widget _buildReservationsCard() {
    final totalPages = (_resTotalCount / _pageSize).ceil();
    return _Card(
      title: 'Historija rezervacija',
      icon: Icons.history,
      child: _resLoading
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              children: [
                if (_reservations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: Text('Nema rezervacija.')),
                  )
                else
                  ..._reservations.map((r) {
                    final dateRange = r.dateOfOccupancyStart != null &&
                            r.dateOfOccupancyEnd != null
                        ? '${DateFormat('dd.MM.yy').format(r.dateOfOccupancyStart!)} – ${DateFormat('dd.MM.yy').format(r.dateOfOccupancyEnd!)}'
                        : null;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: r.isActive == true
                            ? Colors.green.shade50
                            : Colors.grey.shade100,
                        child: Icon(Icons.receipt_long,
                            color: r.isActive == true ? Colors.green : Colors.grey),
                      ),
                      title: Text(r.reservationNumber ?? '—'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.propertyName ?? '—',
                              style: const TextStyle(fontSize: 12)),
                          if (dateRange != null)
                            Text(dateRange,
                                style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                              r.totalPrice != null
                                  ? '${r.totalPrice!.toStringAsFixed(2)} KM'
                                  : '—',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                          Text(r.isActive == true ? 'Aktivna' : 'Završena',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: r.isActive == true
                                      ? Colors.green
                                      : Colors.grey)),
                        ],
                      ),
                    );
                  }),
                if (_resTotalCount > _pageSize)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: _resPage > 1
                              ? () => _loadReservations(page: _resPage - 1)
                              : null,
                        ),
                        Text('$_resPage / $totalPages',
                            style: const TextStyle(fontSize: 13)),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: _resPage < totalPages
                              ? () => _loadReservations(page: _resPage + 1)
                              : null,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _row(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey.shade500),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(label,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  const _Card({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
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
            Row(children: [
              Icon(icon, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
            ]),
            const Divider(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
