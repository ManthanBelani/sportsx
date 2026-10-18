import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';

/// Reusable bottom sheets: Filter & Sort (S.4) and Report (S.26).

class FilterChipGroup {
  final String title;
  final List<String> options;
  const FilterChipGroup({required this.title, required this.options});
}

class FilterSelection {
  /// group title -> selected options
  final Map<String, Set<String>> values;
  final String? sort;
  const FilterSelection({required this.values, this.sort});

  bool get isEmpty =>
      sort == null && values.values.every((s) => s.isEmpty);
}

/// Shows the reusable Filter & Sort sheet. Returns null if dismissed,
/// otherwise the [FilterSelection].
Future<FilterSelection?> showFilterSheet(
  BuildContext context, {
  String title = 'Filter & Sort',
  required List<FilterChipGroup> groups,
  List<String> sortOptions = const ['Relevant', 'Nearest', 'Rating'],
  FilterSelection initial = const FilterSelection(values: {}),
}) {
  return showModalBottomSheet<FilterSelection>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(
      title: title,
      groups: groups,
      sortOptions: sortOptions,
      initial: initial,
    ),
  );
}

class _FilterSheet extends StatefulWidget {
  final String title;
  final List<FilterChipGroup> groups;
  final List<String> sortOptions;
  final FilterSelection initial;

  const _FilterSheet({
    required this.title,
    required this.groups,
    required this.sortOptions,
    required this.initial,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final Map<String, Set<String>> _values;
  String? _sort;

  @override
  void initState() {
    super.initState();
    _values = {
      for (final g in widget.groups) g.title: {...?widget.initial.values[g.title]},
    };
    _sort = widget.initial.sort;
  }

  void _toggle(String group, String option) {
    setState(() {
      final set = _values.putIfAbsent(group, () => <String>{});
      if (!set.remove(option)) set.add(option);
    });
  }

  void _reset() {
    setState(() {
      for (final g in widget.groups) {
        _values[g.title] = <String>{};
      }
      _sort = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                child: Row(
                  children: [
                    Text(widget.title,
                        style: GoogleFonts.sora(
                            fontSize: 19,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    const Spacer(),
                    TextButton(
                      onPressed: _reset,
                      child: Text('Reset',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: [
                    for (final g in widget.groups) ...[
                      Text(g.title,
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark)),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final o in g.options)
                            SportXChip(
                              label: o,
                              selected: _values[g.title]?.contains(o) ?? false,
                              onTap: () => _toggle(g.title, o),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],
                    if (widget.sortOptions.isNotEmpty) ...[
                      Text('Sort by',
                          style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.dark)),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final s in widget.sortOptions)
                            SportXChip(
                              label: s,
                              selected: _sort == s,
                              onTap: () =>
                                  setState(() => _sort = _sort == s ? null : s),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'Apply Filters',
                      icon: LucideIcons.check,
                      onPressed: () => Navigator.pop(
                        context,
                        FilterSelection(values: _values, sort: _sort),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReportSubmission {
  final String reason;
  final String notes;
  const ReportSubmission({required this.reason, required this.notes});
}

const List<String> kReportReasons = [
  'Spam or misleading',
  'Harassment or bullying',
  'Inappropriate content',
  'Fake profile',
  'Copyright violation',
  'Something else',
];

/// Shows the reusable Report sheet (S.26). Returns null if dismissed.
Future<ReportSubmission?> showReportSheet(
  BuildContext context, {
  String targetTitle = '',
}) {
  return showModalBottomSheet<ReportSubmission>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(targetTitle: targetTitle),
  );
}

class _ReportSheet extends StatefulWidget {
  final String targetTitle;
  const _ReportSheet({required this.targetTitle});

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  String? _reason;
  final _notes = TextEditingController();

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 14),
          Text('Report',
              style: GoogleFonts.sora(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (widget.targetTitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(widget.targetTitle,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 14),
          Text('Reason',
              style: GoogleFonts.inter(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in kReportReasons)
                SportXChip(
                  label: r,
                  selected: _reason == r,
                  onTap: () => setState(() => _reason = r),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _notes,
            maxLines: 3,
            style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Add any details (optional)',
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              label: 'Submit Report',
              icon: LucideIcons.flag,
              onPressed: _reason == null
                  ? null
                  : () => Navigator.pop(
                        context,
                        ReportSubmission(
                            reason: _reason!, notes: _notes.text.trim()),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

/// S.30 Share sheet. Returns the chosen channel key ('copy', 'whatsapp',
/// 'more'), or null if dismissed. The caller performs the actual share.
Future<String?> showShareSheet(
  BuildContext context, {
  String title = 'Share',
  String? subtitle,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(99)),
            ),
          ),
          const SizedBox(height: 14),
          Text(title,
              style: GoogleFonts.sora(
                  fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _shareOption(context, LucideIcons.link, 'Copy link', 'copy'),
              const SizedBox(width: 18),
              _shareOption(context, LucideIcons.messageCircle, 'WhatsApp', 'whatsapp'),
              const SizedBox(width: 18),
              _shareOption(context, LucideIcons.share2, 'More', 'more'),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _shareOption(
    BuildContext context, IconData icon, String label, String key) {
  return Expanded(
    child: GestureDetector(
      onTap: () => Navigator.pop(context, key),
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                shape: BoxShape.circle, color: AppColors.surface),
            alignment: Alignment.center,
            child: Icon(icon, size: 22, color: AppColors.dark),
          ),
          const SizedBox(height: 8),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    ),
  );
}

/// Upload tile for media grids (S.10 / profile gallery).
class MediaUploadTile extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final bool isUploading;
  final double progress; // 0..1

  const MediaUploadTile({
    super.key,
    required this.onTap,
    this.label = 'Upload',
    this.isUploading = false,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border, style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
        ),
        alignment: Alignment.center,
        child: isUploading
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      value: progress > 0 ? progress : null,
                      color: AppColors.yellowDeep,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).round()}%',
                      style: GoogleFonts.inter(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.imagePlus,
                      size: 26, color: AppColors.textSecondary),
                  const SizedBox(height: 7),
                  Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ],
              ),
      ),
    );
  }
}
