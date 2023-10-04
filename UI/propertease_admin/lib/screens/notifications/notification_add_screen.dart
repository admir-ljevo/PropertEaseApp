import 'package:flutter/material.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class NotificationAddScreen extends StatefulWidget {
  const NotificationAddScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => NotificationAddScreenState();
}

class NotificationAddScreenState extends State<NotificationAddScreen> {
  late NotificationProvider _notificationProvider;
  New? notification = New();
  File? selectedImage = File('assets/images/house_placeholder.jpg');

  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationProvider = context.read<NotificationProvider>();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
        notification?.file = selectedImage;
      });
    }
  }

  Future addNotification() async {
    if (_formKey.currentState!.validate()) {
      notification?.createdAt = DateTime.now();
      notification?.file = selectedImage;
      notification?.text = textController.text;
      notification?.name = nameController.text;
      notification?.image = notification?.file?.path;

      await _notificationProvider.addNotification(notification!);

      // Show a success message using a SnackBar
      showSuccessSnackBar();
    }
  }

  // Method to show a SnackBar for success message
  void showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Notification added successfully!'),
        duration: Duration(seconds: 2), // Adjust the duration as needed
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add notification screen')),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(
                height: 30,
              ),
              // Row containing image picker and text area
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.center, // Center the content horizontally
                children: [
                  // Image Picker Column
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment
                          .center, // Center the content vertically
                      children: [
                        if (selectedImage != null)
                          Image.file(
                            selectedImage!,
                            width: 700,
                            height: 400,
                          )
                        else
                          Image.asset(
                            'assets/images/house_placeholder.jpg',
                            height: 400,
                            width: 700,
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
                        // TextFormField for Title
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
                        const SizedBox(
                          height: 30,
                        ),
                        // TextField for Notification Text
                        TextFormField(
                          controller: textController,
                          maxLines: null, // Allow multiple lines of text
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
                        const SizedBox(
                          height: 30,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Save Button
              ElevatedButton(
                onPressed: () async {
                  await addNotification();
                },
                child: const Text('Save Notification'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
