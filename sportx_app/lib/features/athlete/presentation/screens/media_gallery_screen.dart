import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/theme/colors.dart';

class MediaGalleryScreen extends ConsumerStatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  ConsumerState<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends ConsumerState<MediaGalleryScreen> {
  int _currentTab = 0;
  List<Map<String, dynamic>> _mediaItems = [];
  bool _isReorderMode = false;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    try {
      final resp = await ref.read(dioProvider).get('/me/profile');
      final data = resp.data['data'] as Map<String, dynamic>?;
      final items = (data?['media_items'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (mounted) setState(() => _mediaItems = items);
    } catch (_) {}
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_currentTab == 0) return _mediaItems.where((i) => i['media_type'] == 'photo').toList();
    if (_currentTab == 1) return _mediaItems.where((i) => i['media_type'] == 'video').toList();
    return [];
  }

  Future<void> _uploadMedia() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: _currentTab == 1 ? 'video' : 'photo');
    if (media == null) return;
    await _loadMedia();
  }

  Future<void> _deleteMedia(int mediaId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Media'),
        content: const Text('Are you sure you want to delete this item?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final success = await deleteMedia(ref, mediaId);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Deleted' : 'Failed to delete')),
      );
    }
    if (success) await _loadMedia();
  }

  Future<void> _saveReorder(List<Map<String, dynamic>> newOrder) async {
    final items = newOrder.asMap().entries.map((e) => {
      'id': e.value['id'] as int,
      'sort_order': e.key,
    }).toList();
    final success = await reorderMedia(ref, items.cast<Map<String, int>>());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Order saved' : 'Failed to save order')),
      );
    }
    if (success) setState(() => _isReorderMode = false);
  }

  String _absoluteUrl(String url) {
    if (url.isEmpty) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final base = ref.read(dioProvider).options.baseUrl;
    final origin = base.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return '$origin$url';
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
        title: Text(_isReorderMode ? 'Drag to Reorder' : 'Media Gallery', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: true,
        actions: [
          if (_isReorderMode) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => setState(() => _isReorderMode = false),
                child: const Text('Cancel'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed: () => _saveReorder(_filteredItems),
                child: const Text('Save'),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => setState(() => _isReorderMode = true),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:                   const Icon(Icons.drag_handle, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ],
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
                _buildTab('Photos (${_mediaItems.where((i) => i['media_type'] == 'photo').length})', 0),
                _buildTab('Videos (${_mediaItems.where((i) => i['media_type'] == 'video').length})', 1),
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

    if (_isReorderMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex -= 1;
            final item = items.removeAt(oldIndex);
            items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            key: ValueKey(item['id']),
            height: 80,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: AppColors.surface,
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(
                  _absoluteUrl((item['url'] ?? '') as String),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: AppColors.border,
                    child: const Icon(LucideIcons.image, size: 24),
                  ),
                ),
              ),
              title: Text(item['media_type'] == 'video' ? 'Video' : 'Photo'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.trash2, color: Colors.red),
                    onPressed: () => _deleteMedia(item['id'] as int),
                  ),
                  const Icon(Icons.drag_handle, color: AppColors.textSecondary),
                ],
              ),
            ),
          );
        },
      );
    }

    final itemCount = items.length + 1;
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
          return GestureDetector(
            onTap: _uploadMedia,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, style: BorderStyle.solid, width: 2),
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
        return _buildMediaTile(item);
      },
    );
  }

  Widget _buildMediaTile(Map<String, dynamic> item, {Key? key}) {
    return Stack(
      key: key,
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _absoluteUrl((item['url'] ?? '') as String),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.surface,
              child: const Icon(LucideIcons.image, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (item['media_type'] == 'video')
          const Center(
            child: Icon(
              Icons.play_arrow,
              size: 32,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        if (_isReorderMode)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _deleteMedia(item['id'] as int),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white),
              ),
            ),
          )
        else
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GestureDetector(
              onLongPress: () => _deleteMedia(item['id'] as int),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.5)],
                  ),
                ),
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 4),
                child: const Icon(LucideIcons.trash2, size: 16, color: Colors.white70),
              ),
            ),
          ),
      ],
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
