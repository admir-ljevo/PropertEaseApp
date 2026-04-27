import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import 'package:provider/provider.dart';

const _kPrimary = Color(0xFF115892);

class NotificationAddScreen extends StatefulWidget {
  const NotificationAddScreen({super.key});

  @override
  State<NotificationAddScreen> createState() => _NotificationAddScreenState();
}

class _NotificationAddScreenState extends State<NotificationAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  File? _selectedImage;
  bool _saving = false;

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final notification = New()
        ..name = _titleController.text.trim()
        ..text = _textController.text.trim()
        ..userId = Authorization.userId
        ..file = _selectedImage
        ..image = _selectedImage?.path;

      await context.read<NotificationProvider>().addNotification(notification);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vijest uspješno dodana!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Nova vijest'),
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImagePicker(),
                  const SizedBox(height: 24),

                  _SectionLabel(label: 'Naslov'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    decoration: _inputDecoration('Unesite naslov vijesti'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Naslov je obavezan' : null,
                  ),
                  const SizedBox(height: 20),

                  _SectionLabel(label: 'Sadržaj'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _textController,
                    minLines: 8,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: _inputDecoration('Unesite tekst vijesti...'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Sadržaj je obavezan' : null,
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _kPrimary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10))),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.save_outlined),
                      label: Text(_saving ? 'Snimanje...' : 'Snimi vijest'),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: _selectedImage != null ? _kPrimary : Colors.grey.shade300,
              width: _selectedImage != null ? 1.5 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: _selectedImage != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(_selectedImage!, fit: BoxFit.cover),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: Colors.black54),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Promijeni sliku'),
                      onPressed: _pickImage,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_outlined,
                      size: 56, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text('Kliknite da odaberete sliku',
                      style: TextStyle(
                          color: Colors.grey.shade500, fontSize: 14)),
                ],
              ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _kPrimary, width: 1.5),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
        label,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _kPrimary,
            letterSpacing: 0.3),
      );
}
