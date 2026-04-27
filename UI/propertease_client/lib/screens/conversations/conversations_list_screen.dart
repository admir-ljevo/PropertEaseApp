import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/models/conversation.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/providers/conversation_provider.dart';
import 'package:propertease_client/screens/conversations/messaging_screen.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:propertease_client/widgets/master_screen.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart' as signalr;

class ConversationListScreen extends StatefulWidget {
  final int? clientId;
  const ConversationListScreen({super.key, this.clientId});

  @override
  State<StatefulWidget> createState() => ConvesrationListScreenState();
}

class ConvesrationListScreenState extends State<ConversationListScreen> {
  late ConversationProvider _conversationProvider;
  List<Conversation> _conversations = [];
  bool _isLoading = true;
  String? _error;
  late signalr.HubConnection signalR;
  final _imgCache = <String, Uint8List>{};

  int get _totalUnread =>
      _conversations.fold(0, (sum, c) => sum + (c.unreadCount ?? 0));

  void initSignalRConnection() async {
    final token = Authorization.token;
    if (token == null) return;
    try {
      signalR = signalr.HubConnectionBuilder()
          .withUrl(
            '${AppConfig.serverBase}/hubs/messageHub',
            signalr.HttpConnectionOptions(
              accessTokenFactory: () async => Authorization.token ?? token,
              logging: (level, message) {},
            ),
          )
          .withAutomaticReconnect()
          .build();

      signalR.on('newMessage', (_) => refreshConversations());
      await signalR.start();
    } catch (_) {}
  }

  @override
  void dispose() {
    signalR.off('newMessage');
    signalR.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _conversationProvider = context.read<ConversationProvider>();
    _fetchConversations();
    initSignalRConnection();
  }

  Future<void> _fetchConversations() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result =
          await _conversationProvider.getByClient(widget.clientId!);
      if (mounted) {
        setState(() {
          _conversations = result.result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void refreshConversations() {
    _fetchConversations();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      body = Center(child: Text('Greška: $_error'));
    } else if (_conversations.isEmpty) {
      body = const Center(child: Text('Nema razgovora.'));
    } else {
      body = RefreshIndicator(
        onRefresh: _fetchConversations,
        child: ListView.builder(
          itemCount: _conversations.length,
          itemBuilder: (context, index) =>
              buildConversationItem(_conversations[index]),
        ),
      );
    }

    return MasterScreenWidget(
      currentIndex: 3,
      title: 'Inbox',
      inboxUnreadCount: _totalUnread,
      child: body,
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

  Widget _buildRenterAvatar(String? photoBytes, {String? photoUrl}) {
    final decoded = _cachedBytes(photoBytes);
    if (decoded != null) {
      return ClipOval(
        child: Image.memory(
          decoded,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const CircleAvatar(radius: 30, child: Icon(Icons.person)),
        ),
      );
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          photoUrl,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              const CircleAvatar(radius: 30, child: Icon(Icons.person)),
        ),
      );
    }
    return const CircleAvatar(radius: 30, child: Icon(Icons.person));
  }

  Widget buildConversationItem(Conversation conversation) {
    final renterPhotoPath = conversation.renter?.person?.profilePhoto;
    final renterPhotoUrl = (renterPhotoPath != null && renterPhotoPath.isNotEmpty)
        ? '${AppConfig.serverBase}$renterPhotoPath'
        : null;
    final Widget avatarWidget = _buildRenterAvatar(
        conversation.renter?.person?.profilePhotoBytes,
        photoUrl: renterPhotoUrl);
    final unread = conversation.unreadCount ?? 0;
    final Widget leadingWidget = unread > 0
        ? Badge(label: Text('$unread'), child: avatarWidget)
        : avatarWidget;

    return ListTile(
      leading: leadingWidget,
      title: Row(
        children: [
          Expanded(
            child: Text(
              conversation.renter?.userName ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (conversation.property?.name != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                conversation.property!.name!,
                style: TextStyle(fontSize: 12, color: Colors.blue.shade800),
                overflow: TextOverflow.ellipsis,
              ),
            ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (conversation.property?.address != null)
            Text(
              conversation.property!.address!,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!.length > 40
                  ? '${conversation.lastMessage!.substring(0, 40)}...'
                  : conversation.lastMessage!,
            ),
          Text(
            formattedLastSent(conversation.lastSent),
            style: const TextStyle(color: Colors.grey, fontSize: 11),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => MessageListScreen(
                  conversationId: conversation.id,
                  recipientId: conversation.renterId,
                  onConversationListUpdated: refreshConversations,
                  chatTitle: conversation.property?.name ?? 'Chat',
                  otherUserPhotoBytes: conversation.renter?.person?.profilePhotoBytes,
                  otherUserPhotoUrl: renterPhotoUrl,
                  myPhotoBytes: Authorization.profilePhotoBytes,
                  renter: conversation.renter,
                ),
              ),
            )
            .then((_) => refreshConversations());
      },
    );
  }

  String formattedLastSent(DateTime? lastSent) {
    return lastSent != null
        ? DateFormat('MMM d, yyyy h:mm a').format(lastSent)
        : 'N/A';
  }
}
