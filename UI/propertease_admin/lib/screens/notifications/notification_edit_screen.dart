import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:provider/provider.dart';

import '../../providers/notification_provider.dart';

class NotificationEditScreen extends StatefulWidget {
  New? notification;
  NotificationEditScreen({super.key, this.notification});

  @override
  State<StatefulWidget> createState() => NotificationEditScreenState();
}

class NotificationEditScreenState extends State<NotificationEditScreen> {
  late NotificationProvider _notificationProvider;
  New? notification;
  File? selectedImage;

  final TextEditingController textController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    textController.text = widget.notification?.text ?? '';
    nameController.text = widget.notification?.name ?? '';
    notification = widget.notification!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _notificationProvider = context.read<NotificationProvider>();
    notification = widget.notification!;
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

  Future updateNotification() async {
    if (_formKey.currentState!.validate()) {
      notification?.file = selectedImage;
      notification?.text = textController.text;
      notification?.name = nameController.text;
      notification?.image = notification?.file?.path;
      print(notification?.file?.path);
      await _notificationProvider.updateNotification(
          notification!, notification!.id!);

      showSuccessSnackBar();
    }
  }

  // Method to show a SnackBar for success message
  void showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: Colors.green,
        content: Text('Notification updated successfully!'),
        duration: Duration(seconds: 2), // Adjust the duration as needed
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit notification screen')),
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
                  await updateNotification();
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
