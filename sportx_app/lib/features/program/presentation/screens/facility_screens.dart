import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/program/presentation/providers/program_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Facility list (Phase 5) with type tabs: All / Grounds / Indoor / Gym / Other.
class FacilityListScreen extends ConsumerStatefulWidget {
  const FacilityListScreen({super.key});

  @override
  ConsumerState<FacilityListScreen> createState() => _FacilityListScreenState();
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.circleAlert, size: 32, color: AppColors.textSecondary),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            SecondaryButton(label: 'Retry', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}

class _FacilityListScreenState extends ConsumerState<FacilityListScreen> {
  String? _typeFilter;

  static const _tabs = {
    null: 'All',
    'ground': 'Grounds',
    'indoor': 'Indoor',
    'gym': 'Gym',
    'other': 'Other',
  };

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(facilitiesProvider);
    final items = _typeFilter == null
        ? state.items
        : state.items.where((f) => f.type == _typeFilter).toList();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Facilities',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
            onPressed: () => context.push('/post-facility'),
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
              children: _tabs.entries.map((e) {
                final selected = _typeFilter == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _typeFilter = e.key),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : Colors.white,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                            color: selected ? AppColors.primary : AppColors.border),
                      ),
                      child: Text(e.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : AppColors.textPrimary,
                          )),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: state.isLoading && state.items.isEmpty
                ? const GenericListSkeleton()
                : state.error != null && state.items.isEmpty
                    // Surface the failure instead of pretending the list is
                    // empty (a 403 used to look like "no venues yet").
                    ? _ErrorState(
                        message: state.error!,
                        onRetry: () => ref.read(facilitiesProvider.notifier).load(),
                      )
                    : RefreshIndicator(
                    onRefresh: () => ref.read(facilitiesProvider.notifier).load(),
                    child: items.isEmpty
                        ? const SingleChildScrollView(
                            physics: AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height: 300,
                              child: Center(child: Text('No facilities yet')),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: items.length,
                            itemBuilder: (context, i) {
                              final f = items[i];
                              return EntityRow(
                                title: f.name,
                                subtitle: [
                                  f.type,
                                  if (f.size != null) f.size!,
                                  if (f.amenities.isNotEmpty) f.amenities.take(3).join(', '),
                                ].join(' · '),
                                avatarText: f.name.isNotEmpty ? f.name[0].toUpperCase() : 'F',
                                trailing: IconButton(
                                  icon: const Icon(LucideIcons.trash2,
                                      color: AppColors.textSecondary, size: 20),
                                  onPressed: () => _delete(f.id.toString()),
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(String id) async {
    final ok = await ref.read(facilitiesProvider.notifier).remove(id);
    if (mounted) {
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Facility deleted');
      } else {
        SnackBarUtils.showError(
          context,
          ref.read(facilitiesProvider).error ?? 'Delete failed',
        );
      }
    }
  }
}

/// Facility create form (academy).
class PostFacilityScreen extends ConsumerStatefulWidget {
  const PostFacilityScreen({super.key});

  @override
  ConsumerState<PostFacilityScreen> createState() => _PostFacilityScreenState();
}

class _PostFacilityScreenState extends ConsumerState<PostFacilityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _size = TextEditingController();
  final _amenities = TextEditingController();
  String _type = 'ground';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _size.dispose();
    _amenities.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final amenities = _amenities.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      final ok = await ref.read(facilitiesProvider.notifier).save({
        'name': _name.text.trim(),
        'type': _type,
        'size': _size.text.trim(),
        'amenities': amenities,
      });
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Facility saved!');
        context.pop();
      } else {
        SnackBarUtils.showError(
          context,
          ref.read(facilitiesProvider).error ?? 'Failed to save',
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
          onPressed: () => context.pop(),
        ),
        title: Text('New Facility',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name (e.g. Main Football Ground)'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const ['ground', 'indoor', 'gym', 'other']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'other'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _size,
                decoration: const InputDecoration(labelText: 'Size (e.g. 100x60 m)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amenities,
                decoration: const InputDecoration(
                    labelText: 'Amenities (comma separated)',
                    hintText: 'Floodlights, Changing Room, First Aid'),
              ),
              const SizedBox(height: 24),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: 'Save Facility', icon: LucideIcons.check, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
