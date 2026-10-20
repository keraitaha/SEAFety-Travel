import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../cloudinary_service.dart';
import '../../shared/models/app_user.dart';
import '../../shared/models/destination_model.dart';
import '../../shared/models/package_model.dart';
import '../../shared/theme/app_theme.dart';
import '../services/destination_service.dart';
import '../services/package_service.dart';

class PackageFormScreen extends StatefulWidget {
  final AppUser currentUser;
  final PackageModel? existing;
  const PackageFormScreen({
    super.key,
    required this.currentUser,
    this.existing,
  });

  @override
  State<PackageFormScreen> createState() => _PackageFormScreenState();
}

class _PackageFormScreenState extends State<PackageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _inclusionsController = TextEditingController();

  final PackageService _packageService = PackageService();
  final DestinationService _destinationService = DestinationService();

  String? _destinationid;
  String _availability = 'available';
  bool _published = true;
  String _imageurl = '';
  File? _pickedImage;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    if (p != null) {
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _durationController.text = p.durationdays.toString();
      _inclusionsController.text = p.inclusions.join(', ');
      _destinationid = p.destinationid;
      _availability = p.availability;
      _published = p.published;
      _imageurl = p.imageurl;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _inclusionsController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _pickedImage = File(picked.path));
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_destinationid == null) {
      setState(() => _error = 'Please choose a destination.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    String imageurl = _imageurl;
    if (_pickedImage != null) {
      final uploaded = await CloudinaryService.uploadImage(_pickedImage!);
      if (uploaded == null) {
        setState(() {
          _saving = false;
          _error = 'Image upload failed. Please try again.';
        });
        return;
      }
      imageurl = uploaded;
    }

    final inclusions = _inclusionsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final price = double.tryParse(_priceController.text.trim()) ?? 0;
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;

    try {
      if (widget.existing == null) {
        await _packageService.addPackage(
          agencyuserid: widget.currentUser.userid,
          destinationid: _destinationid!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageurl: imageurl,
          price: price,
          durationdays: duration,
          inclusions: inclusions,
          availability: _availability,
          published: _published,
        );
      } else {
        await _packageService.updatePackage(
          packageid: widget.existing!.packageid,
          destinationid: _destinationid!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          imageurl: imageurl,
          price: price,
          durationdays: duration,
          inclusions: inclusions,
          availability: _availability,
          published: _published,
        );
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = 'Could not save package. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Package' : 'New Package')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ImagePreview(
                  pickedImage: _pickedImage,
                  imageurl: _imageurl,
                  onPick: _saving ? null : _pickImage,
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<DestinationModel>>(
                  stream: _destinationService.publishedDestinations(),
                  builder: (context, snapshot) {
                    final destinations = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      initialValue: _destinationid,
                      decoration: const InputDecoration(
                        labelText: 'Destination',
                      ),
                      items: destinations
                          .map(
                            (d) => DropdownMenuItem(
                              value: d.destinationid,
                              child: Text('${d.name} (${d.country})'),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _destinationid = value),
                    );
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price (MYR)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (double.tryParse(v.trim()) == null) {
                      return 'Enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (days)',
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (int.tryParse(v.trim()) == null) {
                      return 'Enter a whole number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _inclusionsController,
                  decoration: const InputDecoration(
                    labelText: 'Inclusions (comma separated)',
                    hintText: 'Breakfast, Transport, Guide',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _availability,
                  decoration: const InputDecoration(labelText: 'Availability'),
                  items: const [
                    DropdownMenuItem(
                      value: 'available',
                      child: Text('Available'),
                    ),
                    DropdownMenuItem(
                      value: 'limited',
                      child: Text('Limited'),
                    ),
                    DropdownMenuItem(
                      value: 'unavailable',
                      child: Text('Unavailable'),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _availability = value ?? 'available'),
                ),
                SwitchListTile(
                  title: const Text('Published'),
                  value: _published,
                  onChanged: (value) => setState(() => _published = value),
                ),
                const SizedBox(height: 8),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Create Package'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePreview extends StatelessWidget {
  final File? pickedImage;
  final String imageurl;
  final VoidCallback? onPick;
  const _ImagePreview({
    required this.pickedImage,
    required this.imageurl,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (pickedImage != null) {
      content = Image.file(pickedImage!, fit: BoxFit.cover);
    } else if (imageurl.isNotEmpty) {
      content = Image.network(imageurl, fit: BoxFit.cover);
    } else {
      content = const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_a_photo, size: 40, color: AppColors.lightBlue),
            SizedBox(height: 8),
            Text('Tap to add image'),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: onPick,
      child: Container(
        height: 160,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.paleBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      ),
    );
  }
}
