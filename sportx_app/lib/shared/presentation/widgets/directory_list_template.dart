import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:go_router/go_router.dart';

class DirectoryItem {
  final String id;
  final String? thumbnailUrl;
  final String title;
  final String subtitle;
  final String meta;
  final String? rating;

  DirectoryItem({
    required this.id,
    this.thumbnailUrl,
    required this.title,
    required this.subtitle,
    required this.meta,
    this.rating,
  });
}

class DirectoryListTemplate extends StatefulWidget {
  final String title;
  final List<DirectoryItem> items;
  final VoidCallback onFilterTap;
  final Function(DirectoryItem) onItemTap;
  final VoidCallback onLoadMore;
  final IconData defaultIcon;

  const DirectoryListTemplate({
    super.key,
    required this.title,
    required this.items,
    required this.onFilterTap,
    required this.onItemTap,
    required this.onLoadMore,
    this.defaultIcon = LucideIcons.circleDot,
  });

  @override
  State<DirectoryListTemplate> createState() => _DirectoryListTemplateState();
}

class _DirectoryListTemplateState extends State<DirectoryListTemplate> {
  String _selectedSport = 'All Sports';
  final List<Map<String, dynamic>> _sports = [
    {'name': 'All Sports', 'icon': null},
    {'name': 'Cricket', 'icon': LucideIcons.circleDot},
    {'name': 'Football', 'icon': LucideIcons.goal},
    {'name': 'Badminton', 'icon': LucideIcons.venetianMask},
    {'name': 'Swimming', 'icon': LucideIcons.waves},
    {'name': 'Athletics', 'icon': LucideIcons.footprints},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(widget.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.slidersHorizontal, color: AppColors.textSecondary),
            onPressed: widget.onFilterTap,
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.search, color: AppColors.textSecondary, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.title.toLowerCase()}...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _sports.length,
              itemBuilder: (context, index) {
                final sport = _sports[index];
                final isSelected = _selectedSport == sport['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedSport = sport['name'] as String),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFE6F0FF) : AppColors.surface,
                      border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        if (sport['icon'] != null) ...[
                          Icon(sport['icon'] as IconData, size: 14, color: isSelected ? AppColors.primary : AppColors.textPrimary),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          sport['name'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: widget.items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '${widget.items.length} ${widget.title.toLowerCase()} found',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  );
                }
                
                if (index == widget.items.length + 1) {
                  return widget.items.isEmpty 
                    ? const SizedBox()
                    : Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: TextButton(
                            onPressed: widget.onLoadMore,
                            child: const Text('Load more'),
                          ),
                        ),
                      );
                }
                
                final item = widget.items[index - 1];
                return _buildCard(context, item);
              },
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, DirectoryItem item) {
    return GestureDetector(
      onTap: () => widget.onItemTap(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                image: item.thumbnailUrl != null
                    ? DecorationImage(
                        image: NetworkImage(item.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              alignment: Alignment.center,
              child: item.thumbnailUrl == null
                  ? Icon(widget.defaultIcon, color: AppColors.primary, size: 32)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.meta,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                      ),
                      if (item.rating != null)
                        Row(
                          children: [
                            const Icon(LucideIcons.star, color: Colors.amber, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              item.rating!,
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
