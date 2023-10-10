import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:propertease_admin/models/new.dart';

class NotificationEditScreen extends StatefulWidget {
  final New? notification;

  NotificationEditScreen({required this.notification});

  @override
  _NotificationEditScreenState createState() => _NotificationEditScreenState();
}

class _NotificationEditScreenState extends State<NotificationEditScreen> {
  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    textController.text = widget.notification?.text ?? '';
    nameController.text = widget.notification?.name ?? '';
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

  void saveAndReturn() {
    New updatedNotification = widget.notification!;
    updatedNotification.text = textController.text;
    updatedNotification.name = nameController.text;

    // If a new image is selected, update it
    if (selectedImage != null) {
      updatedNotification.file = selectedImage;
      updatedNotification.image = selectedImage?.path;
    }

    // Use Navigator.pop to return the updated notification to the detail screen
    Navigator.pop(context, updatedNotification);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit notification screen')),
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
