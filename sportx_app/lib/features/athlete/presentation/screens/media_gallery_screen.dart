import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class MediaGalleryScreen extends ConsumerStatefulWidget {
  const MediaGalleryScreen({super.key});

  @override
  ConsumerState<MediaGalleryScreen> createState() => _MediaGalleryScreenState();
}

class _MediaGalleryScreenState extends ConsumerState<MediaGalleryScreen> {
  int _currentTab = 0;
  List<Map<String, dynamic>> _mediaItems = [];
  List<Map<String, dynamic>> _achievements = [];
  bool _isReorderMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedia();
  }

  String get _role => ref.read(authProvider).user?.role ?? 'athlete';

  Future<void> _loadMedia() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // /me/profile now supports both athlete and coach (coach returns media_items + achievements).
      // Fallback to /me/coach-profile if profile is null for coach.
      Map<String, dynamic>? data;
      try {
        final resp = await ref.read(dioProvider).get('/me/profile');
        data = resp.data['data'] as Map<String, dynamic>?;
      } catch (_) {}
      if ((data == null || data.isEmpty) && _role == 'coach') {
        try {
          final resp = await ref.read(dioProvider).get('/me/coach-profile');
          data = resp.data['data'] as Map<String, dynamic>?;
        } catch (_) {}
      }
      // Normalize achievements: may be List of Map or List of String (JSON stored)
      final rawAch = data?['achievements'] as List? ?? const [];
      final ach = rawAch.whereType<dynamic>().map((e) {
        if (e is Map) return Map<String, dynamic>.from(e);
        if (e is String) return <String, dynamic>{'text': e, 'title': e};
        return <String, dynamic>{'text': e.toString()};
      }).toList();
      // Ensure each achievement has an id for keying (use index if missing)
      for (int i = 0; i < ach.length; i++) {
        ach[i]['id'] ??= i + 1;
        // Normalize text/title so display works
        ach[i]['title'] ??= ach[i]['text'];
        ach[i]['text'] ??= ach[i]['title'];
      }
      final items = (data?['media_items'] as List? ?? data?['mediaItems'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
      if (mounted) {
        setState(() {
          _mediaItems = items;
          _achievements = ach;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredItems {
    if (_currentTab == 0) return _mediaItems.where((i) => i['media_type'] == 'photo').toList();
    if (_currentTab == 1) return _mediaItems.where((i) => i['media_type'] == 'video').toList();
    if (_currentTab == 2) return _achievements;
    return [];
  }

  bool _uploading = false;

  Future<void> _uploadMedia() async {
    if (_uploading) return;
    setState(() => _uploading = true);
    try {
      final media = await pickAndUploadMedia(context, ref, mediaType: _currentTab == 1 ? 'video' : 'photo');
      if (media == null) return;
      await _loadMedia();
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
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
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final (success, error) = await deleteMedia(ref, mediaId);
    if (mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, 'Deleted');
      } else {
        SnackBarUtils.showError(context, error ?? 'Failed to delete. Please try again.');
      }
    }
    if (success) await _loadMedia();
  }

  Future<void> _deleteAchievement(dynamic achievementId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Achievement'),
        content: const Text('Are you sure you want to delete this achievement?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      // Remove achievement locally by filtering then persist via PUT /me/profile
      // which now supports coach achievements as JSON.
      final remaining = _achievements.where((a) => a['id'] != achievementId).toList();
      // For legacy achievements where id was index-based, fallback to title/text matching
      final filtered = remaining.length == _achievements.length
          ? _achievements.where((a) => a['id'].toString() != achievementId.toString()).toList()
          : remaining;
      final payloadAch = filtered.isEmpty
          ? []
          : filtered.map((a) => {'text': a['text'] ?? a['title'] ?? ''}).toList();
      await ref.read(dioProvider).put('/me/profile', data: {'achievements': payloadAch});
      if (mounted) SnackBarUtils.showSuccess(context, 'Achievement deleted');
      await _loadMedia();
    } on DioException catch (e) {
      if (mounted) SnackBarUtils.showError(context, ApiException.fromDio(e));
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to delete achievement. Please try again.');
    }
  }

  Future<void> _saveReorder(List<Map<String, dynamic>> newOrder) async {
    final items = newOrder.asMap().entries.map((e) => {
      'id': e.value['id'] as int,
      'sort_order': e.key,
    }).toList();
    final (success, error) = await reorderMedia(ref, items.cast<Map<String, int>>());
    if (mounted) {
      if (success) {
        SnackBarUtils.showSuccess(context, 'Order saved');
      } else {
        SnackBarUtils.showError(context, error ?? 'Failed to save order. Please try again.');
      }
    }
    if (success) {
      await _loadMedia();
      if (mounted) setState(() => _isReorderMode = false);
    }
  }

  String _absoluteUrl(String url) => MediaUtils.resolveUrl(url);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
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
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: Text(_isReorderMode ? 'Drag to Reorder' : 'Media Gallery',
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                    child:                   const Icon(LucideIcons.gripVertical, color: AppColors.textPrimary, size: 20),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      body: _isLoading
          ? const MediaGallerySkeleton()
          : Column(
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
                      _buildTab('Achievements (${_achievements.length})', 2),
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

    if (_currentTab == 2) {
      return _buildAchievementsList();
    }

    if (_isReorderMode) {
      return ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            // Adjust for removal offset handled by onReorderItem but keep compat.
            if (oldIndex < newIndex) newIndex -= 1;
            final moved = items.removeAt(oldIndex);
            items.insert(newIndex, moved);
            // Apply reordered filtered sequence back to underlying _mediaItems
            // so save reflects UI order and cancel keeps original.
            final mediaTypeFilter = _currentTab == 1 ? 'video' : 'photo';
            int cursor = 0;
            for (int i = 0; i < _mediaItems.length; i++) {
              if (_mediaItems[i]['media_type'] == mediaTypeFilter) {
                _mediaItems[i] = items[cursor++];
              }
            }
          });
        },
        itemBuilder: (context, index) {
          final item = items[index];
          return Container(
            key: ValueKey(item['id']),
            height: 80,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              border: Border.all(color: AppColors.border),
              boxShadow: SportXShadows.e1,
            ),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _absoluteUrl((item['url'] ?? '') as String),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
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
                    icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                    onPressed: () => _deleteMedia(item['id'] as int),
                  ),
                  const Icon(LucideIcons.gripVertical, color: AppColors.textSecondary),
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
            errorBuilder: (_, _, _) => Container(
              color: AppColors.surface,
              child: const Icon(LucideIcons.image, color: AppColors.textSecondary),
            ),
          ),
        ),
        if (item['media_type'] == 'video')
          const Center(
            child: Icon(
              LucideIcons.play,
              size: 32,
              color: Colors.white,
              shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
            ),
          ),
        // Always-visible delete button (top-right) – replaces hidden longPress.
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _deleteMedia(item['id'] as int),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1),
              ),
              child: const Icon(LucideIcons.trash2, size: 14, color: Colors.white),
            ),
          ),
        ),
        if (_isReorderMode)
          const Positioned(
            bottom: 4,
            right: 4,
            child: Icon(LucideIcons.gripVertical, color: Colors.white, size: 16, shadows: [Shadow(blurRadius: 4, color: Colors.black54)]),
          ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
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

  Widget _buildAchievementsList() {
    final items = _filteredItems;

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            children: [
              const Icon(LucideIcons.trophy, size: 48, color: AppColors.textSecondary),
              const SizedBox(height: 16),
              const Text(
                'No achievements yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 8),
              const Text(
                'Add your achievements to showcase your accomplishments',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Add Achievement',
                icon: LucideIcons.plus,
                onPressed: () async {
                  await context.push('/add-achievement');
                  await _loadMedia();
                },
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final achievement = entry.value;
        return Container(
          key: ValueKey(achievement['id'] ?? index),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  achievement['icon']?.toString() ?? '🏆',
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement['title']?.toString() ?? achievement['text']?.toString() ?? 'Achievement',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    if (achievement['year'] != null || achievement['date'] != null)
                      Text(
                        achievement['year']?.toString() ?? achievement['date']?.toString() ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    if (achievement['description'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          achievement['description'].toString(),
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ),
                  ],
                ),
              ),
              if (_isReorderMode)
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.error),
                  onPressed: () => _deleteAchievement(achievement['id']),
                )
              else
                IconButton(
                  icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                  onPressed: () => _deleteAchievement(achievement['id']),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
