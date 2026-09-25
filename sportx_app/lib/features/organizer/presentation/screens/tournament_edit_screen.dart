import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class CategoryEditRow {
  int? id;
  TextEditingController name = TextEditingController();
  TextEditingController capacity = TextEditingController(text: '16');
  int? ageGroupId;
  void dispose() { name.dispose(); capacity.dispose(); }
}

class TournamentEditScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const TournamentEditScreen({super.key, required this.tournamentId});
  @override
  ConsumerState<TournamentEditScreen> createState() => _TournamentEditScreenState();
}

class _TournamentEditScreenState extends ConsumerState<TournamentEditScreen> {
  final _name = TextEditingController();
  final _venue = TextEditingController();
  final _description = TextEditingController();
  final _prizePool = TextEditingController();
  final _entryFee = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _deadline = TextEditingController();
  int? _sportId;
  int? _cityId;
  String _format = 'knockout';
  String _gender = 'mixed';
  String _status = 'draft';
  bool _loading = true;
  bool _saving = false;
  final List<CategoryEditRow> _categories = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose(); _venue.dispose(); _description.dispose(); _prizePool.dispose();
    _entryFee.dispose(); _startDate.dispose(); _endDate.dispose(); _deadline.dispose();
    for (final c in _categories) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final resp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}');
      final data = resp.data is Map && resp.data['data'] is Map ? resp.data['data'] as Map : resp.data as Map;
      _name.text = (data['name'] ?? data['title'] ?? '').toString();
      _venue.text = (data['venue'] ?? '').toString();
      _description.text = (data['rules'] ?? data['description'] ?? '').toString();
      _prizePool.text = (data['prize_pool'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '');
      _entryFee.text = (data['entry_fee'] ?? '').toString();
      _sportId = (data['sport_id'] ?? data['sport']?['id']) as int?;
      _cityId = (data['city_id'] ?? data['city']?['id']) as int?;
      _format = (data['format'] ?? 'knockout').toString();
      _gender = (data['gender'] ?? 'mixed').toString();
      _status = (data['status'] ?? 'draft').toString();
      _startDate.text = (data['start_date'] ?? '').toString().split('T').first;
      _endDate.text = (data['end_date'] ?? '').toString().split('T').first;
      _deadline.text = (data['registration_deadline'] ?? '').toString().split('T').first.replaceAll('null', '');

      // categories via capacity endpoint for accurate capacity
      try {
        final capResp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}/capacity');
        final raw = capResp.data;
        List list = raw is Map && raw['data'] is List ? raw['data'] as List : [];
        for (final e in list) {
          final m = e as Map;
          final row = CategoryEditRow();
          row.id = (m['category_id'] ?? m['id']) as int?;
          row.name.text = (m['category_name'] ?? m['name'] ?? '').toString();
          row.capacity.text = (m['max_teams'] ?? m['capacity'] ?? 16).toString();
          row.ageGroupId = m['age_group_id'] as int?;
          _categories.add(row);
        }
      } catch (_) {}
      if (_categories.isEmpty) {
        _categories.add(CategoryEditRow()..name.text = 'Open');
      }
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        SnackBarUtils.showError(context, e);
      }
    }
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (d != null) ctrl.text = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _venue.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Name and venue required');
      return;
    }
    setState(() => _saving = true);
    try {
      final payload = {
        'name': _name.text.trim(),
        if (_sportId != null) 'sport_id': _sportId,
        if (_cityId != null) 'city_id': _cityId,
        'venue': _venue.text.trim(),
        'format': _format,
        'gender': _gender,
        if (_startDate.text.trim().isNotEmpty) 'start_date': _startDate.text.trim(),
        if (_endDate.text.trim().isNotEmpty) 'end_date': _endDate.text.trim(),
        'registration_deadline': _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
        if (_entryFee.text.trim().isNotEmpty) 'entry_fee': num.tryParse(_entryFee.text.replaceAll(RegExp(r'[₹, ]'), '')) ?? 0,
        if (_prizePool.text.trim().isNotEmpty) 'prize_pool': _prizePool.text.trim(),
        'rules': _description.text.trim().isEmpty ? null : _description.text.trim(),
      };
      await ref.read(dioProvider).put('/me/tournaments/${widget.tournamentId}', data: payload);

      // update categories
      final cats = _categories.where((c) => c.name.text.trim().isNotEmpty).map((c) => {
            if (c.id != null) 'id': c.id,
            'name': c.name.text.trim(),
            if (c.ageGroupId != null) 'age_group_id': c.ageGroupId,
            'capacity': int.tryParse(c.capacity.text) ?? 16,
            'waitlist_enabled': true,
          }).toList();
      if (cats.isNotEmpty) {
        await ref.read(dioProvider).put('/me/tournaments/${widget.tournamentId}/categories', data: {'categories': cats});
      }
      ref.invalidate(myTournamentsProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Tournament updated');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _changeStatus(String action) async {
    setState(() => _saving = true);
    try {
      if (action == 'publish') {
        await ref.read(providerTournamentActionsProvider).publish(widget.tournamentId);
      } else if (action == 'close') {
        await ref.read(providerTournamentActionsProvider).close(widget.tournamentId);
      }
      if (mounted) {
        SnackBarUtils.showSuccess(context, action == 'publish' ? 'Published' : 'Closed');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    if (_loading) {
      return Scaffold(appBar: AppBar(title: const Text('Edit Tournament')), body: const Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Edit Tournament', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'publish' || v == 'close') _changeStatus(v);
            },
            itemBuilder: (_) => [
              if (_status == 'draft') const PopupMenuItem(value: 'publish', child: Text('Publish')),
              if (_status == 'published') const PopupMenuItem(value: 'close', child: Text('Close Tournament')),
            ],
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _label('Tournament Name'), TextField(controller: _name, decoration: const InputDecoration(hintText: 'Name')),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Sport'), DropdownButtonFormField<int>(initialValue: _sportId, hint: const Text('Select'), items: meta.sports.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(), onChanged: (v) => setState(() => _sportId = v), decoration: const InputDecoration())])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('City'), DropdownButtonFormField<int>(initialValue: _cityId, hint: const Text('Select city'), items: meta.cities.take(50).map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(), onChanged: (v) => setState(() => _cityId = v), decoration: const InputDecoration())])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Format'), DropdownButtonFormField<String>(initialValue: _format, items: const [DropdownMenuItem(value: 'knockout', child: Text('Knockout')), DropdownMenuItem(value: 'league', child: Text('League')), DropdownMenuItem(value: 'round-robin', child: Text('Round Robin'))], onChanged: (v) => setState(() => _format = v ?? 'knockout'), decoration: const InputDecoration())])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Gender'), DropdownButtonFormField<String>(initialValue: _gender, items: const [DropdownMenuItem(value: 'mixed', child: Text('Mixed')), DropdownMenuItem(value: 'male', child: Text('Male')), DropdownMenuItem(value: 'female', child: Text('Female'))], onChanged: (v) => setState(() => _gender = v ?? 'mixed'), decoration: const InputDecoration())])),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Start Date'), TextField(controller: _startDate, readOnly: true, onTap: () => _pickDate(_startDate), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18)))])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('End Date'), TextField(controller: _endDate, readOnly: true, onTap: () => _pickDate(_endDate), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18)))])),
          ]),
          const SizedBox(height: 12),
          _label('Venue'), TextField(controller: _venue, decoration: const InputDecoration(hintText: 'Kanteerava Stadium')),
          const SizedBox(height: 12),
          _label('Registration Deadline'), TextField(controller: _deadline, readOnly: true, onTap: () => _pickDate(_deadline), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Entry Fee'), TextField(controller: _entryFee, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ '))])),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_label('Prize Pool'), TextField(controller: _prizePool, decoration: const InputDecoration(prefixText: '₹ '))])),
          ]),
          const SizedBox(height: 12),
          _label('Description / Rules'), TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(hintText: 'Rules, eligibility...')),
          const SizedBox(height: 16),
          _label('Categories'),
          ..._categories.asMap().entries.map((e) {
            final i = e.key; final cat = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                Expanded(flex: 2, child: TextField(controller: cat.name, decoration: const InputDecoration(hintText: 'Category'))),
                const SizedBox(width: 8),
                Expanded(flex: 2, child: DropdownButtonFormField<int>(initialValue: cat.ageGroupId, hint: const Text('Age group', style: TextStyle(fontSize: 12)), items: meta.ageGroups.map((ag) => DropdownMenuItem(value: ag.id, child: Text(ag.label, style: const TextStyle(fontSize: 12)))).toList(), onChanged: (v) => setState(() => cat.ageGroupId = v), decoration: const InputDecoration(isDense: true))),
                const SizedBox(width: 8),
                SizedBox(width: 80, child: TextField(controller: cat.capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Cap'))),
                const SizedBox(width: 8),
                InkWell(onTap: _categories.length > 1 ? () { setState(() => _categories.removeAt(i)); } : null, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16)), child: const Icon(LucideIcons.x, size: 14))),
              ]),
            );
          }),
          InkWell(onTap: () => setState(() => _categories.add(CategoryEditRow())), child:  Row(children: [Icon(LucideIcons.plus, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('+ Add Category', style: GoogleFonts.inter(color: AppColors.primary, fontSize: 14))])),
          const SizedBox(height: 24),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(label: 'Save Changes', icon: LucideIcons.check, onPressed: _saving ? null : _save),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(child: StatusPill(label: 'Status: $_status', kind: _status == 'published' ? PillKind.ok : PillKind.draft)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));
}
