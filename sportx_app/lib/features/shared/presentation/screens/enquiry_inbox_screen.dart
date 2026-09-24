import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class EnquiryInboxScreen extends ConsumerStatefulWidget {
  const EnquiryInboxScreen({super.key});

  @override
  ConsumerState<EnquiryInboxScreen> createState() => _EnquiryInboxScreenState();
}

class _EnquiryInboxScreenState extends ConsumerState<EnquiryInboxScreen> {
  int _selectedIndex = 0;
  bool get _loading => ref.read(enquiryInboxProvider).isLoading;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(enquiryInboxProvider.notifier).load());
  }

  Future<void> _refresh() => ref.read(enquiryInboxProvider.notifier).load();

  List<Enquiry> _filtered(List<Enquiry> items) {
    switch (_selectedIndex) {
      case 1:
        return items.where((e) => e.status == 'new').toList();
      case 2:
        return items.where((e) => e.status == 'replied').toList();
      default:
        return items;
    }
  }

  String _relativeTime(String? iso) {
    if (iso == null) return '';
    final t = DateTime.tryParse(iso);
    if (t == null) return '';
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${t.day}/${t.month}/${t.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enquiryInboxProvider);
    final all = state.items;
    final newCount = all.where((e) => e.status == 'new').length;
    final repliedCount = all.where((e) => e.status == 'replied').length;
    final tabs = ['All (${all.length})', 'New ($newCount)', 'Replied ($repliedCount)'];
    final items = _filtered(all);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: 'Enquiry Inbox',
        showBack: true,
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/academy-dashboard'),
      ) as PreferredSizeWidget,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: List.generate(tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => setState(() => _selectedIndex = index),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.infoLight : AppColors.surface,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        tabs[index],
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: _loading && all.isEmpty
                  ? const GenericListSkeleton()
                  : state.error != null && all.isEmpty
                      ? ListView(children: [
                          Padding(
                            padding: const EdgeInsets.all(32),
                            child: Center(
                              child: Text(state.error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: AppColors.textSecondary)),
                            ),
                          ),
                        ])
                      : items.isEmpty
                          ? ListView(children: const [
                              Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Text('No enquiries yet',
                                          style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppColors.textPrimary)),
                                      SizedBox(height: 4),
                                      Text(
                                          'When athletes enquire about\nyour coaching, they will appear here',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: AppColors.textSecondary,
                                              height: 1.4)),
                                    ],
                                  ),
                                ),
                              ),
                            ])
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: items.length,
                              itemBuilder: (context, i) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _EnquiryCard(
                                  enquiry: items[i],
                                  timeLabel: _relativeTime(items[i].createdAt),
                                ),
                              ),
                            ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnquiryCard extends StatelessWidget {
  final Enquiry enquiry;
  final String timeLabel;

  const _EnquiryCard({required this.enquiry, required this.timeLabel});

  Color get _badgeBg {
    switch (enquiry.status) {
      case 'replied':
        return AppColors.successLight;
      default:
        return AppColors.infoLight;
    }
  }

  Color get _badgeFg {
    switch (enquiry.status) {
      case 'replied':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  String get _badgeLabel => enquiry.status == 'replied' ? 'Replied' : 'New';

  @override
  Widget build(BuildContext context) {
    final e = enquiry;
    final isNew = e.status == 'new';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/enquiry-detail', extra: {'id': e.id}),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          border: Border.all(color: isNew ? AppColors.primary.withValues(alpha: 0.4) : AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.surface,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              backgroundImage: e.athletePhotoUrl != null ? NetworkImage(e.athletePhotoUrl!) : null,
              child: e.athletePhotoUrl == null
                  ? Text(
                      e.athleteName.isNotEmpty ? e.athleteName[0].toUpperCase() : '?',
                      style: const TextStyle(
                          color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(e.athleteName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15, color: AppColors.textPrimary)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _badgeBg,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(_badgeLabel,
                            style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w600, color: _badgeFg)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(e.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 13, color: Colors.grey[700], height: 1.3)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(LucideIcons.circleDot, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          e.sport ?? e.subject.replaceAll('_', ' '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                      Text(timeLabel,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
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