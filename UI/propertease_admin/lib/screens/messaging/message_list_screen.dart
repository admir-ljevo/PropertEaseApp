import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/message.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/conversation_provider.dart';
import 'package:propertease_admin/providers/message_provider.dart';
import 'package:propertease_admin/screens/users/user_profile_screen.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart';

class MessageListScreen extends StatefulWidget {
  final int? conversationId;
  final int? recipientId;
  final String? recipientName;
  final String? recipientPhotoBytes;
  final String? recipientPhotoUrl;
  final VoidCallback onConversationListUpdated;

  const MessageListScreen({
    Key? key,
    this.conversationId,
    this.recipientId,
    this.recipientName,
    this.recipientPhotoBytes,
    this.recipientPhotoUrl,
    required this.onConversationListUpdated,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageListScreenState();
}

class MessageListScreenState extends State<MessageListScreen> {
  late TextEditingController _messageController;
  late MessageProvider _messageProvider;
  late ConversationProvider _conversationProvider;
  final ScrollController _scrollController = ScrollController();
  final _imgCache = <String, Uint8List>{};

  Message message = Message();
  String? firstName;
  String? lastName;
  int? userId;
  SearchResult<Message>? messages;
  late HubConnection signalR;

  @override
  void initState() {
    super.initState();
    _messageProvider = context.read<MessageProvider>();
    _conversationProvider = context.read<ConversationProvider>();
    _messageController = TextEditingController();
    _initSignalR();
    _loadUser();
    _fetchMessages();
    _markAsReadSilent();
  }

  void _initSignalR() async {
    try {
      signalR = HubConnectionBuilder()
          .withUrl(
            '${AppConfig.serverBase}/hubs/messageHub',
            HttpConnectionOptions(
              accessTokenFactory: () async => Authorization.token ?? '',
              logging: (level, message) {},
            ),
          )
          .withAutomaticReconnect()
          .build();

      signalR.on('newMessage', (_) {
        _syncMessages();
        _markAsReadSilent();
      });
      signalR.on('messagesRead', (_) => _syncMessages());
      await signalR.start();
    } catch (e) {
      debugPrint('SignalR init error: $e');
    }
  }

  @override
  void dispose() {
    signalR.off('newMessage');
    signalR.stop();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider = context.read<MessageProvider>();
  }

  void _loadUser() {
    userId = Authorization.userId;
    firstName = Authorization.firstName;
    lastName = Authorization.lastName;
  }

  Future<void> _fetchMessages() async {
    try {
      final result =
          await _messageProvider.getByConversationId(widget.conversationId!);
      if (mounted) setState(() => messages = result);
    } catch (e) {
      debugPrint('Fetch messages error: $e');
    }
  }

  void _syncMessages() {
    _messageProvider
        .getByConversationId(widget.conversationId!)
        .then((result) {
      if (mounted) setState(() => messages = result);
    }).catchError((Object e) {
      debugPrint('Sync error: $e');
    });
  }

  void _markAsReadSilent() {
    if (userId == null) return;
    _conversationProvider
        .markAsRead(widget.conversationId!, userId!)
        .then((_) => widget.onConversationListUpdated())
        .catchError((Object _) {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final optimistic = Message()
      ..content = text
      ..senderId = userId
      ..recipientId = widget.recipientId
      ..conversationId = widget.conversationId
      ..createdAt = DateTime.now()
      ..modifiedAt = DateTime.now();

    _messageController.clear();
    setState(() {
      messages ??= SearchResult<Message>();
      messages!.result.insert(0, optimistic);
    });
    _scrollToBottom();

    try {
      await _messageProvider.addMessage(optimistic);
      _syncMessages();
      widget.onConversationListUpdated();
    } catch (e) {
      debugPrint('Send message error: $e');
      if (mounted) {
        setState(() => messages?.result.remove(optimistic));
        _messageController.text = text;
      }
    }
  }

  String get _headerTitle {
    if (widget.recipientName != null && widget.recipientName!.isNotEmpty) {
      return widget.recipientName!;
    }
    return 'Razgovor';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: widget.recipientId != null
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: widget.recipientId)))
              : null,
          child: Row(
            children: [
              _buildAvatar(widget.recipientPhotoBytes, photoUrl: widget.recipientPhotoUrl),
              const SizedBox(width: 10),
              Text(
                _headerTitle,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
              if (widget.recipientId != null)
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: Icon(Icons.chevron_right, size: 16),
                ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    if (messages == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (messages!.result.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline, size: 48, color: Colors.black26),
            SizedBox(height: 12),
            Text('Nema poruka', style: TextStyle(color: Colors.black38)),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: messages!.result.length,
      itemBuilder: (_, i) => _buildMessageBubble(messages!.result[i]),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final isMine = msg.senderId == userId;
    final time = msg.createdAt != null
        ? DateFormat.Hm().format(msg.createdAt!)
        : '';
    final senderName =
        '${msg.sender?.person?.firstName ?? ''} ${msg.sender?.person?.lastName ?? ''}'.trim();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildAvatar(widget.recipientPhotoBytes, photoUrl: widget.recipientPhotoUrl),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMine && senderName.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2, left: 4),
                    child: Text(
                      senderName,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.65,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.blue
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    msg.content ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(time,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.black38)),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          msg.isRead == true
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: msg.isRead == true
                              ? Colors.blue
                              : Colors.black38,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isMine) ...[
            const SizedBox(width: 8),
            _buildMyAvatar(),
          ],
        ],
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

  Widget _buildAvatar(String? profilePhotoBytes, {String? photoUrl}) {
    final decoded = _cachedBytes(profilePhotoBytes);
    if (decoded != null) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: MemoryImage(decoded),
      );
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage('${AppConfig.serverBase}$photoUrl'),
      );
    }
    return const CircleAvatar(
      radius: 16,
      child: Icon(Icons.person, size: 16),
    );
  }

  Widget _buildMyAvatar() {
    if (Authorization.profilePhotoBytes != null &&
        Authorization.profilePhotoBytes!.isNotEmpty) {
      return _buildAvatar(Authorization.profilePhotoBytes);
    }
    final photoPath = Authorization.profilePhoto;
    if (photoPath != null && photoPath.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage('${AppConfig.serverBase}$photoPath'),
      );
    }
    return const CircleAvatar(
      radius: 16,
      child: Icon(Icons.person, size: 16),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              minLines: 1,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Napišite poruku...',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Colors.blue),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: Colors.blue,
            borderRadius: BorderRadius.circular(24),
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: _sendMessage,
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
