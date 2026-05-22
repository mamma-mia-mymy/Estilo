import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerWidget extends StatefulWidget {
  final Function(File?) onImageSelected;

  const ImagePickerWidget({required this.onImageSelected, Key? key}) : super(key: key);

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      widget.onImageSelected(_selectedImage);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _pickImage,
      child: CircleAvatar(
        radius: 48,
        backgroundColor: Colors.grey.shade200,
        backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : null,
        child: _selectedImage == null
            ? Icon(Icons.camera_alt_outlined, size: 32, color: Colors.black45)
            : null,
      ),
    );
  }
}