import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class OrganizerOnboardingScreen extends ConsumerStatefulWidget {
  const OrganizerOnboardingScreen({super.key});
  @override
  ConsumerState<OrganizerOnboardingScreen> createState() => _OrganizerOnboardingScreenState();
}

class _OrganizerOnboardingScreenState extends ConsumerState<OrganizerOnboardingScreen> {
  final _name = TextEditingController();
  final _regNo = TextEditingController();
  final _website = TextEditingController();
  String _type = 'State Sports Association';
  bool _saving=false;
  int? _docMediaId;
  String? _docName;

  final _types = [
    'State Sports Association',
    'District Sports Association',
    'Private Sports Club',
    'School/College Sports Dept',
    'Other',
  ];

  String _mapTypeToApi(String ui){
    switch(ui){
      case 'State Sports Association': return 'federation';
      case 'District Sports Association': return 'federation';
      case 'Private Sports Club': return 'club';
      case 'School/College Sports Dept': return 'other';
      default: return 'other';
    }
  }

  @override
  void dispose(){ _name.dispose(); _regNo.dispose(); _website.dispose(); super.dispose(); }

  Future<void> _pickDoc() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'document');
    if (media != null && mounted) {
      setState(() {
        _docMediaId = media.mediaId;
        _docName = media.file.path.split('/').last;
      });
      SnackBarUtils.showSuccess(context, 'Document uploaded');
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty){ SnackBarUtils.showError(context, 'Organization name required'); return; }
    setState(()=> _saving=true);
    try{
      await ref.read(dioProvider).post('/onboarding/organizer', data: {
        'organization_name': _name.text.trim(),
        'org_type': _mapTypeToApi(_type),
        'registration_number': _regNo.text.trim().isEmpty? null: _regNo.text.trim(),
        'website': _website.text.trim().isEmpty? null: _website.text.trim(),
        if (_docMediaId != null) 'verification_doc_media_id': _docMediaId,
      });
      if (mounted){
        await ref.read(authProvider.notifier).refreshUser();
        ref.read(authProvider.notifier).markOnboardingComplete();
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Profile Submitted for Review');
        context.go('/organizer-dashboard');
      }
    } catch(e){
      if (mounted) SnackBarUtils.showError(context, e is DioException ? ApiException.fromDio(e as DioException) : e);
    } finally{ if (mounted) setState(()=> _saving=false); }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(children:[
          // progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20,16,20,0),
            child: Row(children:[
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppColors.cta, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(width:8),
              Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(999)))),
            ]),
          ),
          // header
          Padding(
            padding: const EdgeInsets.fromLTRB(20,16,20,0),
            child: Row(children:[
              InkWell(onTap: ()=> context.pop(), borderRadius: BorderRadius.circular(16), child: Container(width:40,height:40, decoration: BoxDecoration(color: Colors.white, border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(16), boxShadow: SportXShadows.e1), alignment: Alignment.center, child: const Icon(LucideIcons.arrowLeft, size:18, color: AppColors.textPrimary))),
              const SizedBox(width:12),
              Text('Organizer Setup', style: GoogleFonts.sora(fontSize: 19, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ]),
          ),
          Container(margin: const EdgeInsets.only(top:12), height:1, color: AppColors.border),
          Expanded(child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children:[
              Text('Organization Details', style: GoogleFonts.sora(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.ink)),
              const SizedBox(height:6),
              Text('Tell us about your organization', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
              const SizedBox(height:24),
              _label('Organization Name'),
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'e.g. Karnataka State Football Association')),
              const SizedBox(height:16),
              _label('Organization Type'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: _types.map((t)=> DropdownMenuItem(value:t, child: Text(t, style: GoogleFonts.inter(fontSize:14, color: AppColors.textPrimary)))).toList(),
                onChanged: (v)=> setState(()=> _type=v??_type),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height:16),
              _label('Registration Number'),
              TextField(controller: _regNo, decoration: const InputDecoration(hintText: 'e.g. REG/2020/0456')),
              const SizedBox(height:16),
              _label('Website (optional)'),
              TextField(controller: _website, decoration: const InputDecoration(hintText: 'https://')),
              const SizedBox(height:16),
              _label('Verification Documents'),
              InkWell(
                onTap: _pickDoc,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: _docMediaId!=null ? AppColors.ctaDark : AppColors.border, width: _docMediaId!=null?1.5:1.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: SportXShadows.e1,
                  ),
                  child: Column(children:[
                    Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: _docMediaId!=null ? AppColors.successLight : AppColors.yellowTint, borderRadius: BorderRadius.circular(14)), child: Icon(_docMediaId!=null ? LucideIcons.checkCircle : LucideIcons.fileText, color: _docMediaId!=null ? AppColors.success : AppColors.ink, size: 30)),
                    const SizedBox(height:12),
                    Text('Upload registration certificate or\nany government ID for verification', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize:14, color: AppColors.textSecondary)),
                    const SizedBox(height:8),
                    RichText(text: TextSpan(style: GoogleFonts.inter(fontSize:14), children:[
                      TextSpan(text: 'Click to upload', style: GoogleFonts.inter(color: AppColors.primaryDarker, fontWeight: FontWeight.w700)),
                      TextSpan(text: ' or drag and drop', style: GoogleFonts.inter(color: AppColors.textSecondary)),
                    ])),
                    const SizedBox(height:4),
                    Text('PDF, JPG up to 10MB', style: GoogleFonts.inter(fontSize:12, color: AppColors.textSecondary)),
                    if (_docMediaId!=null) Padding(padding: const EdgeInsets.only(top:8), child: Text('✓ ${_docName ?? 'document.pdf'} uploaded', style: GoogleFonts.inter(fontSize:12, color: AppColors.success, fontWeight: FontWeight.w700))),
                  ]),
                ),
              ),
              if (_docMediaId!=null) ...[
                const SizedBox(height:16),
                Center(child: Container(
                  padding: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(999), border: Border.all(color: AppColors.success.withValues(alpha: 0.35))),
                  child: Row(mainAxisSize: MainAxisSize.min, children:[
                    Icon(LucideIcons.checkCircle, size:14, color: AppColors.success),
                    SizedBox(width:6),
                    Text('Documents submitted for verification', style: GoogleFonts.inter(fontSize:13, fontWeight: FontWeight.w600, color: AppColors.success)),
                  ]),
                )),
              ],
              const SizedBox(height:32),
            ]),
          )),
          Container(
            padding: EdgeInsets.fromLTRB(20,16,20,16+MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children:[
              Expanded(child: SecondaryButton(label: 'Back', onPressed: ()=> context.pop())),
              const SizedBox(width:12),
              Expanded(
                child: _saving
                    ? Container(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.primaryLight, AppColors.cta, AppColors.ctaDark],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                          boxShadow: SportXShadows.btnShadow,
                        ),
                        alignment: Alignment.center,
                        child: const SizedBox(height:20,width:20, child: CircularProgressIndicator(strokeWidth:2,color:AppColors.ink)),
                      )
                    : PrimaryButton(label: 'Continue', icon: LucideIcons.arrowRight, onPressed: _submit),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _label(String t)=> Padding(padding: const EdgeInsets.only(bottom:6), child: Text(t, style: GoogleFonts.inter(fontSize:14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)));
}
