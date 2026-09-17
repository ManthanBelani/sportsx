import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

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
                leading: Icon(mediaType == 'video' ? LucideIcons.video : LucideIcons.camera, color: AppColors.primary),
                title: Text(mediaType == 'video' ? 'Record Video' : 'Take Photo'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ListTile(
              leading: Icon(mediaType == 'video' ? LucideIcons.video : LucideIcons.image, color: AppColors.primary),
              title: Text(mediaType == 'video' ? 'Choose Video from Gallery' : 'Choose from Gallery'),
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
    final picker = ImagePicker();
    XFile? picked;
    final isVideo = mediaType == 'video';
    if (isVideo) {
      picked = await picker.pickVideo(source: source);
    } else {
      picked = await picker.pickImage(source: source, imageQuality: 80);
    }
    if (picked == null) return null;

    final file = File(picked.path);
    final fileSize = await file.length();
    if (fileSize == 0) {
      if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('Selected file is empty')));
      return null;
    }
    // Client-side size guard (backend limit 10MB)
    const kMaxBytes = 10 * 1024 * 1024;
    if (fileSize > kMaxBytes) {
      if (context.mounted) messenger.showSnackBar(const SnackBar(content: Text('File too large (max 10MB)')));
      return null;
    }

    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: picked.name),
      'media_type': mediaType,
    });

    final resp = await ref.read(dioProvider).post('/media/upload', data: form);

      final data = resp.data is Map ? resp.data['data'] as Map<String, dynamic>? : null;
    final mediaId = data?['id'] as int?;
    final url = data?['url'] as String? ?? '';

    if (mediaId == null || mediaId == 0) {
      if (context.mounted) SnackBarUtils.showError(context, 'Upload succeeded but server did not return media ID. Please try again.');
      return null;
    }

    if (context.mounted) SnackBarUtils.showSuccess(context, 'Uploaded successfully');

    return PickedMedia(file: file, mediaId: mediaId, url: url);
  } on DioException catch (e) {
    if (context.mounted) {
      final apiEx = ApiException.fromDio(e);
      if (apiEx.fieldErrors.isNotEmpty) {
        SnackBarUtils.showValidationError(context, apiEx.fieldErrors, apiEx);
      } else {
        SnackBarUtils.showError(context, apiEx);
      }
    }
    return null;
  } catch (e) {
    if (context.mounted) {
      SnackBarUtils.showError(context, e, 'Upload failed. Please check your connection and try again.');
    }
    return null;
  }
}

/// Deletes a media item by ID. Returns (success, errorMessage).
Future<(bool, String?)> deleteMedia(WidgetRef ref, int mediaId) async {
  try {
    await ref.read(dioProvider).delete('/media/$mediaId');
    return (true, null);
  } on DioException catch (e) {
    return (false, ApiException.fromDio(e).message);
  } catch (e) {
    return (false, ApiException.messageFor(e));
  }
}

/// Reorders media items. Returns (success, errorMessage).
Future<(bool, String?)> reorderMedia(WidgetRef ref, List<Map<String, int>> items) async {
  if (items.isEmpty) return (true, null);
  try {
    await ref.read(dioProvider).put('/media/reorder', data: {'items': items});
    return (true, null);
  } on DioException catch (e) {
    return (false, ApiException.fromDio(e).message);
  } catch (e) {
    return (false, ApiException.messageFor(e));
  }
}

/// Returns a signed download URL for a private media item.
Future<(String?, String?)> getSignedMediaUrl(WidgetRef ref, int mediaId) async {
  try {
    final resp = await ref.read(dioProvider).get('/media/$mediaId/signed-url');
    final data = resp.data is Map ? resp.data['data'] as Map<String, dynamic>? : null;
    final url = data?['url'] as String?;
    if (url == null || url.isEmpty) return (null, 'Failed to generate download link. Please try again.');
    return (url, null);
  } on DioException catch (e) {
    return (null, ApiException.fromDio(e).message);
  } catch (e) {
    return (null, ApiException.messageFor(e));
  }
}
