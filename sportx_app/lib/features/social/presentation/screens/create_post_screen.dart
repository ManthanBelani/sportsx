import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionController = TextEditingController();
  final _focusNode = FocusNode();
  final List<File> _selectedMedia = [];
  final List<String> _selectedHashtags = [];
  bool _isPosting = false;

  final List<String> _availableHashtags = [
    'Cricket',
    'Football',
    'Badminton',
    'Tennis',
    'Hockey',
    'Kabaddi',
    'Athletics',
    'Swimming',
    'Boxing',
    'Wrestling',
  ];

  @override
  void dispose() {
    _captionController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pickMedia(ImageSource source) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedMedia.add(File(pickedFile.path));
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  void _toggleHashtag(String hashtag) {
    setState(() {
      if (_selectedHashtags.contains(hashtag)) {
        _selectedHashtags.remove(hashtag);
      } else {
        _selectedHashtags.add(hashtag);
      }
    });
  }

  Future<void> _submitPost() async {
    if (_captionController.text.trim().isEmpty && _selectedMedia.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a caption or media')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'caption': _captionController.text.trim(),
        'hashtags': _selectedHashtags,
        if (_selectedMedia.isNotEmpty)
          'media': await Future.wait(
            _selectedMedia.asMap().entries.map((entry) async {
              return MultipartFile.fromFile(
                entry.value.path,
                filename: 'post_media_${entry.key}.jpg',
              );
            }),
          ),
      });

      await dio.post('/posts', data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post created successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create post: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Post'),
        actions: [
          TextButton(
            onPressed: _isPosting ? null : _submitPost,
            child: _isPosting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _captionController,
              focusNode: _focusNode,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: "What's on your mind?",
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
              ),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            if (_selectedMedia.isNotEmpty) ...[
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedMedia.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            image: DecorationImage(
                              image: FileImage(_selectedMedia[index]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 12,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMedia.removeAt(index));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, size: 16, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableHashtags.map((hashtag) {
                final isSelected = _selectedHashtags.contains(hashtag);
                return FilterChip(
                  label: Text('#$hashtag'),
                  selected: isSelected,
                  onSelected: (_) => _toggleHashtag(hashtag),
                  selectedColor: AppColors.infoLight,
                  backgroundColor: AppColors.surface,
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMediaButton(
              icon: Icons.photo_library_outlined,
              label: 'Gallery',
              onTap: () => _pickMedia(ImageSource.gallery),
            ),
            _buildMediaButton(
              icon: Icons.camera_alt_outlined,
              label: 'Camera',
              onTap: () => _pickMedia(ImageSource.camera),
            ),
            _buildMediaButton(
              icon: Icons.tag,
              label: 'Hashtags',
              onTap: () {
                _focusNode.unfocus();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
