import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_client/models/application_user.dart';
import 'package:propertease_client/models/message.dart';
import 'package:propertease_client/models/search_result.dart';
import 'package:propertease_client/config/app_config.dart';
import 'package:propertease_client/providers/message_provider.dart';
import 'package:propertease_client/screens/users/renter_profile_screen.dart';
import 'package:propertease_client/utils/authorization.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart';

class MessageListScreen extends StatefulWidget {
  final int? conversationId;
  final int? recipientId;
  final VoidCallback? onConversationListUpdated;
  final String? chatTitle;
  final String? otherUserPhotoBytes;
  final String? otherUserPhotoUrl;
  final String? myPhotoBytes;
  final ApplicationUser? renter;

  const MessageListScreen({
    Key? key,
    this.conversationId,
    this.recipientId,
    this.onConversationListUpdated,
    this.chatTitle,
    this.otherUserPhotoBytes,
    this.otherUserPhotoUrl,
    this.myPhotoBytes,
    this.renter,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageListScreenState();
}

class MessageListScreenState extends State<MessageListScreen> {
  late TextEditingController _messageController;
  late MessageProvider _messageProvider;
  final ScrollController _scrollController = ScrollController();
  final _imgCache = <String, Uint8List>{};
  Message message = Message();
  String? firstName;
  String? lastName;
  String? photoUrl;
  int? roleId;
  int? userId;
  SearchResult<Message>? messages;
  late HubConnection signalR;

  int _page = 1;
  bool _hasMore = true;
  bool _loadingMore = false;
  static const int _pageSize = 30;

  @override
  void initState() {
    super.initState();
    _messageProvider = context.read<MessageProvider>();
    _messageController = TextEditingController();

    _scrollController.addListener(_onScroll);
    initSignalRConnection();
    _loadUserInfo();
    fetchMessages();
    _markAsReadNow();
  }

  void _markAsReadNow() {
    final uid = Authorization.userId;
    if (uid == null || widget.conversationId == null) return;
    _messageProvider.markAsRead(widget.conversationId!, uid).then((_) {
      widget.onConversationListUpdated?.call();
    }).catchError((_) {});
  }

  void initSignalRConnection() async {
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
        _markAsReadNow();
      });
      signalR.on('messagesRead', (_) => _syncMessages());
      await signalR.start();
    } catch (_) {}
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 120 &&
        !_loadingMore &&
        _hasMore) {
      _loadMoreMessages();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    signalR.off('newMessage');
    signalR.stop();
    _scrollController.dispose();
    super.dispose();
  }

  void _loadUserInfo() {
    userId = Authorization.userId;
    firstName = Authorization.firstName;
    lastName = Authorization.lastName;
  }

  Future<void> fetchMessages() async {
    try {
      final result = await _messageProvider.getByConversationId(
        widget.conversationId!,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        messages = result;
        _page = 1;
        _hasMore = result.result.length >= _pageSize;
      });
      _scrollToBottom();
    } catch (_) {}
  }

  Future<void> _loadMoreMessages() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final nextPage = _page + 1;
      final result = await _messageProvider.getByConversationId(
        widget.conversationId!,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        messages!.result.addAll(result.result);
        _page = nextPage;
        _hasMore = result.result.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _syncMessages() {
    if (_page != 1) return;
    _messageProvider
        .getByConversationId(widget.conversationId!, page: 1, pageSize: _pageSize)
        .then((result) {
      if (mounted) {
        setState(() {
          messages = result;
          _hasMore = result.result.length >= _pageSize;
        });
      }
    }).catchError((_) {});
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: widget.renter != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RenterProfileScreen(renter: widget.renter, renterId: widget.recipientId),
                    ),
                  )
              : null,
          child: Row(
            children: [
              Expanded(child: Text(widget.chatTitle ?? 'Chat')),
              if (widget.renter != null)
                const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messages != null
                ? ListView.builder(
                    controller: _scrollController,
                    itemCount: messages!.result.length + (_loadingMore ? 1 : 0),
                    reverse: true,
                    itemBuilder: (context, index) {
                      if (index == messages!.result.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }
                      return buildMessageItem(messages!.result[index]);
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          buildInputArea(),
        ],
      ),
    );
  }

  Widget buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Type your message...',
              ),
            ),
          ),
          SizedBox(width: 8),
          ElevatedButton(
            style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue)),
            onPressed: () async {
              await sendMessage();
            },
            child: Icon(
              Icons.send,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    if (widget.conversationId == null || widget.conversationId == 0 || userId == null) {
      return;
    }

    final optimistic = Message()
      ..content = content
      ..senderId = userId
      ..recipientId = widget.recipientId
      ..conversationId = widget.conversationId
      ..createdAt = DateTime.now();

    _messageController.clear();
    setState(() {
      messages ??= SearchResult<Message>();
      messages!.result.insert(0, optimistic); // list is reversed
    });
    _scrollToBottom();

    try {
      await _messageProvider.addMessage(optimistic);

      _syncMessages();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        messages?.result.remove(optimistic);
      });
      _messageController.text = content;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to send: $e'),
            backgroundColor: Colors.red),
      );
    }
  }

  Widget buildMessageItem(Message message) {
    final isMine = message.senderId == userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) ...[
            _buildSenderAvatar(widget.otherUserPhotoBytes, photoUrl: widget.otherUserPhotoUrl),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  isMine
                      ? ''
                      : '${message.sender?.person?.firstName ?? ''} ${message.sender?.person?.lastName ?? ''}'.trim(),
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? Colors.blue
                        : const Color.fromARGB(255, 212, 211, 211),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isMine ? 16 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 16),
                    ),
                  ),
                  child: Text(
                    message.content ?? '',
                    style: TextStyle(
                      fontSize: 16,
                      color: isMine ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.createdAt != null
                            ? DateFormat.Hm().format(message.createdAt!)
                            : '',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      if (isMine) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isRead == true ? Icons.done_all : Icons.done,
                          size: 14,
                          color: message.isRead == true
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
            _buildSenderAvatar(widget.myPhotoBytes ?? Authorization.profilePhotoBytes),
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

  Widget _buildSenderAvatar(String? profilePhotoBytes, {String? photoUrl}) {
    final decoded = _cachedBytes(profilePhotoBytes);
    if (decoded != null) {
      return CircleAvatar(backgroundImage: MemoryImage(decoded));
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      return CircleAvatar(backgroundImage: NetworkImage(photoUrl));
    }
    return const CircleAvatar(child: Icon(Icons.person));
  }
}
