import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/application_user.dart';
import 'package:propertease_admin/models/conversation.dart';
import 'package:propertease_admin/providers/conversation_provider.dart';
import 'package:propertease_admin/screens/messaging/message_list_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart' as signalr;

class ConversationListScreen extends StatefulWidget {
  const ConversationListScreen({super.key});

  @override
  State<StatefulWidget> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  late ConversationProvider _provider;
  List<Conversation> _propertyConversations = [];
  List<Conversation> _adminConversations = [];
  bool _loading = true;
  String? _error;
  late signalr.HubConnection _signalR;

  @override
  void initState() {
    super.initState();
    _provider = context.read<ConversationProvider>();
    _fetchAll();
    _initSignalR();
  }

  void _initSignalR() async {
    try {
      _signalR = signalr.HubConnectionBuilder()
          .withUrl(
            '${AppConfig.serverBase}/hubs/messageHub',
            signalr.HttpConnectionOptions(
              client: IOClient(
                  HttpClient()..badCertificateCallback = (x, y, z) => true),
              logging: (level, message) {},
            ),
          )
          .build();
      _signalR.on('newMessage', (_) => _fetchAll(silent: true));
      await _signalR.start();
    } catch (e) {
      debugPrint('SignalR error: $e');
    }
  }

  @override
  void dispose() {
    _signalR.off('newMessage');
    _signalR.stop();
    super.dispose();
  }

  Future<void> _fetchAll({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final userId = Authorization.userId!;
      final isRenter = Authorization.isRenter;

      List<Conversation> propConvs = [];
      if (isRenter) {
        final result = await _provider.getByPropertyAndRenter(null, userId);
        propConvs = result.result;
      }

      final adminResult = await _provider.getAdminConversations(userId);

      if (mounted) {
        setState(() {
          _propertyConversations = propConvs;
          _adminConversations = adminResult.result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Inbox')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : RefreshIndicator(
                  onRefresh: () => _fetchAll(),
                  child: _buildBody(),
                ),
    );
  }

  Widget _buildBody() {
    final showPropertySection = Authorization.isRenter;

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (showPropertySection) ...[
          _sectionHeader(
            icon: Icons.home_work_outlined,
            label: 'Razgovori o nekretninama',
            count: _propertyConversations
                .where((c) => (c.unreadCount ?? 0) > 0)
                .length,
          ),
          if (_propertyConversations.isEmpty)
            _emptyState('Nema razgovora o nekretninama.')
          else
            ..._propertyConversations.map(
                (c) => _ConversationCard(
                      conversation: c,
                      currentUserId: Authorization.userId,
                      isAdminConv: false,
                      onTap: () => _openConversation(c,
                          _otherUser(c, Authorization.userId)),
                    )),
        ],

        _sectionHeader(
          icon: Icons.support_agent_outlined,
          label: Authorization.isAdmin
              ? 'Poruke upućene meni'
              : 'Razgovori s administratorom',
          count: _adminConversations
              .where((c) => (c.unreadCount ?? 0) > 0)
              .length,
          trailing: !Authorization.isAdmin
              ? IconButton(
                  icon: const Icon(Icons.add_comment_outlined),
                  tooltip: 'Novi razgovor s administratorom',
                  onPressed: _startNewAdminConversation,
                )
              : null,
        ),
        if (_adminConversations.isEmpty)
          _emptyState('Nema poruka.')
        else
          ..._adminConversations.map((c) => _ConversationCard(
                conversation: c,
                currentUserId: Authorization.userId,
                isAdminConv: true,
                onTap: () => _openConversation(
                    c, _otherUser(c, Authorization.userId)),
              )),

        const SizedBox(height: 16),
      ],
    );
  }

  ApplicationUser? _otherUser(Conversation c, int? me) =>
      (c.client?.id != me) ? c.client : c.renter;

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    int count = 0,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.blueGrey.shade400),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: Colors.blueGrey.shade600,
              letterSpacing: 0.3,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _emptyState(String message) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(message, style: const TextStyle(color: Colors.black38)),
      );

  void _openConversation(Conversation conversation, ApplicationUser? other) {
    final me = Authorization.userId!;
    final recipientId = (conversation.clientId != me)
        ? conversation.clientId
        : conversation.renterId;
    final recipientName =
        '${other?.person?.firstName ?? ''} ${other?.person?.lastName ?? ''}'
            .trim();

    Navigator.of(context)
        .push(MaterialPageRoute(
          builder: (_) => MessageListScreen(
            conversationId: conversation.id,
            recipientId: recipientId,
            recipientName: recipientName.isNotEmpty ? recipientName : null,
            recipientPhotoBytes: other?.person?.profilePhotoBytes,
            recipientPhotoUrl: other?.person?.profilePhoto,
            onConversationListUpdated: () => _fetchAll(silent: true),
          ),
        ))
        .then((_) => _fetchAll(silent: true));
  }

  Future<void> _startNewAdminConversation() async {
    try {
      final admins = await _provider.getAdmins();
      if (!mounted) return;
      if (admins.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nema dostupnih administratora.')));
        return;
      }
      showModalBottomSheet(
        context: context,
        builder: (_) => _AdminPickerSheet(
          admins: admins,
          onSelected: _openOrCreateAdminConversation,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Greška: $e')));
      }
    }
  }

  void _openOrCreateAdminConversation(ApplicationUser admin) async {
    Navigator.of(context).pop();
    final me = Authorization.userId!;

    for (final c in _adminConversations) {
      if ((c.clientId == me && c.renterId == admin.id) ||
          (c.renterId == me && c.clientId == admin.id)) {
        _openConversation(c, admin);
        return;
      }
    }

    try {
      final newConv = Conversation(clientId: me, renterId: admin.id);
      final created = await _provider.addAsync(newConv);
      if (mounted) {
        _openConversation(created, admin);
        _fetchAll(silent: true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Greška pri kreiranju razgovora: $e')));
      }
    }
  }
}

class _ConversationCard extends StatelessWidget {
  static final _imgCache = <String, Uint8List>{};

  final Conversation conversation;
  final int? currentUserId;
  final bool isAdminConv;
  final VoidCallback onTap;

  const _ConversationCard({
    required this.conversation,
    required this.currentUserId,
    required this.isAdminConv,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final other = (conversation.client?.id != currentUserId)
        ? conversation.client
        : conversation.renter;
    final name =
        '${other?.person?.firstName ?? ''} ${other?.person?.lastName ?? ''}'
            .trim();
    final displayName =
        name.isNotEmpty ? name : (other?.userName ?? 'Korisnik');
    final unread = conversation.unreadCount ?? 0;
    final hasUnread = unread > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      elevation: hasUnread ? 3 : 1,
      shadowColor: hasUnread ? Colors.blue.shade100 : Colors.black12,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: hasUnread
            ? BorderSide(color: Colors.blue.shade200, width: 1.5)
            : BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildAvatar(other?.person?.profilePhotoBytes, unread,
                  photoUrl: other?.person?.profilePhoto),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: TextStyle(
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(conversation.lastSent),
                          style: TextStyle(
                            fontSize: 11,
                            color: hasUnread
                                ? Colors.blue.shade600
                                : Colors.grey,
                            fontWeight: hasUnread
                                ? FontWeight.w600
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (!isAdminConv &&
                        conversation.property?.name != null) ...[
                      const SizedBox(height: 3),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          conversation.property!.name!,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (conversation.lastMessage != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        conversation.lastMessage!.length > 60
                            ? '${conversation.lastMessage!.substring(0, 60)}...'
                            : conversation.lastMessage!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: hasUnread
                              ? Colors.black87
                              : Colors.grey.shade600,
                          fontWeight: hasUnread
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Uint8List? _cachedBytes(String? b64) {
    if (b64 == null || b64.isEmpty) return null;
    if (_imgCache.containsKey(b64)) {
      final cached = _imgCache[b64]!;
      return cached.isEmpty ? null : cached;
    }
    try {
      final bytes = base64Decode(b64);
      _imgCache[b64] = bytes;
      return bytes;
    } catch (_) {
      _imgCache[b64] = Uint8List(0);
      return null;
    }
  }

  Widget _buildAvatar(String? photoBytes, int unread, {String? photoUrl}) {
    Widget avatar;
    final decoded = _cachedBytes(photoBytes);
    if (decoded != null) {
      avatar = CircleAvatar(radius: 24, backgroundImage: MemoryImage(decoded));
    } else if (photoUrl != null && photoUrl.isNotEmpty) {
      avatar = CircleAvatar(
          radius: 24,
          backgroundImage:
              NetworkImage('${AppConfig.serverBase}$photoUrl'));
    } else {
      avatar = const CircleAvatar(radius: 24, child: Icon(Icons.person));
    }

    if (unread <= 0) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
            child: Text(
              '$unread',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dtDay = DateTime(dt.year, dt.month, dt.day);
    if (dtDay == today) return DateFormat.Hm().format(dt);
    if (dtDay == today.subtract(const Duration(days: 1))) return 'Jučer';
    return DateFormat('MMM d').format(dt);
  }
}

class _AdminPickerSheet extends StatelessWidget {
  final List<ApplicationUser> admins;
  final ValueChanged<ApplicationUser> onSelected;

  const _AdminPickerSheet({required this.admins, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Odaberite administratora',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...admins.map((a) {
          final name =
              '${a.person?.firstName ?? ''} ${a.person?.lastName ?? ''}'.trim();
          Widget avatar = const CircleAvatar(child: Icon(Icons.person));
          final b64 = a.person?.profilePhotoBytes;
          if (b64 != null && b64.isNotEmpty) {
            try {
              avatar = CircleAvatar(
                  backgroundImage: MemoryImage(base64Decode(b64)));
            } catch (_) {}
          }
          return ListTile(
            leading: avatar,
            title: Text(name.isNotEmpty ? name : (a.userName ?? 'Admin')),
            onTap: () => onSelected(a),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}
