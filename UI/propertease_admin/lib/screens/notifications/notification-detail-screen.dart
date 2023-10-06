import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/screens/notifications/notification_edit_screen.dart';
import 'package:propertease_admin/widgets/master_screen.dart';

class NotificationDetailScreen extends StatefulWidget {
  New? notification;
  NotificationDetailScreen({super.key, this.notification});

  @override
  State<StatefulWidget> createState() => NotificationDetailScreenState();
}

class NotificationDetailScreenState extends State<NotificationDetailScreen> {
  final TextEditingController _contentController = TextEditingController();
  void _navigateToEditScreen(BuildContext context, New notification) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return NotificationEditScreen(notification: notification);
    })).then((updatedNotification) {
      // Handle the returned updated notification here
      if (updatedNotification != null) {
        // Update the UI with the updated notification data
        setState(() {
          notification = updatedNotification;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('News details'),
        actions: <Widget>[
          // Add an "Edit" button to the AppBar
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NotificationEditScreen(
                        notification: widget.notification,
                      ),
                    ),
                  );
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
                      maxWidth: 600, // Replace with your desired maxWidth
                      maxHeight: double
                          .infinity, // Replace with your desired maxHeight
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
                    'https://localhost:44340/${widget.notification?.image}',
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
                      const SizedBox(
                          width: 8), // Add spacing between the icon and text
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
                      const SizedBox(
                          width: 8), // Add spacing between the icon and text
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
                  enabled: false, // Make the text area disabled
                  decoration: const InputDecoration(
                    labelText: 'News content',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 10,
                  maxLines: null, // Allow multiple lines of text
                  keyboardType: TextInputType.multiline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    _contentController.text = widget.notification?.text ?? '';
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _contentController.text = widget.notification?.text ?? '';
  }
}
