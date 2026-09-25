import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/theme/design_tokens.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';

/// v2 form page — matches trial-registration.html / tournament-registration.html:
/// surface bg, blurred white topbar (via AppBar), 16px content padding,
/// white auto-fill card (16px radius, e1), v2 checkbox row, floating
/// yellow PrimaryButton. Pure styling — same confirm-gate logic.
class FormPageTemplate extends StatefulWidget {
  final String title;
  final Widget? autoFilledProfile;
  final List<Widget> formFields;
  final String ctaText;
  final VoidCallback onSubmit;
  final String confirmText;

  const FormPageTemplate({
    super.key,
    required this.title,
    this.autoFilledProfile,
    required this.formFields,
    required this.ctaText,
    required this.onSubmit,
    this.confirmText = 'I confirm the details are correct',
  });

  @override
  State<FormPageTemplate> createState() => _FormPageTemplateState();
}

class _FormPageTemplateState extends State<FormPageTemplate> {
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text(widget.title,
            style: GoogleFonts.sora(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: AppColors.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.autoFilledProfile != null) ...[
              Text('Your Profile (auto-filled)',
                  style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: AppColors.dark)),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                      BorderRadius.circular(DesignTokens.radiusMd),
                  border: Border.all(color: AppColors.border),
                  boxShadow: SportXShadows.e1,
                ),
                child: widget.autoFilledProfile!,
              ),
              const SizedBox(height: 20),
            ],

            ...widget.formFields,

            const SizedBox(height: 20),
            GestureDetector(
              onTap: () => setState(() => _confirmed = !_confirmed),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    margin: const EdgeInsets.only(top: 1),
                    decoration: BoxDecoration(
                      gradient: _confirmed
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFD54A),
                                Color(0xFFFFC107)
                              ])
                          : null,
                      color: _confirmed ? null : Colors.white,
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(
                          color: _confirmed
                              ? const Color(0x33785000)
                              : AppColors.border,
                          width: 1.5),
                    ),
                    alignment: Alignment.center,
                    child: _confirmed
                        ? const Icon(Icons.check,
                            size: 15, color: AppColors.ink)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(widget.confirmText,
                        style: GoogleFonts.inter(
                            fontSize: 13.5,
                            color: AppColors.dark,
                            height: 1.5)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.94),
          border: const Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: widget.ctaText,
                  onPressed: _confirmed ? widget.onSubmit : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
