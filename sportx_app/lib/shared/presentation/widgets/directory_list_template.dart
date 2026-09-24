import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
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
        title: Text(widget.title,
            style: GoogleFonts.sora(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SportXIconButton(icon: LucideIcons.slidersHorizontal, onTap: widget.onFilterTap),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // v2 .searchbar row — matches trials.html / coach-directory.html
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: DesignTokens.inputHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border, width: 1.5),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: SportXShadows.e1,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.search,
                            color: AppColors.textSecondary, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            focusNode: _focusNode,
                            style: GoogleFonts.inter(
                                fontSize: 14, color: AppColors.textPrimary),
                            decoration: InputDecoration(
                              hintText: 'Search ${widget.title.toLowerCase()}...',
                              hintStyle: GoogleFonts.inter(
                                  color: AppColors.textTertiary, fontSize: 14),
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
                              setState(() {});
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
                            child: const Icon(LucideIcons.x,
                                color: AppColors.textSecondary, size: 16),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // v2 .chiprow
          if (widget.sportOptions.length > 1)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.sportOptions.length,
                itemBuilder: (context, index) {
                  final sport = widget.sportOptions[index];
                  final isAll = sport == 'All Sports';
                  final isSelected = isAll ? _selectedSport == null : _selectedSport == sport;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SportXChip(
                      label: sport,
                      selected: isSelected,
                      onTap: () {
                        setState(() => _selectedSport = isAll ? null : sport);
                        widget.onSportSelected?.call(isAll ? null : sport);
                      },
                    ),
                  );
                },
              ),
            ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              itemCount: widget.items.length + 2,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(2, 2, 2, 12),
                    child: Text(
                      '${widget.items.length} ${widget.title.toLowerCase()} found',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
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
                            child: Text('Load more',
                                style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDarker)),
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
    // v2 .entity — white card, 16px radius, yellow-gradient avatar, e1 shadow.
    // Functionality unchanged: same onItemTap, same fields.
    return EntityRow(
      title: item.title,
      subtitle: item.subtitle,
      avatarText: item.title.isNotEmpty ? item.title[0].toUpperCase() : '?',
      onTap: () => widget.onItemTap(item),
      trailing: item.rating != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.star, color: AppColors.yellowDeep, size: 14),
                const SizedBox(width: 4),
                Text(item.rating!,
                    style: GoogleFonts.inter(
                        fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(width: 4),
                const Icon(LucideIcons.chevronRight,
                    color: Color(0xFFC9CDD3), size: 18),
              ],
            )
          : null,
    );
  }
}
