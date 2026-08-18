import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class PickedMedia {
  final File file;
  final int mediaId;
  final String url;

  PickedMedia({required this.file, required this.mediaId, required this.url});
}

class MediaItem {
  final int id;
  final String url;
  final String mediaType;
  final int sortOrder;

  MediaItem({
    required this.id,
    required this.url,
    required this.mediaType,
    this.sortOrder = 0,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    return MediaItem(
      id: json['id'] as int,
      url: json['url'] as String? ?? '',
      mediaType: json['media_type'] as String? ?? 'photo',
      sortOrder: json['sort_order'] as int? ?? 0,
    );
  }
}

/// Shows the camera/gallery source sheet, picks an image and uploads it to
/// `/media/upload`. Returns null when the user cancels or the pick fails.
Future<PickedMedia?> pickAndUploadMedia(
  BuildContext context,
  WidgetRef ref, {
  String mediaType = 'photo',
  bool allowCamera = true,
}) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    backgroundColor: AppColors.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (allowCamera)
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: const Icon(LucideIcons.image, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    ),
  );

  if (source == null || !context.mounted) return null;

  final messenger = ScaffoldMessenger.of(context);

  try {
    final picked = await ImagePicker().pickImage(source: source, imageQuality: 80);
    if (picked == null) return null;

    final file = File(picked.path);
    final fileSize = await file.length();
    if (fileSize == 0) {
      if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('Selected file is empty')));
      return null;
    }

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: picked.name),
      'media_type': mediaType,
    });

    final resp = await ref.read(dioProvider).post('/media/upload', data: form);

    if (resp.statusCode != 201) {
      if (context.mounted) messenger.showSnackBar(SnackBar(content: Text('Upload failed: ${resp.statusCode}')));
      return null;
    }

    final data = resp.data is Map ? resp.data['data'] as Map<String, dynamic>? : null;
    final mediaId = data?['id'] as int?;
    final url = data?['url'] as String? ?? '';

    if (mediaId == null || mediaId == 0) {
      if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('Upload succeeded but no media ID returned')));
      return null;
    }

    if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('Uploaded successfully')));

    return PickedMedia(file: file, mediaId: mediaId, url: url);
  } on DioException catch (e) {
    if (context.mounted) {
      final apiEx = ApiException.fromDio(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload error: ${apiEx.message} (${apiEx.statusCode})')),
      );
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    }
    return null;
  }
}

/// Deletes a media item by ID. Returns true on success.
Future<bool> deleteMedia(WidgetRef ref, int mediaId) async {
  try {
    await ref.read(dioProvider).delete('/media/$mediaId');
    return true;
  } on DioException {
    return false;
  }
}

/// Reorders media items. The `items` list should contain the new ordered list
/// of {id, sort_order} pairs.
Future<bool> reorderMedia(WidgetRef ref, List<Map<String, int>> items) async {
  if (items.isEmpty) return true;
  try {
    await ref.read(dioProvider).put('/media/reorder', data: {'items': items});
    return true;
  } on DioException {
    return false;
  }
}
