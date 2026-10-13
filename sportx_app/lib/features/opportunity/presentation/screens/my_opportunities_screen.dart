import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// My Opportunities AT.8 (Phase 4): Applied + Created tabs with status chips.
class MyOpportunitiesScreen extends ConsumerStatefulWidget {
  const MyOpportunitiesScreen({super.key});

  @override
  ConsumerState<MyOpportunitiesScreen> createState() => _MyOpportunitiesScreenState();
}

class _MyOpportunitiesScreenState extends ConsumerState<MyOpportunitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'shortlisted':
        return AppColors.success;
      case 'declined':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myOpportunitiesProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('My Opportunities',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Applied'), Tab(text: 'Created')],
        ),
      ),
      body: state.isLoading && state.applied.isEmpty && state.created.isEmpty
          ? const GenericListSkeleton()
          : TabBarView(
              controller: _tabs,
              children: [
                RefreshIndicator(
                  onRefresh: () => ref.read(myOpportunitiesProvider.notifier).load(),
                  child: state.applied.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 300,
                            child: Center(child: Text('No applications yet')),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.applied.length,
                          itemBuilder: (context, i) {
                            final a = state.applied[i];
                            return Card(
                              child: ListTile(
                                title: Text('Application #${a.id}',
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                  a.pitch,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(a.status).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(a.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _statusColor(a.status),
                                      )),
                                ),
                                onTap: () => context.push('/opportunity-detail/${a.opportunityId}'),
                              ),
                            );
                          },
                        ),
                ),
                RefreshIndicator(
                  onRefresh: () => ref.read(myOpportunitiesProvider.notifier).load(),
                  child: state.created.isEmpty
                      ? const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 300,
                            child: Center(child: Text('Nothing posted yet')),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.created.length,
                          itemBuilder: (context, i) {
                            final o = state.created[i];
                            return EntityRow(
                              title: o.title,
                              subtitle: '${o.type} · ${o.status}',
                              avatarText: o.title.isNotEmpty ? o.title[0].toUpperCase() : 'O',
                              onTap: () => context.push('/opportunity-detail/${o.id}'),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
