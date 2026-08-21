import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/async_state_view.dart';
import 'package:sportx_app/shared/presentation/widgets/detail_page_template.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class CoachDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const CoachDetailScreen({super.key, required this.id});

  @override
  ConsumerState<CoachDetailScreen> createState() => _CoachDetailScreenState();
}

class _CoachDetailScreenState extends ConsumerState<CoachDetailScreen> {
  String _connectionStatus = 'none';
  bool _isConnecting = false;
  bool _connectionLoaded = false;

  Future<void> _handleConnect(Coach c) async {
    if (_connectionStatus == 'pending' || _connectionStatus == 'accepted') return;

    setState(() => _isConnecting = true);

    try {
      final dio = ref.read(dioProvider);
      await dio.post('/me/connections/request', data: {'user_id': c.userId});
      if (mounted) {
        setState(() => _connectionStatus = 'pending');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connection request sent!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send connection request')),
        );
      }
    } finally {
      if (mounted) setState(() => _isConnecting = false);
    }
  }

  Future<void> _loadConnectionStatus(Coach c) async {
    if (_connectionLoaded) return;
    _connectionLoaded = true;

    try {
      final resp = await ref.read(dioProvider).get('/me/connections/status/${c.userId}');
      if (mounted) {
        setState(() {
          _connectionStatus = resp.data['data']['status'] ?? 'none';
        });
      }
    } catch (e) {
      // Stay with 'none' status
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(coachDetailProvider(widget.id));

    return AsyncDetailBuilder<Coach>(
      async: async,
      title: 'Coach',
      onRetry: () => ref.invalidate(coachDetailProvider(widget.id)),
      dataBuilder: (c) {
        _loadConnectionStatus(c);

        final isPending = _connectionStatus == 'pending';
        final isConnected = _connectionStatus == 'accepted';
        final connectLabel = isPending ? 'Pending' : isConnected ? 'Connected' : 'Connect';

        return DetailPageTemplate(
          heroIcon: LucideIcons.user,
          heroImageUrl: c.profilePhotoUrl,
          title: c.fullName,
          subtitle: c.city?.name ?? '',
          rating: null,
          reviewsCount: null,
          tags: [c.sport?.name, c.specialization].whereType<String>().toList(),
          details: {
            if (c.experience != null) 'Experience': '${c.experience} years',
            if (c.sport?.name != null) 'Sport': c.sport!.name,
            if (c.specialization != null) 'Specialization': c.specialization!,
            if (c.hourlyRate != null) 'Fees': '₹${c.hourlyRate!.toStringAsFixed(0)}/session',
            if (c.contactNumber != null) 'Contact': c.contactNumber!,
          },
          addressStr: c.city?.name ?? '',
          ctaText: 'Enquire / Book',
          onCtaPressed: () => context.push('/enquire/coach_profile/${c.id}/${Uri.encodeComponent(c.fullName)}'),
          onPhonePressed: c.contactNumber == null ? null : () => launchUrl(Uri.parse('tel:${c.contactNumber}')),
          secondaryCtaText: connectLabel,
          onSecondaryCtaPressed: (isPending || isConnected) ? null : () => _handleConnect(c),
          isSecondaryCtaLoading: _isConnecting,
          savedType: 'coach_profile',
          savedItemId: c.id.toString(),
        );
      },
    );
  }
}
