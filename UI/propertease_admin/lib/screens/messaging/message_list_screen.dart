import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/message.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/message_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_core/signalr_core.dart';
import 'package:http/io_client.dart';

class MessageListScreen extends StatefulWidget {
  final int? conversationId;
  int? recipientId;
  final VoidCallback onConversationListUpdated;

  MessageListScreen({
    Key? key,
    this.conversationId,
    this.recipientId,
    required this.onConversationListUpdated,
  }) : super(key: key);

  @override
  State<StatefulWidget> createState() => MessageListScreenState();
}

class MessageListScreenState extends State<MessageListScreen> {
  late TextEditingController _messageController;
  late MessageProvider _messageProvider;
  Message message = Message();
  String? firstName;
  String? lastName;
  String? photoUrl;
  int? roleId;
  int? userId;
  SearchResult<Message>? messages;
  late HubConnection signalR;

  @override
  void initState() {
    super.initState();
    _messageProvider = context.read<MessageProvider>();
    _messageController = TextEditingController();

    initSignalRConnection();
    getUserIdFromSharedPreferences();
    fetchMessages();
  }

  void initSignalRConnection() async {
    try {
      signalR = HubConnectionBuilder()
          .withUrl(
            'https://localhost:7137/hubs/messageHub',
            HttpConnectionOptions(
              client: IOClient(
                  HttpClient()..badCertificateCallback = (x, y, z) => true),
              logging: (level, message) => print(message),
            ),
          )
          .build();

      signalR.on('newMessage', (message) {
        // Handle the received message
        print('Received new message: $message');
        fetchMessages(); // Update UI or handle the new message as needed
      });
      await signalR.start();
    } catch (e) {
      print('Error initializing SignalR: $e');
      // Handle the error appropriately based on your application's requirements.
    }
  }

  void _onNewMessage(List<dynamic>? parameters) async {
    if (parameters != null && parameters.length >= 2) {
      final methodName = parameters[0] as String;
      final message = parameters[1] as String;
      print("MethodName = $methodName, Message = $message");
      await fetchMessages();
    }
  }

  @override
  void dispose() {
    signalR.off('newMessage'); // Unsubscribe from the event
    signalR.stop();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _messageProvider = context.read<MessageProvider>();
    getUserIdFromSharedPreferences();
    fetchMessages();
  }

  Future<void> fetchMessages() async {
    try {
      var tempMessages =
          await _messageProvider.getByConversationId(widget.conversationId!);
      setState(() {
        messages = tempMessages;
      });
    } catch (e) {
      print(e.toString());
    }
  }

  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = int.tryParse(prefs.getString('userId')!)!;
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      photoUrl = prefs.getString('profilePhoto');
      roleId = prefs.getInt('roleId');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.recipientId.toString())),
      body: Column(
        children: [
          Expanded(
            child: messages != null
                ? ListView.builder(
                    itemCount: messages!.result.length,
                    reverse: true,
                    itemBuilder: (context, index) {
                      return buildMessageItem(messages!.result[index]);
                    },
                  )
                : Center(
                    child: CircularProgressIndicator(),
                  ),
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
    try {
      message.content = _messageController.text;
      message.senderId = userId;
      message.recipientId = widget.recipientId;
      message.conversationId = widget.conversationId;
      message.createdAt = DateTime.now();
      message.modifiedAt = DateTime.now();

      await _messageProvider.addMessage(message);
      await fetchMessages();
      _messageController.text = "";

      final jsonString = jsonEncode(message.toJson());

      // Pass the JSON-encoded string in the list of arguments
      await signalR.invoke('SendMessage', args: ['newMessage', jsonString]);
    } catch (e) {
      print(e.toString());
    } finally {
      widget.onConversationListUpdated();
    }
  }

  Widget buildMessageItem(Message message) {
    final isCurrentUserRecipient = message.recipientId == userId;

    return ListTile(
      title: Row(
        mainAxisAlignment: isCurrentUserRecipient
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isCurrentUserRecipient)
            _buildSenderAvatar(message.sender?.person?.profilePhotoBytes),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: isCurrentUserRecipient
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Text(
                "${message.sender?.person?.firstName ?? ''} ${message.sender?.person?.lastName ?? ''}",
              ),
              Text(
                DateFormat.Hm().format(message.createdAt!),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          if (isCurrentUserRecipient)
            _buildSenderAvatar(message.sender?.person?.profilePhotoBytes),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            color: isCurrentUserRecipient
                ? Color.fromARGB(255, 212, 211, 211)
                : Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                message.content!,
                style: TextStyle(
                  fontSize: 20,
                  color: isCurrentUserRecipient ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSenderAvatar(String? profilePhotoBytes) {
    final imageProvider = profilePhotoBytes != null
        ? MemoryImage(base64Decode(profilePhotoBytes))
        : AssetImage("assets/images/user_placeholder.jpg")
            as ImageProvider<Object>;

    return CircleAvatar(
      backgroundImage: imageProvider,
    );
  }
}
