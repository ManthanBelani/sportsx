import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class CoachProfileDetailScreen extends ConsumerStatefulWidget {
  final String coachId;

  const CoachProfileDetailScreen({super.key, required this.coachId});

  @override
  ConsumerState<CoachProfileDetailScreen> createState() => _CoachProfileDetailScreenState();
}

class _CoachProfileDetailScreenState extends ConsumerState<CoachProfileDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _coachData;

  @override
  void initState() {
    super.initState();
    _loadCoachData();
  }

  Future<void> _loadCoachData() async {
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/coaches/${widget.coachId}');
      if (mounted) {
        setState(() {
          _coachData = response.data['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // Use mock data on error
        _coachData = {
          'full_name': 'Rahul Mehta',
          'profile_photo_url': 'https://i.pravatar.cc/150?img=10',
          'specialization': 'Cricket',
          'experience': 8,
          'bio': 'Passionate cricket coach with 8 years of experience training young athletes. Specialized in batting technique and mental conditioning.',
          'contact_number': '+91 9876543210',
          'email': 'rahul@coach.com',
          'hourly_rate': 800,
          'city': {'name': 'Ahmedabad'},
          'is_verified': true,
          'credentials': [
            {'title': 'BCCI Level 2 Certificate', 'year': '2020'},
            {'title': 'Sports Science Diploma', 'year': '2019'},
          ],
          'facilities': [
            {'name': 'Indoor Cricket Nets', 'type': 'facility'},
            {'name': 'Weekend Training Camp', 'type': 'program'},
          ],
          'showcase_athletes': [
            {'name': 'Rohit Sharma', 'profile_photo_url': 'https://i.pravatar.cc/150?img=3'},
            {'name': 'Priya Patel', 'profile_photo_url': 'https://i.pravatar.cc/150?img=5'},
            {'name': 'Akash Kumar', 'profile_photo_url': 'https://i.pravatar.cc/150?img=8'},
          ],
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _coachData == null
              ? const Center(child: Text('Coach not found'))
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildProfileInfo(),
                          const SizedBox(height: 24),
                          _buildStatsRow(),
                          const SizedBox(height: 24),
                          _buildAboutSection(),
                          const SizedBox(height: 24),
                          _buildCredentialsSection(),
                          const SizedBox(height: 24),
                          _buildFacilitiesSection(),
                          const SizedBox(height: 24),
                          _buildShowcaseAthletesSection(),
                          const SizedBox(height: 24),
                          _buildContactSection(),
                          const SizedBox(height: 24),
                          _buildShareProfileButton(),
                          const SizedBox(height: 100),
                        ]),
                      ),
                    ),
                  ],
                ),
      bottomSheet: _coachData != null ? _buildBottomCTA() : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              'https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=400&fit=crop',
              fit: BoxFit.cover,
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _coachData!['profile_photo_url'] != null
                        ? NetworkImage(_coachData!['profile_photo_url'])
                        : null,
                    backgroundColor: AppColors.surface,
                    child: _coachData!['profile_photo_url'] == null
                        ? const Icon(Icons.person, size: 40, color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              _coachData!['full_name'] ?? 'Coach',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_coachData!['is_verified'] == true) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.verified, color: AppColors.primary, size: 20),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_coachData!['specialization'] ?? "Cricket"} · ${_coachData!['city']?['name'] ?? "India"}',
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border, color: Colors.white),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildProfileInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.work_outline, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '${_coachData!['experience'] ?? 0} years experience',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(width: 16),
            Icon(Icons.payments_outlined, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(
              '₹${_coachData!['hourly_rate'] ?? 0}/hour',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatItem('12', 'Credentials', Icons.verified_outlined),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('5', 'Facilities', Icons.business_outlined),
          Container(width: 1, height: 32, color: AppColors.border),
          _buildStatItem('8', 'Athletes', Icons.people_outline),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Text(
          _coachData!['bio'] ?? 'No bio available.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildCredentialsSection() {
    final credentials = _coachData!['credentials'] as List? ?? [];
    if (credentials.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Credentials', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ...credentials.map((credential) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified, color: AppColors.success, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          credential['title'] ?? '',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          credential['year'] ?? '',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildFacilitiesSection() {
    final facilities = _coachData!['facilities'] as List? ?? [];
    if (facilities.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Facilities & Programs', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: facilities.map((facility) {
            final isProgram = facility['type'] == 'program';
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isProgram ? AppColors.infoLight : AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isProgram ? AppColors.primary : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isProgram ? Icons.calendar_today : Icons.business,
                    size: 16,
                    color: isProgram ? AppColors.primary : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    facility['name'] ?? '',
                    style: TextStyle(
                      color: isProgram ? AppColors.primary : AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildShowcaseAthletesSection() {
    final athletes = _coachData!['showcase_athletes'] as List? ?? [];
    if (athletes.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Associated Athletes', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () {},
              child: const Text('See all →'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: athletes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final athlete = athletes[index];
              return Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: athlete['profile_photo_url'] != null
                        ? NetworkImage(athlete['profile_photo_url'])
                        : null,
                    backgroundColor: AppColors.surface,
                    child: athlete['profile_photo_url'] == null
                        ? const Icon(Icons.person, color: AppColors.textTertiary)
                        : null,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    athlete['name'] ?? 'Athlete',
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Contact Information', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (_coachData!['contact_number'] != null)
          _buildContactItem(
            icon: Icons.phone_outlined,
            label: _coachData!['contact_number'],
            onTap: () {},
          ),
        if (_coachData!['email'] != null)
          _buildContactItem(
            icon: Icons.email_outlined,
            label: _coachData!['email'],
            onTap: () {},
          ),
      ],
    );
  }

  Widget _buildContactItem({
    required IconData icon,
    required String? label,
    required VoidCallback onTap,
  }) {
    if (label == null) return const SizedBox.shrink();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.infoLight,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 22),
      ),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
      onTap: onTap,
    );
  }

  Widget _buildShareProfileButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Share.share(
            'Check out this coach on SportX India!\nhttps://sportx.in/coach/${widget.coachId}',
          );
        },
        icon: const Icon(Icons.share_outlined),
        label: const Text('Share Profile'),
      ),
    );
  }

  Widget _buildBottomCTA() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: FilledButton(
            onPressed: () {
              context.push('/enquire/${_coachData!['full_name'] ?? 'Coach'}');
            },
            child: const Text('Enquire / Book'),
          ),
        ),
      ),
    );
  }
}
