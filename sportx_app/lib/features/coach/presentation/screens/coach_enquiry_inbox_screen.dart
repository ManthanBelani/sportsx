import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class CoachEnquiryInboxScreen extends ConsumerStatefulWidget {
  final bool isTabContent;

  const CoachEnquiryInboxScreen({super.key, this.isTabContent = false});

  @override
  ConsumerState<CoachEnquiryInboxScreen> createState() => _CoachEnquiryInboxScreenState();
}

class _CoachEnquiryInboxScreenState extends ConsumerState<CoachEnquiryInboxScreen> {
  int _selectedTabIndex = 0;
  final _tabKeys = ['all', 'new', 'replied', 'closed'];
  final _tabLabels = ['All', 'New', 'Replied', 'Closed'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(enquiryInboxProvider.notifier).load();
    });
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTabIndex = index);
  }

  List<Enquiry> _filterItems(List<Enquiry> items) {
    switch (_selectedTabIndex) {
      case 1:
        return items.where((e) => e.status == 'new').toList();
      case 2:
        return items.where((e) => e.status == 'replied').toList();
      case 3:
        return items.where((e) => e.status == 'closed').toList();
      default:
        return items;
    }
  }

  Widget _buildContent() {
    final state = ref.watch(enquiryInboxProvider);
    final allItems = state.items;
    final items = _filterItems(allItems);

    if (state.isLoading && state.items.isEmpty) {
      return const CoachEnquiryListSkeleton();
    }
    if (items.isEmpty) {
      return _buildEmptyState();
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final e = items[index];
        return _buildEnquiryItem(e);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enquiryInboxProvider);
    final allItems = state.items;

    final tabs = List.generate(_tabKeys.length, (index) {
      int count = 0;
      if (index == 0) {
        count = allItems.length;
      } else if (index == 1) {
        count = allItems.where((e) => e.status == 'new').length;
      } else if (index == 2) {
        count = allItems.where((e) => e.status == 'replied').length;
      } else if (index == 3) {
        count = allItems.where((e) => e.status == 'closed').length;
      }

      return Tab(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_tabLabels[index], style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text('($count)', style: GoogleFonts.inter(fontSize: 12)),
          ],
        ),
      );
    });

    final tabBar = TabBar(
      onTap: _onTabChanged,
      tabs: tabs,
      labelColor: AppColors.primary,
      unselectedLabelColor: AppColors.textSecondary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
      indicatorColor: AppColors.primary,
      indicatorWeight: 2,
      dividerColor: AppColors.border,
    );

    if (widget.isTabContent) {
      return DefaultTabController(
        length: _tabKeys.length,
        child: Column(
          children: [
            tabBar,
            Expanded(child: _buildContent()),
          ],
        ),
      );
    }

    return DefaultTabController(
      length: _tabKeys.length,
      child: Scaffold(
        backgroundColor: AppColors.surface,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'Enquiry Inbox',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
        ),
        body: Column(
          children: [
            tabBar,
            Expanded(child: _buildContent()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.inbox, size: 48, color: AppColors.textSecondary),
          const SizedBox(height: 16),
          const Text(
            'No enquiries yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          const Text(
            'When athletes enquire about\nyour coaching, they will appear here',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEnquiryItem(Enquiry e) {
    final status = e.status;

    return InkWell(
      onTap: () => context.push('/coach-enquiry-detail', extra: {'id': e.id}),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.coach.withValues(alpha: 0.12),
              child: e.athletePhotoUrl != null
                  ? ClipOval(
                      child: Image.network(
                        e.athletePhotoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Icon(LucideIcons.user, color: AppColors.coach),
                      ),
                    )
                  : const Icon(LucideIcons.user, color: AppColors.coach),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.athleteName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (e.messages.isNotEmpty && e.messages.first.isMe) ...[
                        const Icon(LucideIcons.checkCheck, size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          e.messages.isNotEmpty ? e.messages.first.body : e.message,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (e.sport != null) ...[
                        Icon(LucideIcons.target, size: 12, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          e.sport!,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        DateFormatUtils.formatRelative(e.createdAt),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
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

  Widget _buildStatusBadge(String status) {
    switch (status) {
      case 'new':
        return const StatusPill(label: 'New', kind: PillKind.pending);
      case 'replied':
        return const StatusPill(label: 'Replied', kind: PillKind.ok);
      case 'closed':
        return const StatusPill(label: 'Closed', kind: PillKind.draft);
      default:
        return StatusPill(label: status, kind: PillKind.draft);
    }
  }
}
