import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/theme/colors.dart';

class SponsorDirectoryCoachScreen extends StatefulWidget {
  const SponsorDirectoryCoachScreen({super.key});

  @override
  State<SponsorDirectoryCoachScreen> createState() => _SponsorDirectoryCoachScreenState();
}

class _SponsorDirectoryCoachScreenState extends State<SponsorDirectoryCoachScreen> {
  String _selectedIndustry = 'All';
  String? _selectedLocation;
  final _searchController = TextEditingController();

  final List<String> _industries = ['All', 'Sportswear', 'Nutrition', 'Finance', 'Technology', 'Media'];

  // Mock sponsors data
  final List<Map<String, dynamic>> _sponsors = [
    {
      'id': '1',
      'name': 'Nike India',
      'industry': 'Sportswear',
      'location': 'Mumbai',
      'logoUrl': 'https://picsum.photos/200/200?random=1',
      'investmentRange': '₹5L - ₹25L',
      'sports': ['Cricket', 'Football', 'Athletics'],
    },
    {
      'id': '2',
      'name': 'HealthFirst Nutrition',
      'industry': 'Nutrition',
      'location': 'Delhi',
      'logoUrl': 'https://picsum.photos/200/200?random=2',
      'investmentRange': '₹1L - ₹10L',
      'sports': ['All Sports'],
    },
    {
      'id': '3',
      'name': 'SportZone',
      'industry': 'Sportswear',
      'location': 'Ahmedabad',
      'logoUrl': 'https://picsum.photos/200/200?random=3',
      'investmentRange': '₹2L - ₹15L',
      'sports': ['Cricket', 'Badminton'],
    },
    {
      'id': '4',
      'name': 'FitLife Supplements',
      'industry': 'Nutrition',
      'location': 'Bangalore',
      'logoUrl': 'https://picsum.photos/200/200?random=4',
      'investmentRange': '₹50K - ₹5L',
      'sports': ['Fitness', 'Bodybuilding'],
    },
    {
      'id': '5',
      'name': 'SportTech Solutions',
      'industry': 'Technology',
      'location': 'Pune',
      'logoUrl': 'https://picsum.photos/200/200?random=5',
      'investmentRange': '₹10L - ₹50L',
      'sports': ['Cricket', 'Tennis'],
    },
    {
      'id': '6',
      'name': 'SportsVenture Capital',
      'industry': 'Finance',
      'location': 'Mumbai',
      'logoUrl': 'https://picsum.photos/200/200?random=6',
      'investmentRange': '₹25L - ₹1Cr',
      'sports': ['All Sports'],
    },
  ];

  List<Map<String, dynamic>> get _filteredSponsors {
    return _sponsors.where((sponsor) {
      final matchesIndustry = _selectedIndustry == 'All' || sponsor['industry'] == _selectedIndustry;
      final matchesLocation = _selectedLocation == null || sponsor['location'] == _selectedLocation;
      final matchesSearch = _searchController.text.isEmpty ||
          sponsor['name'].toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesIndustry && matchesLocation && matchesSearch;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Sponsors'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
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
                hintText: 'Search sponsors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
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
                  onSelected: (_) {
                    setState(() => _selectedIndustry = industry);
                  },
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                );
              },
            ),
          ),
          if (_selectedLocation != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _selectedLocation!,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _selectedLocation = null),
                    child: const Icon(Icons.close, size: 16, color: AppColors.error),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _filteredSponsors.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.business_center_outlined, size: 64, color: AppColors.textTertiary),
                        const SizedBox(height: 16),
                        Text(
                          'No sponsors found',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _filteredSponsors.length,
                    itemBuilder: (context, index) {
                      final sponsor = _filteredSponsors[index];
                      return _buildSponsorCard(sponsor);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorCard(Map<String, dynamic> sponsor) {
    return InkWell(
      onTap: () => context.push('/sponsor-pitch/${sponsor['id']}'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                image: DecorationImage(
                  image: NetworkImage(sponsor['logoUrl']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sponsor['name'],
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sponsor['industry'],
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          sponsor['location'],
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ctaLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sponsor['investmentRange'],
                      style: TextStyle(
                        color: AppColors.ctaDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLocation,
              decoration: const InputDecoration(labelText: 'Location'),
              items: const [
                DropdownMenuItem(value: 'Mumbai', child: Text('Mumbai')),
                DropdownMenuItem(value: 'Delhi', child: Text('Delhi')),
                DropdownMenuItem(value: 'Ahmedabad', child: Text('Ahmedabad')),
                DropdownMenuItem(value: 'Bangalore', child: Text('Bangalore')),
                DropdownMenuItem(value: 'Pune', child: Text('Pune')),
              ],
              onChanged: (value) {
                setState(() => _selectedLocation = value);
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Apply Filters'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
