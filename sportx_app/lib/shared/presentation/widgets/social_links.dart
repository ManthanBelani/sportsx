import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/models/social_links.dart';
import 'package:sportx_app/theme/colors.dart';

/// Open a social URL in the external app/browser.
Future<void> launchSocialUrl(BuildContext context, String url) async {
  var value = url.trim();
  if (!RegExp(r'^[a-z][a-z0-9+.-]*://', caseSensitive: false).hasMatch(value)) {
    value = 'https://$value';
  }
  final uri = Uri.tryParse(value);
  if (uri == null) {
    SnackBarUtils.showError(context, 'Invalid link');
    return;
  }
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) SnackBarUtils.showError(context, 'Could not open link');
}

/// Row of tappable social icons. Renders nothing when [links] is empty.
class SocialLinksRow extends StatelessWidget {
  final Map<String, String> links;
  final double iconSize;

  const SocialLinksRow({super.key, required this.links, this.iconSize = 20});

  @override
  Widget build(BuildContext context) {
    final entries = kSocialPlatforms.where((p) => (links[p.key] ?? '').isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: entries.map((p) {
        return Semantics(
          label: 'Open ${p.label}',
          button: true,
          child: InkWell(
            onTap: () => launchSocialUrl(context, links[p.key]!),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.infoLight,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(p.icon, color: AppColors.primary, size: iconSize),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Titled section wrapper for profile screens. Renders nothing when empty.
class SocialLinksSection extends StatelessWidget {
  final Map<String, dynamic>? profile;
  final String title;

  const SocialLinksSection({super.key, required this.profile, this.title = 'Social Links'});

  @override
  Widget build(BuildContext context) {
    final links = socialLinksOf(profile);
    if (links.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        SocialLinksRow(links: links),
        const SizedBox(height: 24),
      ],
    );
  }
}

/// Reusable editor used by the universal Social Links screen (all roles).
class SocialLinksEditor extends StatefulWidget {
  final Map<String, String> initial;
  final bool saving;
  final Future<void> Function(Map<String, String>) onSave;

  const SocialLinksEditor({super.key, required this.initial, required this.saving, required this.onSave});

  @override
  State<SocialLinksEditor> createState() => _SocialLinksEditorState();
}

class _SocialLinksEditorState extends State<SocialLinksEditor> {
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _controllers = {for (final p in kSocialPlatforms) p.key: TextEditingController(text: widget.initial[p.key] ?? '')};
  }

  @override
  void didUpdateWidget(SocialLinksEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial && !widget.saving) {
      for (final p in kSocialPlatforms) {
        final v = widget.initial[p.key] ?? '';
        if (_controllers[p.key]!.text != v) _controllers[p.key]!.text = v;
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final p in kSocialPlatforms) ...[
          TextField(
            controller: _controllers[p.key],
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: p.label,
              hintText: p.hint,
              prefixIcon: Icon(p.icon, size: 18, color: AppColors.textSecondary),
              suffixIcon: _controllers[p.key]!.text.isNotEmpty
                  ? null
                  : const Icon(LucideIcons.plus, size: 16, color: AppColors.textTertiary),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: widget.saving
                ? null
                : () {
                    final links = <String, String>{};
                    for (final p in kSocialPlatforms) {
                      final v = _controllers[p.key]!.text.trim();
                      if (v.isNotEmpty) links[p.key] = v;
                    }
                    widget.onSave(links);
                  },
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            icon: widget.saving
                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(LucideIcons.check, size: 18),
            label: Text(widget.saving ? 'Saving…' : 'Save Links'),
          ),
        ),
      ],
    );
  }
}
