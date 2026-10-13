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

/// Coach/academy program management (Phase 5): Active / Drafts / Past tabs.
class MyProgramsScreen extends ConsumerStatefulWidget {
  const MyProgramsScreen({super.key});

  @override
  ConsumerState<MyProgramsScreen> createState() => _MyProgramsScreenState();
}

class _MyProgramsScreenState extends ConsumerState<MyProgramsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  static const _statuses = ['active', 'draft', 'past'];
  static const _labels = ['Active', 'Drafts', 'Past'];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (!_tabs.indexIsChanging) {
        ref.read(myProgramsProvider.notifier).load(status: _statuses[_tabs.index]);
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(myProgramsProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('My Programs',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.plus, color: AppColors.textPrimary),
            onPressed: () => context.push('/post-program'),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: _labels.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: state.isLoading && state.items.isEmpty
          ? const GenericListSkeleton()
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(myProgramsProvider.notifier)
                  .load(status: _statuses[_tabs.index]),
              child: state.items.isEmpty
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: 300,
                        child: Center(child: Text('Nothing here yet')),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.items.length,
                      itemBuilder: (context, i) {
                        final p = state.items[i];
                        return EntityRow(
                          title: p.title,
                          subtitle: '${p.mode} · ${p.priceLabel}',
                          avatarText: p.title.isNotEmpty ? p.title[0].toUpperCase() : 'P',
                          onTap: () => context.push('/program-detail/${p.id}'),
                        );
                      },
                    ),
            ),
    );
  }
}

/// Program create form (coach/academy).
class PostProgramScreen extends ConsumerStatefulWidget {
  const PostProgramScreen({super.key});

  @override
  ConsumerState<PostProgramScreen> createState() => _PostProgramScreenState();
}

class _PostProgramScreenState extends ConsumerState<PostProgramScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _duration = TextEditingController();
  final _price = TextEditingController();
  final _schedule = TextEditingController();
  final _about = TextEditingController();
  String _mode = 'offline';
  bool _active = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    _price.dispose();
    _schedule.dispose();
    _about.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'title': _title.text.trim(),
        'duration': _duration.text.trim(),
        'mode': _mode,
        'schedule': _schedule.text.trim(),
        'about': _about.text.trim(),
        'status': _active ? 'active' : 'draft',
      };
      if (_price.text.trim().isNotEmpty) payload['price'] = double.tryParse(_price.text.trim());
      final ok = await ref.read(myProgramsProvider.notifier).save(payload);
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Program saved!');
        ref.invalidate(programsProvider);
        context.pop();
      } else {
        SnackBarUtils.showError(
          context,
          ref.read(myProgramsProvider).error ?? 'Failed to save',
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
        title: Text('New Program',
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
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _mode,
                      decoration: const InputDecoration(labelText: 'Mode'),
                      items: const ['online', 'offline', 'hybrid']
                          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                          .toList(),
                      onChanged: (v) => setState(() => _mode = v ?? 'offline'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _duration,
                      decoration: const InputDecoration(labelText: 'Duration (e.g. 12 weeks)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹, optional)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _schedule,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Schedule'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _about,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'About the program'),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active (visible to athletes)'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: 16),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(label: 'Save Program', icon: LucideIcons.check, onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
