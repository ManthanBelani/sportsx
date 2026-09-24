import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/date_format_utils.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

class CapacityManagementScreen extends ConsumerStatefulWidget {
  final String tournamentId;
  const CapacityManagementScreen({super.key, required this.tournamentId});

  @override
  ConsumerState<CapacityManagementScreen> createState() => _CapacityManagementScreenState();
}

class _CapCategory {
  int id;
  String name;
  int maxTeams;
  int registered;
  bool waitlistEnabled;
  _CapCategory({required this.id, required this.name, required this.maxTeams, required this.registered, this.waitlistEnabled=true});
}

class _CapacityManagementScreenState extends ConsumerState<CapacityManagementScreen> {
  List<_CapCategory> _cats = [];
  bool _loading = true;
  bool _saving = false;
  String? _tournamentName;
  String? _dateStr;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.tournamentId.isEmpty) { setState(()=> _loading=false); return; }
    try {
      final resp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}/capacity');
      final raw = resp.data;
      List data;
      if (raw is Map && raw['data'] is List) {
        data = raw['data'] as List;
      } else if (raw is List) {
        data = raw;
      } else {
        data = [];
      }

      // also fetch tournament detail for header
      try {
        final tResp = await ref.read(dioProvider).get('/tournaments/${widget.tournamentId}');
        final tData = tResp.data is Map && tResp.data['data'] is Map ? tResp.data['data'] as Map : tResp.data as Map;
        _tournamentName = (tData['name'] ?? tData['title'])?.toString();
        _dateStr = DateFormatUtils.formatShortDate(tData['start_date']?.toString());
      } catch (_) {}

      setState(() {
        _cats = data.map((e){
          final m = e as Map;
          return _CapCategory(
            id: (m['category_id'] ?? m['id']) as int,
            name: (m['category_name'] ?? m['name'] ?? 'Category').toString(),
            maxTeams: (m['max_teams'] as int?) ?? 16,
            registered: (m['registered'] as int?) ?? 0,
            waitlistEnabled: (m['waitlist_enabled'] as bool?) ?? true,
          );
        }).toList();
        _loading = false;
      });
    } catch (e) {
      setState(()=> _loading=false);
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to load capacity. Please check your connection and try again.');
    }
  }

  Future<void> _save() async {
    setState(()=> _saving=true);
    try {
      // Single atomic call: capacity + waitlist via /me/tournaments/{id}/categories (handles both)
      await ref.read(dioProvider).put('/me/tournaments/${widget.tournamentId}/categories', data: {
        'categories': _cats.map((c)=> {'id': c.id, 'name': c.name, 'capacity': c.maxTeams, 'waitlist_enabled': c.waitlistEnabled}).toList(),
      });
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Capacity saved');
        context.pop();
      }
    } catch (e) {
      // Fallback to legacy capacity endpoint if categories update fails
      try {
        await ref.read(dioProvider).put('/tournaments/${widget.tournamentId}/capacity', data: {
          'categories': _cats.map((c)=> {'id': c.id, 'max_teams': c.maxTeams}).toList(),
        });
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'Capacity saved');
          context.pop();
        }
      } catch (e2) {
        if (mounted) SnackBarUtils.showError(context, e2, 'Failed to update capacity. Please try again.');
      }
    } finally {
      if (mounted) setState(()=> _saving=false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        scrolledUnderElevation: 0,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: ()=> context.pop()),
        title: Text('Manage Capacity', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _saving || _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryDarker))
                  : PrimaryButton(small: true, label: 'Save', icon: LucideIcons.check, onPressed: _save),
            ),
          ),
        ],
        bottom: PreferredSize(preferredSize: const Size.fromHeight(1), child: Container(height: 1, color: AppColors.border)),
      ),
      body: _loading
          ? const GenericListSkeleton()
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Tournament header card per design
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                    Text(_tournamentName ?? 'Tournament', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text(_dateStr ?? 'Dates pending', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                  ]),
                ),
                const SizedBox(height: 16),
                if (_cats.isEmpty)
                   Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('No categories found', style: GoogleFonts.inter(color: AppColors.textSecondary))))
                else
                  ..._cats.map((cat)=> Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
                        Text('${cat.name} Category', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        const SizedBox(height: 12),
                        Row(children: [
                          const Text('Spots', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(trackHeight: 6, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10), activeTrackColor: AppColors.primary, inactiveTrackColor: AppColors.border),
                              child: Slider(min: 0, max: 32, divisions: 32, value: cat.maxTeams.toDouble().clamp(0,32), onChanged: (v)=> setState(()=> cat.maxTeams=v.toInt())),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('${cat.registered}/${cat.maxTeams}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                        ]),
                        const SizedBox(height: 10),
                        Container(height: 1, color: AppColors.border),
                        const SizedBox(height: 10),
                        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children:[
                          const Text('Enable waitlist when full', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          GestureDetector(
                            onTap: ()=> setState(()=> cat.waitlistEnabled=!cat.waitlistEnabled),
                            child: Container(
                              width: 44, height: 24,
                              decoration: BoxDecoration(color: cat.waitlistEnabled? AppColors.primary: AppColors.border, borderRadius: BorderRadius.circular(16)),
                              alignment: cat.waitlistEnabled? Alignment.centerRight: Alignment.centerLeft,
                              padding: const EdgeInsets.all(2),
                              child: Container(width:20,height:20, decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: AppColors.border), boxShadow: SportXShadows.e1)),
                            ),
                          ),
                        ]),
                      ]),
                    ),
                  )),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(16)),
                  child: const Text('Changes will be reflected immediately. Teams on waitlist will be notified automatically when spots open up.', style: TextStyle(fontSize: 13, color: AppColors.primary)),
                ),
              ],
            ),
    );
  }
}