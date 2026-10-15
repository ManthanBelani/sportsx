import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Opportunity list D.9 (Phase 4): v3 mockup-style image cards with
/// pill CTA, date/location rows, and type chips (Trials / Tournaments /
/// Scholarships / Sponsorships).
class OpportunityListScreen extends ConsumerStatefulWidget {
  const OpportunityListScreen({super.key});

  @override
  ConsumerState<OpportunityListScreen> createState() => _OpportunityListScreenState();
}

class _OpportunityListScreenState extends ConsumerState<OpportunityListScreen> {
  String? _typeFilter;

  static const _types = ['scholarship', 'sponsorship', 'tryout', 'camp'];

  String _label(String type) {
    switch (type) {
      case 'scholarship':
        return 'Scholarships';
      case 'sponsorship':
        return 'Sponsorships';
      case 'tryout':
        return 'Trials';
      case 'camp':
        return 'Camps';
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  String _shortDate(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

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
            style: GoogleFonts.sora(
                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
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
                    color: AppColors.yellowDeep,
                    onRefresh: () =>
                        ref.read(opportunitiesProvider.notifier).refresh(),
                    child: items.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 220),
                              Center(child: Text('No opportunities found')),
                            ],
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                            itemCount: items.length,
                            itemBuilder: (context, i) =>
                                _OpportunityCard(
                              opportunity: items[i],
                              onTap: () => context.push(
                                  '/opportunity-detail/${items[i].id}'),
                              shortDate: items[i].deadline == null
                                  ? null
                                  : _shortDate(items[i].deadline!),
                            ),
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
            color: selected ? AppColors.ink : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.ink : AppColors.border,
            ),
          ),
          child: Text(label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.yellow : AppColors.textPrimary,
              )),
        ),
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final dynamic opportunity;
  final VoidCallback onTap;
  final String? shortDate;
  const _OpportunityCard({
    required this.opportunity,
    required this.onTap,
    required this.shortDate,
  });

  IconData get _typeIcon {
    switch ((opportunity.type as String? ?? '').toLowerCase()) {
      case 'scholarship':
        return LucideIcons.graduationCap;
      case 'sponsorship':
        return LucideIcons.handshake;
      case 'tryout':
        return LucideIcons.trophy;
      case 'camp':
        return LucideIcons.dumbbell;
      default:
        return LucideIcons.trophy;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sportName = opportunity.sport?.name as String?;
    final title = opportunity.title as String;
    final typeLabel = (opportunity.type as String? ?? '').isEmpty
        ? 'Opportunity'
        : ((opportunity.type as String)[0].toUpperCase() +
            (opportunity.type as String).substring(1));
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(16),
            boxShadow: SportXShadows.e1,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.yellowSoft,
                        AppColors.yellowTint,
                      ],
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -12,
                        bottom: -8,
                        child: Icon(
                          _typeIcon,
                          size: 100,
                          color: AppColors.yellowDeep.withValues(alpha: 0.35),
                        ),
                      ),
                      Positioned(
                        left: 14,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.ink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            typeLabel.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.yellow,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.sora(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    if (shortDate != null || sportName != null) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        children: [
                          if (shortDate != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.calendar,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(shortDate!,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                          if (sportName != null)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(LucideIcons.medal,
                                    size: 13,
                                    color: AppColors.textSecondary),
                                const SizedBox(width: 4),
                                Text(sportName,
                                    style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                              ],
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.yellow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'Apply Now',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
