import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:propertease_admin/config/app_config.dart';
import 'package:propertease_admin/models/new.dart';
import 'package:propertease_admin/providers/notification_provider.dart';
import 'package:provider/provider.dart';

const _kPrimary = Color(0xFF115892);

class NotificationEditScreen extends StatefulWidget {
  final New? notification;
  const NotificationEditScreen({super.key, required this.notification});

  @override
  State<NotificationEditScreen> createState() => _NotificationEditScreenState();
}

class _NotificationEditScreenState extends State<NotificationEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  File? _selectedImage;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.notification?.name ?? '');
    _textController =
        TextEditingController(text: widget.notification?.text ?? '');
  }

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
      final updated = widget.notification!
        ..name = _titleController.text.trim()
        ..text = _textController.text.trim();

      if (_selectedImage != null) {
        updated.file = _selectedImage;
        updated.image = _selectedImage!.path;
      }

      await context
          .read<NotificationProvider>()
          .updateNotification(updated, updated.id!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vijest uspješno ažurirana!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(updated);
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
        title: const Text('Uredi vijest'),
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
                      label: Text(_saving ? 'Snimanje...' : 'Snimi izmjene'),
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
    final existingUrl = widget.notification?.image != null &&
            widget.notification!.image!.isNotEmpty
        ? '${AppConfig.serverBase}/${widget.notification!.image}'
        : null;

    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (_selectedImage != null)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else if (existingUrl != null)
              Image.network(existingUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _placeholder())
            else
              _placeholder(),
            Positioned(
              bottom: 12,
              right: 12,
              child: FilledButton.icon(
                style:
                    FilledButton.styleFrom(backgroundColor: Colors.black54),
                icon: const Icon(Icons.edit, size: 16),
                label: const Text('Promijeni sliku'),
                onPressed: _pickImage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey.shade100,
        child: const Center(
            child: Icon(Icons.newspaper, size: 56, color: Colors.grey)),
      );

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
