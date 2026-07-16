import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smartstock/core/theme/app_colors.dart';
import 'package:smartstock/core/services/imgbb_service.dart';

class ImagePickerWidget extends StatefulWidget {
  final String? initialImageUrl;
  final ValueChanged<String> onImageUploaded;

  const ImagePickerWidget({
    super.key,
    this.initialImageUrl,
    required this.onImageUploaded,
  });

  @override
  State<ImagePickerWidget> createState() => _ImagePickerWidgetState();
}

class _ImagePickerWidgetState extends State<ImagePickerWidget> {
  final ImagePicker _picker = ImagePicker();
  final ImgBBService _imgbbService = ImgBBService();
  String? _imageUrl;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.initialImageUrl;
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        await _uploadImage(image);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _uploadImage(XFile image) async {
    setState(() => _isUploading = true);

    try {
      final bytes = await image.readAsBytes();
      final base64Image = base64Encode(bytes);
      final url = await _imgbbService.uploadImage(base64Image);

      if (url != null) {
        setState(() => _imageUrl = url);
        widget.onImageUploaded(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to upload image')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Image',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 180,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.outlineVariant,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: _isUploading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                )
              : _imageUrl != null && _imageUrl!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: _imageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (context, error, stackTrace) =>
                              _buildPlaceholder(),
                          placeholder: (context, url) =>
                              _buildPlaceholder(),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            onPressed: () => setState(() {
                              _imageUrl = null;
                              widget.onImageUploaded('');
                            }),
                            icon: const Icon(Icons.close),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              foregroundColor: Colors.white,
                              iconSize: 18,
                            ),
                          ),
                        ),
                      ],
                    )
                  : _buildPlaceholder(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt, size: 18),
                label: const Text(
                  'Camera',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library, size: 18),
                label: const Text(
                  'Gallery',
                  style: TextStyle(fontFamily: 'Inter', fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image,
            size: 48,
            color: AppColors.onSurfaceVariant,
          ),
          SizedBox(height: 4),
          Text(
            'No image selected',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
