import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/io_client.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/conversation.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/conversation_provider.dart';
import 'package:propertease_admin/screens/messaging/message_list_screen.dart';
import 'package:provider/provider.dart';
import 'package:signalr_core/signalr_core.dart' as signalr;

class ConversationListScreen extends StatefulWidget {
  int? renterId;
  ConversationListScreen({super.key, this.renterId});

  @override
  State<StatefulWidget> createState() => ConvesrationListScreenState();
}

class ConvesrationListScreenState extends State<ConversationListScreen> {
  late ConversationProvider _conversationProvider;
  late Future<SearchResult<Conversation>> conversationsFuture;
  late signalr.HubConnection signalR;

  void initSignalRConnection() async {
    try {
      signalR = signalr.HubConnectionBuilder()
          .withUrl(
            'https://localhost:7137/hubs/messageHub',
            signalr.HttpConnectionOptions(
              client: IOClient(
                HttpClient()..badCertificateCallback = (x, y, z) => true,
              ),
              logging: (level, message) => print(message),
            ),
          )
          .build();

      signalR.on('newMessage', (message) {
        // Handle the received message
        print('Received new message: $message');
        refreshConversations(); // Update UI or handle the new message as needed
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
      refreshConversations();
    }
  }

  @override
  void dispose() {
    signalR.off('newMessage'); // Unsubscribe from the event
    signalR.stop();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _conversationProvider = context.read<ConversationProvider>();
    conversationsFuture = fetchConversations();
    initSignalRConnection();
  }

  Future<SearchResult<Conversation>> fetchConversations() async {
    try {
      var tempConversations = await _conversationProvider
          .getByPropertyAndRenter(null, widget.renterId!);
      print('Fetched Conversations: ${tempConversations}');
      return tempConversations;
    } catch (e) {
      print(e.toString());
      throw e;
    }
  }

  void refreshConversations() {
    setState(() {
      conversationsFuture = fetchConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Conversations"),
      ),
      body: FutureBuilder(
        future: conversationsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.result.isEmpty) {
            return Center(child: Text("No conversations available."));
          } else {
            var conversations = snapshot.data!.result;
            return ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                return buildConversationItem(conversations[index]);
              },
            );
          }
        },
      ),
    );
  }

  Widget buildConversationItem(Conversation conversation) {
    Widget leadingWidget =
        conversation.client!.person!.profilePhotoBytes != null
            ? Image.memory(
                base64Decode(conversation.client!.person!.profilePhotoBytes!),
                width: 150,
                height: 150,
              )
            : Image.asset(
                'assets/images/user_placeholder.jpg',
                width: 80,
                height: 80,
              );

    return ListTile(
      leading: leadingWidget,
      title: Text(
          "Client: ${conversation.client?.person?.firstName} ${conversation.client?.person?.lastName}"),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Property: ${conversation.property?.name ?? "N/A"}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          if (conversation.lastMessage != null) Text("Last message: "),
          if (conversation.lastMessage != null)
            Text(
              conversation.lastMessage!.length > 30
                  ? '${conversation.lastMessage!.substring(0, 30)}...'
                  : conversation.lastMessage!,
            ),
          SizedBox(height: 4),
          Text(
            'Created: ${formattedLastSent(conversation.lastSent)}',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MessageListScreen(
              conversationId: conversation.id,
              recipientId: conversation.clientId,
              onConversationListUpdated: refreshConversations,
            ),
          ),
        );
      },
    );
  }

  String formattedLastSent(DateTime? lastSent) {
    return lastSent != null
        ? DateFormat('MMM d, yyyy h:mm a').format(lastSent)
        : 'N/A';
  }
}
