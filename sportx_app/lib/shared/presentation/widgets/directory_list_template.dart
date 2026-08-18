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

  /// Called with the current search text (empty string when cleared).
  final void Function(String query)? onSearchChanged;

  /// Human-readable sport names available for the filter chips.
  final List<String> sportOptions;

  /// Called when the user taps a sport chip (null = All Sports).
  final void Function(String? sport)? onSportSelected;

  const DirectoryListTemplate({
    super.key,
    required this.title,
    required this.items,
    required this.onFilterTap,
    required this.onItemTap,
    required this.onLoadMore,
    this.defaultIcon = LucideIcons.circleDot,
    this.onSearchChanged,
    this.sportOptions = const ['All Sports'],
    this.onSportSelected,
  });

  @override
  State<DirectoryListTemplate> createState() => _DirectoryListTemplateState();
}

class _DirectoryListTemplateState extends State<DirectoryListTemplate> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  String? _selectedSport;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    widget.onSearchChanged?.call(value.trim());
  }

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
                      controller: _searchController,
                      focusNode: _focusNode,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: 'Search ${widget.title.toLowerCase()}...',
                        hintStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _applySearch,
                      onChanged: (v) {
                        if (v.trim().isEmpty) _applySearch(v);
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _applySearch('');
                        _focusNode.unfocus();
                      },
                      child: const Icon(LucideIcons.x, color: AppColors.textSecondary, size: 16),
                    ),
                ],
              ),
            ),
          ),

          if (widget.sportOptions.length > 1)
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.sportOptions.length,
                itemBuilder: (context, index) {
                  final sport = widget.sportOptions[index];
                  final isAll = sport == 'All Sports';
                  final isSelected = isAll ? _selectedSport == null : _selectedSport == sport;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedSport = isAll ? null : sport);
                      widget.onSportSelected?.call(isAll ? null : sport);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFFE6F0FF) : AppColors.surface,
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        sport,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
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
