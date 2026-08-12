import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class MediaGalleryScreen extends ConsumerStatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  ConsumerState<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends ConsumerState<MediaGalleryScreen> {
  int _currentTab = 0;
  
  // Mock media data
  final List<Map<String, dynamic>> _mediaItems = [
    {'id': '1', 'url': 'https://images.unsplash.com/photo-1517649763962-0c623066013b?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '2', 'url': 'https://images.unsplash.com/photo-1461896836934-0c70ed8b1e22?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '3', 'url': 'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=300&h=300&fit=crop', 'type': 'video'},
    {'id': '4', 'url': 'https://images.unsplash.com/photo-1535131749006-b7f58c99034b?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '5', 'url': 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '6', 'url': 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '7', 'url': 'https://images.unsplash.com/photo-1547347298-4074fc3086f0?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '8', 'url': 'https://images.unsplash.com/photo-1526232761682-d26e03ac148e?w=300&h=300&fit=crop', 'type': 'photo'},
    {'id': '9', 'url': 'https://images.unsplash.com/photo-1599058917212-d750089bc07e?w=300&h=300&fit=crop', 'type': 'video'},
  ];

  List<Map<String, dynamic>> get _filteredItems {
    if (_currentTab == 0) return _mediaItems.where((i) => i['type'] == 'photo').toList();
    if (_currentTab == 1) return _mediaItems.where((i) => i['type'] == 'video').toList();
    return []; // Achievements handled differently or empty for now
  }

  Future<void> _uploadMedia(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile == null) return;
      final file = File(pickedFile.path);
      final form = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: pickedFile.name),
        'media_type': 'photo',
      });
      await ref.read(dioProvider).post('/media/upload', data: form);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media uploaded successfully!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to upload media: $e')));
      }
    }
  }

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(LucideIcons.camera, color: AppColors.primary),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadMedia(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.image, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadMedia(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: const Text('Media Gallery', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.check, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Tab Bar
          Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _buildTab('Photos (24)', 0),
                _buildTab('Videos (3)', 1),
                _buildTab('Achievements (8)', 2),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildGrid(),
                  const SizedBox(height: 12),
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String title, int index) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isActive ? AppColors.primary : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final items = _filteredItems;
    final itemCount = items.length + 1; // +1 for the Add button

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == items.length) {
          // Add Button
          return GestureDetector(
            onTap: _showUploadOptions,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 2), // Dashed isn't native, solid for now
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, color: AppColors.textSecondary),
                  SizedBox(height: 8),
                  Text('Add', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
                ],
              ),
            ),
          );
        }

        final item = items[index];
        return Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item['url'], fit: BoxFit.cover),
            ),
            if (item['type'] == 'video')
              const Center(
                child: Icon(
                  Icons.play_arrow,
                  size: 32,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tips for a great gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          SizedBox(height: 4),
          Text(
            'Add photos and videos of your training, matches, and achievements. Profiles with media get 3x more enquiries.',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
