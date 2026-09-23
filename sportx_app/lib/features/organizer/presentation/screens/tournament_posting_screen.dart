import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class TournamentPostingScreen extends ConsumerStatefulWidget {
  const TournamentPostingScreen({super.key});

  @override
  ConsumerState<TournamentPostingScreen> createState() => _TournamentPostingScreenState();
}

class CategoryRow {
  TextEditingController name = TextEditingController();
  TextEditingController capacity = TextEditingController(text: '16');
  int? ageGroupId;
  void dispose() {
    name.dispose();
    capacity.dispose();
  }
}

class _TournamentPostingScreenState extends ConsumerState<TournamentPostingScreen> {
  final _name = TextEditingController(text: '');
  final _venue = TextEditingController();
  final _description = TextEditingController();
  final _prizePool = TextEditingController();
  final _prize1 = TextEditingController();
  final _prize2 = TextEditingController();
  final _prize3 = TextEditingController();
  final _entryFee = TextEditingController();
  final _maxTeams = TextEditingController();
  final _startDate = TextEditingController();
  final _endDate = TextEditingController();
  final _deadline = TextEditingController();

  int? _sportId;
  int? _cityId;
  String _format = 'knockout';
  String _gender = 'mixed';
  bool _saving = false;
  final List<CategoryRow> _categories = [CategoryRow()..name.text='U-16', CategoryRow()..name.text='U-18', CategoryRow()..name.text='Open'];

  @override
  void initState() {
    super.initState();
    _prizePool.text = '300000';
    _prize1.text = '150000';
    _prize2.text = '80000';
    _prize3.text = '40000';
    // default age groups will be filled from meta after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ageGroups = ref.read(metaProvider).ageGroups;
      if (ageGroups.isNotEmpty) {
        for (int i = 0; i < _categories.length && i < ageGroups.length; i++) {
          if (_categories[i].ageGroupId == null) {
            setState(() => _categories[i].ageGroupId = ageGroups[i].id);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _venue.dispose();
    _description.dispose();
    _prizePool.dispose();
    _prize1.dispose();
    _prize2.dispose();
    _prize3.dispose();
    _entryFee.dispose();
    _maxTeams.dispose();
    _startDate.dispose();
    _endDate.dispose();
    _deadline.dispose();
    for (final c in _categories) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(TextEditingController ctrl) async {
    final d = await showDatePicker(context: context, initialDate: DateTime.now().add(const Duration(days: 30)), firstDate: DateTime(2024), lastDate: DateTime(2030));
    if (d != null) ctrl.text = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  Future<void> _submit(String status) async {
    if (_name.text.trim().isEmpty || _venue.text.trim().isEmpty || _startDate.text.trim().isEmpty || _endDate.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please fill required fields: Name, Venue, Start & End Date');
      return;
    }
    if (_sportId == null || _cityId == null) {
      SnackBarUtils.showError(context, 'Please select Sport and City');
      return;
    }
    // Validate categories have age group
    for (final c in _categories) {
      if (c.name.text.trim().isNotEmpty && c.ageGroupId == null) {
        SnackBarUtils.showError(context, 'Please select age group for category "${c.name.text.trim()}"');
        return;
      }
    }
    setState(() => _saving = true);
    try {
      final cleanedCats = <Map<String, dynamic>>[];
      for (final c in _categories) {
        if (c.name.text.trim().isEmpty) continue;
        cleanedCats.add({
          'name': c.name.text.trim(),
          'age_group_id': c.ageGroupId,
          'capacity': int.tryParse(c.capacity.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 16,
          'waitlist_enabled': true,
        });
      }
      if (cleanedCats.isEmpty) {
        SnackBarUtils.showError(context, 'Add at least one category');
        setState(() => _saving = false);
        return;
      }

      final payload = {
        'name': _name.text.trim(),
        'sport_id': _sportId,
        'city_id': _cityId,
        'venue': _venue.text.trim(),
        'format': _format,
        'gender': _gender,
        'start_date': _startDate.text.trim(),
        'end_date': _endDate.text.trim(),
        'registration_deadline': _deadline.text.trim().isEmpty ? null : _deadline.text.trim(),
        'entry_fee': num.tryParse(_entryFee.text.replaceAll(RegExp(r'[₹, ]'), '')) ?? 0,
        'prize_pool': '₹${_prizePool.text.trim()} (1st: ₹${_prize1.text}, 2nd: ₹${_prize2.text}, 3rd: ₹${_prize3.text})',
        'rules': _description.text.trim().isEmpty ? null : _description.text.trim(),
        'status': status,
        'categories': cleanedCats,
      }..removeWhere((k, v) => v == null);

      await ref.read(dioProvider).post('/me/tournaments', data: payload);
      if (!mounted) return;
      SnackBarUtils.showSuccess(context, status == 'published' ? 'Tournament published!' : 'Draft saved!');
      context.pop();
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e is DioException ? ApiException.fromDio(e as DioException) : e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: Text('Create Tournament', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament Details section
            Text('Tournament Details', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            _label('Tournament Name'),
            TextField(controller: _name, decoration: const InputDecoration(hintText: 'State Level Athletics Meet 2025')),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Sport'),
                DropdownButtonFormField<int>(
                  initialValue: _sportId,
                  hint: const Text('Select'),
                  items: meta.sports.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (v)=> setState(()=> _sportId=v),
                  decoration: const InputDecoration(),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Format'),
                DropdownButtonFormField<String>(
                  initialValue: _format,
                  items: const [
                    DropdownMenuItem(value: 'knockout', child: Text('Knockout')),
                    DropdownMenuItem(value: 'league', child: Text('League')),
                    DropdownMenuItem(value: 'round-robin', child: Text('Round Robin')),
                    DropdownMenuItem(value: 'single-elimination', child: Text('Knockout + League')),
                  ],
                  onChanged: (v)=> setState(()=> _format=v??'knockout'),
                  decoration: const InputDecoration(),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            // Gender + City
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                _label('City'),
                DropdownButtonFormField<int>(
                  initialValue: _cityId,
                  hint: const Text('Select city'),
                  items: meta.cities.take(50).map((c)=> DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                  onChanged: (v)=> setState(()=> _cityId=v),
                  decoration: const InputDecoration(),
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('Gender'),
                DropdownButtonFormField<String>(
                  initialValue: _gender,
                  items: const [
                    DropdownMenuItem(value: 'mixed', child: Text('Mixed')),
                    DropdownMenuItem(value: 'male', child: Text('Male')),
                    DropdownMenuItem(value: 'female', child: Text('Female')),
                  ],
                  onChanged: (v)=> setState(()=> _gender=v??'mixed'),
                  decoration: const InputDecoration(),
                ),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                _label('Start Date'),
                TextField(controller: _startDate, readOnly: true, onTap: ()=> _pickDate(_startDate), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18))),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                _label('End Date'),
                TextField(controller: _endDate, readOnly: true, onTap: ()=> _pickDate(_endDate), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18))),
              ])),
            ]),
            const SizedBox(height: 16),
            _label('Venue'),
            TextField(controller: _venue, decoration: const InputDecoration(hintText: 'Kanteerava Stadium, Bangalore')),
            const SizedBox(height: 16),
            _label('Description'),
            TextField(controller: _description, maxLines: 3, decoration: const InputDecoration(hintText: 'Tournament format, rules, eligibility...')),
            const SizedBox(height: 24),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 24),

            // Prize Pool
            Text('Prize Pool', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            _label('Total Prize Pool'),
            TextField(controller: _prizePool, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ ', hintText: '300000')),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[_label('1st Place'), TextField(controller: _prize1, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ '))])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[_label('2nd Place'), TextField(controller: _prize2, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ '))])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[_label('3rd Place'), TextField(controller: _prize3, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ '))])),
            ]),
            const SizedBox(height: 24),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 24),

            // Entry Fee & Categories
            Text('Entry Fee & Categories', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[_label('Entry Fee (per team/individual)'), TextField(controller: _entryFee, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: '₹ ', hintText: '3000'))])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[_label('Default capacity per category'), TextField(controller: _maxTeams, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '16'), onChanged: (v){ final n = int.tryParse(v); if(n!=null){ for(final c in _categories){ if(c.capacity.text.isEmpty || c.capacity.text=='16') c.capacity.text = '$n'; } setState((){}); }})])),
            ]),
            const SizedBox(height: 16),
            _label('Categories (name + age group + capacity)'),
            ..._categories.asMap().entries.map((entry){
              final i = entry.key;
              final cat = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(flex: 2, child: TextField(controller: cat.name, decoration: const InputDecoration(hintText: 'e.g. U-16'))),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: cat.ageGroupId,
                      hint: const Text('Age group', style: TextStyle(fontSize: 12)),
                      items: ref.watch(metaProvider).ageGroups.map((ag) => DropdownMenuItem(value: ag.id, child: Text(ag.label, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => cat.ageGroupId = v),
                      decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(width: 90, child: TextField(controller: cat.capacity, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Capacity'))),
                  const SizedBox(width: 8),
                  InkWell(onTap: _categories.length>1 ? (){ setState(()=> _categories.removeAt(i)); } : null, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)), child: const Icon(LucideIcons.x, size: 14))),
                ]),
              );
            }),
            InkWell(onTap: ()=> setState(()=> _categories.add(CategoryRow())), child: Row(children: const [Icon(LucideIcons.plus, size: 14, color: AppColors.primary), SizedBox(width: 6), Text('+ Add Category', style: TextStyle(color: AppColors.primary, fontSize: 14, fontWeight: FontWeight.w500))])),
            const SizedBox(height: 24),
            Divider(color: AppColors.border, height: 1),
            const SizedBox(height: 24),

            // Registration Deadline
            Text('Registration Deadline', style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            _label('Deadline Date'),
            TextField(controller: _deadline, readOnly: true, onTap: ()=> _pickDate(_deadline), decoration: const InputDecoration(hintText: 'YYYY-MM-DD', suffixIcon: Icon(LucideIcons.calendar, size: 18))),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
        decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: Row(children: [
          Expanded(child: SecondaryButton(label: 'Save as Draft', onPressed: _saving ? null : ()=> _submit('draft'))),
          const SizedBox(width: 12),
          Expanded(child: PrimaryButton(label: 'Publish Tournament', icon: LucideIcons.trophy, onPressed: _saving ? null : ()=> _submit('published'))),
        ]),
      ),
    );
  }

  Widget _label(String t)=> Padding(padding: const EdgeInsets.only(bottom:6), child: Text(t, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));
}
