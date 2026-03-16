import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/application_role.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/providers/application_role_provider.dart';
import 'package:propertease_admin/providers/application_user_provider.dart';
import 'package:provider/provider.dart';

class UserDetailScreen extends StatefulWidget {
  // ignore: must_be_immutable
  ApplicationUser? user;
  UserDetailScreen({super.key, this.user});

  @override
  State<StatefulWidget> createState() => UserDetailScreenState();
}

class UserDetailScreenState extends State<UserDetailScreen> {
  late UserProvider _userProvider;
  late RoleProvider _roleProvider;
  List<Map<String, dynamic>> _userRoles = [];
  List<ApplicationRole> _allRoles = [];

  @override
  void initState() {
    super.initState();
    _userProvider = context.read<UserProvider>();
    _roleProvider = context.read<RoleProvider>();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      final results = await Future.wait([
        _userProvider.getUserRoles(widget.user!.id!),
        _roleProvider.get(),
      ]);
      if (mounted) {
        setState(() {
          _userRoles = results[0] as List<Map<String, dynamic>>;
          _allRoles = (results[1] as dynamic).result as List<ApplicationRole>;
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _assignRole() async {
    final assignedRoleIds = _userRoles.map((r) => r['roleId'] as int?).toSet();
    final available = _allRoles.where((r) => !assignedRoleIds.contains(r.id)).toList();
    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All roles are already assigned.')),
      );
      return;
    }

    ApplicationRole? selected;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlg) => AlertDialog(
          title: const Text('Assign Role'),
          content: DropdownButtonFormField<ApplicationRole>(
            decoration: const InputDecoration(labelText: 'Role'),
            items: available.map((r) => DropdownMenuItem(value: r, child: Text(r.name ?? ''))).toList(),
            onChanged: (v) => setDlg(() => selected = v),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Assign')),
          ],
        ),
      ),
    );
    if (confirmed != true || selected == null) return;
    try {
      await _userProvider.assignRole(widget.user!.id!, selected!.id!);
      await _loadRoles();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _removeRole(Map<String, dynamic> userRole) async {
    final name = userRole['role']?['name'] ?? 'this role';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Role'),
        content: Text('Remove "$name" from this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _userProvider.removeUserRole(widget.user!.id!, userRole['roleId'] as int);
      await _loadRoles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Uloga "$name" uklonjena'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Greška pri uklanjanju uloge: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _fmt(DateTime? d) =>
      d != null ? DateFormat('dd.MM.yyyy').format(d) : '—';

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final photoUrl = u?.person?.profilePhoto != null
        ? '${AppConfig.serverBase}${u!.person!.profilePhoto}'
        : null;
    final roleName = u?.userRoles?.isNotEmpty == true
        ? u!.userRoles![0].role?.name ?? '—'
        : '—';

    return Scaffold(
      appBar: AppBar(title: const Text('Detalji korisnika')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile header card ─────────────────────────────────────────
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: Colors.blue.shade50,
                      backgroundImage: photoUrl != null
                          ? NetworkImage(photoUrl) as ImageProvider
                          : null,
                      child: photoUrl == null
                          ? Icon(Icons.person,
                              size: 56, color: Colors.blue.shade200)
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${u?.person?.firstName ?? ''} ${u?.person?.lastName ?? ''}'
                                .trim(),
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '@${u?.userName ?? ''}',
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(
                                    Icons.verified_user_outlined,
                                    size: 14),
                                label: Text(roleName),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: TextStyle(
                                    color: Colors.blue.shade700,
                                    fontSize: 12),
                                padding: EdgeInsets.zero,
                              ),
                              if (u?.person?.gender != null)
                                Chip(
                                  avatar: Icon(
                                    u!.person!.gender == 0
                                        ? Icons.male
                                        : Icons.female,
                                    size: 14,
                                  ),
                                  label: Text(u.person!.gender == 0
                                      ? 'Muški'
                                      : 'Ženski'),
                                  backgroundColor: Colors.grey.shade100,
                                  labelStyle: const TextStyle(fontSize: 12),
                                  padding: EdgeInsets.zero,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Lični podaci ────────────────────────────────────────────────
            _SectionCard(
              title: 'Lični podaci',
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: _InfoTile(
                            Icons.badge_outlined,
                            'JMBG',
                            u?.person?.jmbg ?? '—')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _InfoTile(
                            Icons.cake_outlined,
                            'Datum rođenja',
                            _fmt(u?.person?.birthDate))),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _InfoTile(
                            Icons.location_city_outlined,
                            'Grad',
                            u?.person?.placeOfResidence?.name ?? '—')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _InfoTile(
                            Icons.home_outlined,
                            'Adresa',
                            u?.person?.address ?? '—')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _InfoTile(
                            Icons.markunread_mailbox_outlined,
                            'Poštanski broj',
                            u?.person?.postCode ?? '—')),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox.shrink()),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Podaci naloga ───────────────────────────────────────────────
            _SectionCard(
              title: 'Podaci naloga',
              child: Column(
                children: [
                  Row(children: [
                    Expanded(
                        child: _InfoTile(
                            Icons.person_outline,
                            'Korisničko ime',
                            u?.userName ?? '—')),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _InfoTile(
                            Icons.email_outlined,
                            'Email',
                            u?.email ?? '—')),
                  ]),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                        child: _InfoTile(
                            Icons.phone_outlined,
                            'Telefon',
                            u?.phoneNumber ?? '—')),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox.shrink()),
                  ]),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Roles ───────────────────────────────────────────────────────
            _SectionCard(
              title: 'Roles',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ..._userRoles.map((ur) => Chip(
                            label: Text(ur['role']?['name'] ?? ''),
                            deleteIcon: const Icon(Icons.close, size: 16),
                            onDeleted: () => _removeRole(ur),
                            backgroundColor: Colors.blue.shade50,
                            labelStyle: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                          )),
                      ActionChip(
                        avatar: const Icon(Icons.add, size: 16),
                        label: const Text('Assign role'),
                        onPressed: _assignRole,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade300),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade500)),
              const SizedBox(height: 2),
              Text(value.isEmpty ? '—' : value,
                  style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

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
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14)),
            const Divider(height: 20),
            child,
          ],
        ),
      ),
    );
  }
}
