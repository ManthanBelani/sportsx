import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// AD.6 Record Edit — add/edit/delete a platform record (content manager).
class AdminRecordEditScreen extends StatefulWidget {
  final String recordType;
  final Map<String, dynamic>? initial;

  const AdminRecordEditScreen({
    super.key,
    this.recordType = 'Record',
    this.initial,
  });

  @override
  State<AdminRecordEditScreen> createState() => _AdminRecordEditScreenState();
}

class _AdminRecordEditScreenState extends State<AdminRecordEditScreen> {
  late final TextEditingController _title;
  late final TextEditingController _owner;
  late final TextEditingController _description;
  String _status = 'Active';

  static const _statuses = ['Active', 'Draft', 'Suspended', 'Expired', 'Archived'];

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?['title'] as String? ?? '');
    _owner = TextEditingController(text: i?['owner'] as String? ?? '');
    _description =
        TextEditingController(text: i?['description'] as String? ?? '');
  }

  @override
  void dispose() {
    _title.dispose();
    _owner.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(
        title: widget.initial == null
            ? 'Add ${widget.recordType}'
            : 'Edit ${widget.recordType}',
        showBack: true,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  SportXCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: _title,
                          decoration: const InputDecoration(labelText: 'Title'),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _owner,
                          decoration: const InputDecoration(
                              labelText: 'Owner / provider'),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration:
                              const InputDecoration(labelText: 'Status'),
                          items: _statuses
                              .map((s) =>
                                  DropdownMenuItem(value: s, child: Text(s)))
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _status = v ?? _status),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _description,
                          maxLines: 4,
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              alignLabelWithHint: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Row(
                children: [
                  if (widget.initial != null)
                    Expanded(
                      child: SecondaryButton(
                        label: 'Delete',
                        icon: LucideIcons.trash2,
                        onPressed: () {
                          SnackBarUtils.showSuccess(
                              context, 'Record deleted');
                          Navigator.of(context).maybePop();
                        },
                      ),
                    ),
                  if (widget.initial != null) const SizedBox(width: 10),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Save',
                      icon: LucideIcons.check,
                      onPressed: () {
                        SnackBarUtils.showSuccess(context, 'Record saved');
                        Navigator.of(context).maybePop();
                      },
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
}
