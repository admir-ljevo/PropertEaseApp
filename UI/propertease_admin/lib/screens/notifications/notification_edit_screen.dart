import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:provider/provider.dart';

class NotificationEditScreen extends StatefulWidget {
  final New? notification;

  NotificationEditScreen({required this.notification});

  @override
  _NotificationEditScreenState createState() => _NotificationEditScreenState();
}

class _NotificationEditScreenState extends State<NotificationEditScreen> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  late NotificationProvider _notificationProvider;
  File? selectedImage;
  late String imageUrl;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationProvider = context.read<NotificationProvider>();
    imageUrl = "https://localhost:44340${widget.notification!.image}";
  }

  Future<File> downloadFile(String url, String localPath) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final file = File(localPath);
      await file.writeAsBytes(response.bodyBytes);
      return file;
    } else {
      throw Exception('Failed to download file from the URL');
    }
  }

  @override
  void initState() {
    super.initState();
    textController.text = widget.notification?.text ?? '';
    nameController.text = widget.notification?.name ?? '';
    imageUrl = "https://localhost:44340${widget.notification!.image}";

    _notificationProvider = context.read<NotificationProvider>();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  void saveAndReturn() async {
    if (nameController.text.isEmpty || textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title and Notification Text cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    New updatedNotification = widget.notification!;
    updatedNotification.text = textController.text;
    updatedNotification.name = nameController.text;
    updatedNotification.file = widget.notification!.file;
    updatedNotification.image = widget.notification!.image;

    if (selectedImage != null) {
      updatedNotification.file = selectedImage;
      updatedNotification.image = selectedImage?.path;
    }
    await _notificationProvider.updateNotification(
        updatedNotification, updatedNotification.id!);
    Navigator.pop(context, updatedNotification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit notification screen')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selectedImage == null)
                        Image.network(
                          "https://localhost:44340${widget.notification!.image}",
                          width: 700,
                          height: 400,
                        )
                      else if (selectedImage != null)
                        Image.file(
                          selectedImage!,
                          width: 700,
                          height: 400,
                        ),
                      ElevatedButton(
                        onPressed: _pickImage,
                        child: const Text('Select Image'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      TextFormField(
                        controller: textController,
                        maxLines: null,
                        minLines: 15,
                        keyboardType: TextInputType.multiline,
                        decoration: const InputDecoration(
                          labelText: 'Notification Text',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter notification text';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ],
            ),
            ElevatedButton(
              onPressed: () {
                saveAndReturn();
              },
              child: const Text('Save Notification'),
            ),
          ],
        ),
      ),
    );
  }
}
