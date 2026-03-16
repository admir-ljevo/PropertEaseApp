import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:propertease_admin/models/property_type.dart';
import 'package:propertease_admin/models/search_result.dart';
import 'package:propertease_admin/providers/property_type_provider.dart';
import 'package:provider/provider.dart';
import 'package:propertease_admin/providers/image_provider.dart';
import 'package:propertease_admin/utils/authorization.dart';
import '../../models/photo.dart';
import '../../models/property.dart';
import '../../providers/property_provider.dart';
import '../../widgets/country_city_selector.dart';
import 'package:image_picker/image_picker.dart';

class PropertyAddScreen extends StatefulWidget {
  const PropertyAddScreen({super.key});

  @override
  State<PropertyAddScreen> createState() => _PropertyAddScreenState();
}

class _PropertyAddScreenState extends State<PropertyAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _priceController = TextEditingController();
  final _squareMetersController = TextEditingController();
  final _gardenSizeController = TextEditingController();
  final _descriptionController = TextEditingController();

  LatLng? _pickedLocation;

  // Pending images – collected before the property is created
  final List<File> _pendingImages = [];
  int _currentPage = 0;

  SearchResult<PropertyType>? _propertyTypeResult;

  final Property _property = Property();
  late PropertyTypeProvider _propertyTypeProvider;
  late PropertyProvider _propertyProvider;
  late PhotoProvider _photoProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _propertyTypeProvider = context.read<PropertyTypeProvider>();
    _propertyProvider = context.read<PropertyProvider>();
    _photoProvider = context.read<PhotoProvider>();
    _initForm();
  }

  Future<void> _initForm() async {
    final ptResult = await _propertyTypeProvider.get();
    if (mounted) {
      setState(() {
        _propertyTypeResult = ptResult;
      });
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    setState(() {
      _pendingImages.add(File(pickedFile.path));
      _currentPage = _pendingImages.length - 1;
    });
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    final parsedPrice = double.tryParse(_priceController.text);
    _property.name = _nameController.text;
    _property.address = _addressController.text;
    _property.squareMeters = int.tryParse(_squareMetersController.text);
    _property.gardenSize = int.tryParse(_gardenSizeController.text);
    _property.description = _descriptionController.text;
    _property.applicationUserId = Authorization.userId;
    _property.createdAt = DateTime.now();

    if (_property.isDaily == true) {
      _property.dailyPrice = parsedPrice;
      _property.monthlyPrice = 0;
    } else if (_property.isMonthly == true) {
      _property.monthlyPrice = parsedPrice;
      _property.dailyPrice = 0;
    }

    // Ensure capacity is at least 1 (dropdown visually defaults to 1 but
    // the model stays 0 until the user interacts with it)
    if ((_property.capacity ?? 0) == 0) _property.capacity = 1;

    // Create the property first to get its ID
    final created = await _propertyProvider.addAsync(_property);

    // Now upload all pending images using the real property ID
    for (final file in _pendingImages) {
      final photo = Photo(0, 'a', created.id, file);
      photo.file = file;
      await _photoProvider.addPhoto(photo);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nekretnina uspješno dodana'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _priceController.dispose();
    _squareMetersController.dispose();
    _gardenSizeController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nova nekretnina'),
        actions: [
          TextButton.icon(
            onPressed: _saveProperty,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Spremi', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildImageSection()),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Lokacija'),
                        const SizedBox(height: 12),
                        _buildMapPicker(),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Osnovne informacije'),
              const SizedBox(height: 12),
              _buildBasicFields(),
              const SizedBox(height: 24),
              _buildSectionTitle('Veličina i kapacitet'),
              const SizedBox(height: 12),
              _buildSizeFields(),
              const SizedBox(height: 24),
              _buildSectionTitle('Cijena i tip najma'),
              const SizedBox(height: 12),
              _buildPricingFields(),
              const SizedBox(height: 24),
              _buildSectionTitle('Sadržaj'),
              const SizedBox(height: 12),
              _buildAmenitiesGrid(),
              const SizedBox(height: 24),
              _buildSectionTitle('Opis'),
              const SizedBox(height: 12),
              _buildDescriptionField(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _saveProperty,
                  icon: const Icon(Icons.add_home),
                  label: const Text('Dodaj nekretninu'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Slike'),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                MouseRegion(
                  cursor: _pendingImages.isEmpty
                      ? SystemMouseCursors.basic
                      : SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _pendingImages.isEmpty
                        ? null
                        : () => _openFullscreen(_currentPage),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: SizedBox.expand(
                        key: ValueKey(
                            _pendingImages.isEmpty ? -1 : _currentPage),
                        child: _pendingImages.isEmpty
                            ? Image.asset(
                                'assets/images/house_placeholder.jpg',
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _pendingImages[_currentPage],
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ),
                if (_pendingImages.length > 1) ...[
                  Positioned(
                    left: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _navButton(
                        icon: Icons.chevron_left,
                        onPressed: _currentPage > 0
                            ? () => setState(() => _currentPage--)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 0,
                    bottom: 0,
                    child: Center(
                      child: _navButton(
                        icon: Icons.chevron_right,
                        onPressed: _currentPage < _pendingImages.length - 1
                            ? () => setState(() => _currentPage++)
                            : null,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 80,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${_pendingImages.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
                Positioned(
                  top: 8,
                  right: 8,
                  child: _addImageButton(),
                ),
              ],
            ),
          ),
        ),
        if (_pendingImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Center(
              child: Text(
                'Slike će biti uploadane nakon što se nekretnina spremi',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
          ),
      ],
    );
  }

  void _openFullscreen(int startIndex) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _FileFullscreenViewer(
          images: _pendingImages, initialIndex: startIndex),
    );
  }

  Widget _navButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.black38,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }

  Widget _addImageButton() {
    return ElevatedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.add_photo_alternate, size: 18),
      label: const Text('Dodaj sliku'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildBasicFields() {
    return Column(
      children: [
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Naziv nekretnine',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Obavezno polje' : null,
        ),
        const SizedBox(height: 12),
        CountryCitySelector(
          onCityChanged: (c) => setState(() {
            _property.city = c;
            _property.cityId = c?.id;
          }),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Adresa',
            prefixIcon: Icon(Icons.place),
            border: OutlineInputBorder(),
          ),
          validator: (v) => (v == null || v.isEmpty) ? 'Obavezno polje' : null,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<PropertyType?>(
          value: _property.propertyType,
          decoration: const InputDecoration(
            labelText: 'Tip nekretnine',
            prefixIcon: Icon(Icons.category),
            border: OutlineInputBorder(),
          ),
          items: (_propertyTypeResult?.result ?? []).map((pt) {
            return DropdownMenuItem<PropertyType?>(
              value: pt,
              child: Text(pt.name ?? 'Nedefinirano'),
            );
          }).toList(),
          onChanged: (val) => setState(() {
            _property.propertyType = val;
            _property.propertyTypeId = val?.id;
          }),
          validator: (val) => val == null ? 'Odaberite tip nekretnine' : null,
        ),
      ],
    );
  }

  Widget _buildSizeFields() {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            controller: _squareMetersController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Površina (m²)',
              prefixIcon: Icon(Icons.square_foot),
              border: OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Obavezno polje' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _gardenSizeController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Dvorište (m²)',
              prefixIcon: Icon(Icons.grass),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: (_property.numberOfRooms ?? 0) > 0 ? _property.numberOfRooms : 1,
            decoration: const InputDecoration(
              labelText: 'Sobe',
              prefixIcon: Icon(Icons.bed),
              border: OutlineInputBorder(),
            ),
            items: List.generate(9, (i) => i + 1).map((v) {
              return DropdownMenuItem(value: v, child: Text('$v'));
            }).toList(),
            onChanged: (val) => setState(() => _property.numberOfRooms = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: (_property.numberOfBathrooms ?? 0) > 0 ? _property.numberOfBathrooms : 1,
            decoration: const InputDecoration(
              labelText: 'Kupatila',
              prefixIcon: Icon(Icons.bathtub),
              border: OutlineInputBorder(),
            ),
            items: List.generate(9, (i) => i + 1).map((v) {
              return DropdownMenuItem(value: v, child: Text('$v'));
            }).toList(),
            onChanged: (val) => setState(() => _property.numberOfBathrooms = val),
          ),
        ),
      ],
    );
  }

  Widget _buildPricingFields() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: _property.isMonthly == true
                ? 'Monthly'
                : _property.isDaily == true
                    ? 'Daily'
                    : null,
            decoration: const InputDecoration(
              labelText: 'Tip najma',
              prefixIcon: Icon(Icons.schedule),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Monthly', child: Text('Mjesečno')),
              DropdownMenuItem(value: 'Daily', child: Text('Dnevno')),
            ],
            onChanged: (val) => setState(() {
              _property.isMonthly = val == 'Monthly';
              _property.isDaily = val == 'Daily';
              _priceController.clear();
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _priceController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: _property.isMonthly == true
                  ? 'Cijena (KM/mj.)'
                  : _property.isDaily == true
                      ? 'Cijena (KM/dan)'
                      : 'Cijena (KM)',
              prefixIcon: const Icon(Icons.attach_money),
              border: const OutlineInputBorder(),
            ),
            validator: (v) => (v == null || v.isEmpty) ? 'Obavezno polje' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: (_property.capacity ?? 0) > 0 ? _property.capacity : 1,
            decoration: const InputDecoration(
              labelText: 'Max osoba',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
            ),
            items: List.generate(9, (i) => i + 1).map((v) {
              return DropdownMenuItem(value: v, child: Text('$v'));
            }).toList(),
            onChanged: (val) => setState(() => _property.capacity = val),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: DropdownButtonFormField<int>(
            value: _property.parkingSize ?? 0,
            decoration: const InputDecoration(
              labelText: 'Parking mjesta',
              prefixIcon: Icon(Icons.local_parking),
              border: OutlineInputBorder(),
            ),
            items: List.generate(10, (i) => i).map((v) {
              return DropdownMenuItem(value: v, child: Text('$v'));
            }).toList(),
            onChanged: (val) => setState(() => _property.parkingSize = val),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    final amenities = [
      _AmenityToggle('Namješteno', Icons.chair, _property.isFurnished, (v) => setState(() => _property.isFurnished = v)),
      _AmenityToggle('Klima uređaj', Icons.ac_unit, _property.hasAirCondition, (v) => setState(() => _property.hasAirCondition = v)),
      _AmenityToggle('Wi-Fi', Icons.wifi, _property.hasWiFi, (v) => setState(() => _property.hasWiFi = v)),
      _AmenityToggle('Centralno grijanje', Icons.thermostat, _property.hasOwnHeatingSystem, (v) => setState(() => _property.hasOwnHeatingSystem = v)),
      _AmenityToggle('Bazen', Icons.pool, _property.hasPool, (v) => setState(() => _property.hasPool = v)),
      _AmenityToggle('Balkon', Icons.balcony, _property.hasBalcony, (v) => setState(() => _property.hasBalcony = v)),
      _AmenityToggle('Alarm', Icons.alarm, _property.hasAlarm, (v) => setState(() => _property.hasAlarm = v)),
      _AmenityToggle('Video nadzor', Icons.videocam, _property.hasSurveilance, (v) => setState(() => _property.hasSurveilance = v)),
      _AmenityToggle('TV', Icons.tv, _property.hasTV, (v) => setState(() => _property.hasTV = v)),
      _AmenityToggle('Kablovska', Icons.cable, _property.hasCableTV, (v) => setState(() => _property.hasCableTV = v)),
      _AmenityToggle('Parking', Icons.local_parking, _property.hasParking, (v) => setState(() => _property.hasParking = v)),
      _AmenityToggle('Garaža', Icons.garage, _property.hasGarage, (v) => setState(() => _property.hasGarage = v)),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: amenities.map((a) => SizedBox(
        width: 200,
        child: CheckboxListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Row(
            children: [
              Icon(a.icon, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(a.label, style: const TextStyle(fontSize: 14)),
            ],
          ),
          value: a.value ?? false,
          onChanged: (v) => a.onChanged(v ?? false),
          controlAffinity: ListTileControlAffinity.leading,
        ),
      )).toList(),
    );
  }

  Widget _buildMapPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 300,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                center: _pickedLocation ?? LatLng(44.0, 17.5),
                zoom: _pickedLocation != null ? 13.0 : 7.0,
                onTap: (tapPosition, point) {
                  setState(() {
                    _pickedLocation = point;
                    _property.latitude = point.latitude;
                    _property.longitude = point.longitude;
                  });
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.propertease.admin',
                ),
                if (_pickedLocation != null)
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: _pickedLocation!,
                        width: 40,
                        height: 40,
                        builder: (ctx) => const Icon(
                          Icons.location_pin,
                          color: Colors.red,
                          size: 40,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _pickedLocation != null
              ? 'Lat: ${_pickedLocation!.latitude.toStringAsFixed(5)}, Lng: ${_pickedLocation!.longitude.toStringAsFixed(5)}'
              : 'Tapnite na mapu da odaberete lokaciju',
          style: TextStyle(
            fontSize: 12,
            color: _pickedLocation != null ? Colors.black54 : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 5,
      decoration: const InputDecoration(
        hintText: 'Unesite opis nekretnine...',
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
    );
  }
}

class _AmenityToggle {
  final String label;
  final IconData icon;
  final bool? value;
  final void Function(bool) onChanged;
  _AmenityToggle(this.label, this.icon, this.value, this.onChanged);
}

// ─── Fullscreen image viewer (local File images) ──────────────────────────────

class _FileFullscreenViewer extends StatefulWidget {
  final List<File> images;
  final int initialIndex;
  const _FileFullscreenViewer(
      {required this.images, required this.initialIndex});

  @override
  State<_FileFullscreenViewer> createState() => _FileFullscreenViewerState();
}

class _FileFullscreenViewerState extends State<_FileFullscreenViewer> {
  late int _idx;

  @override
  void initState() {
    super.initState();
    _idx = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                  color: Colors.transparent,
                  width: size.width,
                  height: size.height),
            ),
            Center(
              child: InteractiveViewer(
                child: Image.file(
                  widget.images[_idx],
                  fit: BoxFit.contain,
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () => Navigator.pop(context),
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.close, color: Colors.white, size: 26),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1) ...[
              Positioned(
                left: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navBtn(
                    icon: Icons.chevron_left,
                    onPressed:
                        _idx > 0 ? () => setState(() => _idx--) : null,
                  ),
                ),
              ),
              Positioned(
                right: 12,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _navBtn(
                    icon: Icons.chevron_right,
                    onPressed: _idx < widget.images.length - 1
                        ? () => setState(() => _idx++)
                        : null,
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_idx + 1} / ${widget.images.length}',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _navBtn({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: onPressed != null ? Colors.black54 : Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
