import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/screens/notifications/notification_edit_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationDetailScreen extends StatefulWidget {
  New? notification;

  NotificationDetailScreen({required this.notification});

  @override
  _NotificationDetailScreenState createState() =>
      _NotificationDetailScreenState();
}

class _NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final TextEditingController _contentController = TextEditingController();
  String? firstName;
  String? lastName;
  String photoUrl = 'https://localhost:7137';
  int? roleId;
  Future<void> getUserIdFromSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      firstName = prefs.getString('firstName');
      lastName = prefs.getString('lastName');
      photoUrl = 'https://localhost:7137${prefs.getString('profilePhoto')}';
      roleId = prefs.getInt('roleId')!;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    getUserIdFromSharedPreferences();
    _contentController.text = widget.notification?.text ?? '';
  }

  void _navigateToEditScreen(BuildContext context) async {
    final updatedNotification = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NotificationEditScreen(
          notification: widget.notification,
        ),
      ),
    );

    if (updatedNotification != null) {
      setState(() {
        widget.notification = updatedNotification;
        _contentController.text = widget.notification!.text!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News details'),
        actions: <Widget>[
          if (roleId == 1)
            Row(
              children: [
                const Text(
                  "Edit notification",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    _navigateToEditScreen(context);
                  },
                ),
              ],
            ),
          const SizedBox(
            width: 50,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 113, 165),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 300,
                      maxWidth: 600,
                      maxHeight: double.infinity,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Center(
                        child: Text(
                          widget.notification?.name ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Roboto',
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Container(
                height: 500,
                width: 1000,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(10.0),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(10.0),
                  ),
                  child: Image.network(
                    'https://localhost:7137/${widget.notification?.image}',
                    fit: BoxFit.cover,
                    height: 170,
                    width: 250,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 50,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.green,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Created at: ${DateFormat('yyyy-MM-dd HH:mm').format(widget.notification?.createdAt ?? DateTime.now())}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(15),
                  color: Colors.green,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Author: ${widget.notification?.user?.person?.firstName} ${widget.notification?.user?.person?.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Container(
              width: 1060,
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: TextField(
                  style: const TextStyle(color: Colors.black),
                  controller: _contentController,
                  enabled: false,
                  decoration: const InputDecoration(
                    labelText: 'News content',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 10,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
