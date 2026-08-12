import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SponsorDirectoryCoachScreen extends ConsumerStatefulWidget {
  const SponsorDirectoryCoachScreen({super.key});

  @override
  ConsumerState<SponsorDirectoryCoachScreen> createState() => _SponsorDirectoryCoachScreenState();
}

class _SponsorDirectoryCoachScreenState extends ConsumerState<SponsorDirectoryCoachScreen> {
  String _selectedIndustry = 'All';
  String? _selectedLocation;
  final _searchController = TextEditingController();

  final List<String> _industries = ['All', 'Sportswear', 'Nutrition', 'Finance', 'Technology', 'Media'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sponsorshipsProvider);
    final sponsors = state.items.where((s) {
      final matchesIndustry = _selectedIndustry == 'All' ||
          (s.sponsorshipType?.toLowerCase().contains(_selectedIndustry.toLowerCase()) ?? false);
      final matchesSearch = _searchController.text.isEmpty ||
          s.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          (s.sponsorName?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
      return matchesIndustry && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Find Sponsorships',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        actions: [
          IconButton(icon: const Icon(LucideIcons.slidersHorizontal, color: AppColors.textPrimary), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Search sponsorships...',
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(LucideIcons.x, size: 18, color: AppColors.textSecondary),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _industries.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final industry = _industries[index];
                final isSelected = _selectedIndustry == industry;
                return FilterChip(
                  label: Text(industry),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedIndustry = industry),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : AppColors.textPrimary),
                  side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
                );
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(sponsorshipsProvider.notifier).refresh(),
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : sponsors.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.briefcase, size: 64, color: AppColors.textTertiary),
                              const SizedBox(height: 16),
                              Text('No sponsorships found',
                                  style: TextStyle(color: AppColors.textSecondary)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sponsors.length,
                          itemBuilder: (context, index) => _buildSponsorCard(sponsors[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(s) {
    return InkWell(
      onTap: () => context.push('/sponsor-pitch/${s.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
              alignment: Alignment.center,
              child: const Icon(LucideIcons.award, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(s.sponsorName ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  if (s.amountLabel != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.ctaLight, borderRadius: BorderRadius.circular(4)),
                      child: Text(s.amountLabel!,
                          style: const TextStyle(color: AppColors.ctaDark, fontSize: 11, fontWeight: FontWeight.w600)),
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
