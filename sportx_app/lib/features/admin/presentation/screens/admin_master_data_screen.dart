import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// AD.9 Category / Master Manager — editable master lists.
class AdminMasterDataScreen extends StatefulWidget {
  const AdminMasterDataScreen({super.key});

  @override
  State<AdminMasterDataScreen> createState() => _AdminMasterDataScreenState();
}

class _AdminMasterDataScreenState extends State<AdminMasterDataScreen> {
  int _tab = 0;
  static const _tabs = ['Sports', 'Cities', 'Age groups', 'Positions'];

  final Map<int, List<String>> _data = {
    0: ['Cricket', 'Football', 'Athletics', 'Badminton', 'Basketball'],
    1: ['Ahmedabad', 'Surat', 'Delhi', 'Mumbai', 'Bengaluru'],
    2: ['U-8', 'U-12', 'U-16', 'U-19', 'Senior'],
    3: ['Batsman', 'Bowler', 'Midfielder', 'Goalkeeper', 'Striker'],
  };

  Future<void> _add() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Add to ${_tabs[_tab]}',
            style: GoogleFonts.sora(
                fontSize: 16, fontWeight: FontWeight.w700)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (value != null && value.isNotEmpty) {
      setState(() => _data[_tab]!.add(value));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _data[_tab]!;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Master Data', showBack: true),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.yellow,
        foregroundColor: AppColors.ink,
        onPressed: _add,
        icon: const Icon(LucideIcons.plus),
        label: Text('Add',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
        children: [
          SegmentTabs(
            tabs: _tabs,
            selectedIndex: _tab,
            onSelect: (i) => setState(() => _tab = i),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < items.length; i++) _row(items, i),
        ],
      ),
    );
  }

  Widget _row(List<String> items, int index) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          const Icon(LucideIcons.tag, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(items[index],
                style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink)),
          ),
          IconButton(
            onPressed: () => setState(() => _data[_tab]!.removeAt(index)),
            icon: const Icon(LucideIcons.trash2,
                size: 17, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
