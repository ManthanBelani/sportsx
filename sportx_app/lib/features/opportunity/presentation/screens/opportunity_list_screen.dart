import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Opportunity list D.9 (Phase 4): filter chips by type + directory list.
class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  String? _typeFilter;

  static const _types = ['scholarship', 'sponsorship', 'tryout', 'camp'];

  String _label(String type) => type[0].toUpperCase() + type.substring(1);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(opportunitiesProvider);
    final items = _typeFilter == null
        ? state.items
        : state.items.where((o) => o.type == _typeFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('Opportunities',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
            onPressed: () => context.push('/post-opportunity'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _chip(null, 'All'),
                ..._types.map((t) => _chip(t, _label(t))),
              ],
            ),
          ),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const GenericListSkeleton()
                : RefreshIndicator(
                    onRefresh: () => ref.read(opportunitiesProvider.notifier).refresh(),
                    child: items.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 300,
                              child: Center(child: Text('No opportunities found')),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final o = items[i];
                              return EntityRow(
                                title: o.title,
                                subtitle: [
                                  _label(o.type),
                                  if (o.sport?.name != null) o.sport!.name,
                                ].join(' · '),
                                avatarText: o.title.isNotEmpty ? o.title[0].toUpperCase() : 'O',
                                onTap: () => context.push('/opportunity-detail/${o.id}'),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String? value, String label) {
    final selected = _typeFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _typeFilter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : AppColors.textPrimary,
              )),
        ),
      ),
    );
  }
}
