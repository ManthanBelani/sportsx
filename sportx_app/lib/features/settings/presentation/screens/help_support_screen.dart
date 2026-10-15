import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/theme/colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _expandedIndex;

  final List<Map<String, String>> _faqs = [
    {
      'question': 'How do I register for a trial?',
      'answer': 'Browse trials from the Trials tab, tap on any trial to view details, then tap "Register Now" to fill in your details and submit your registration.'
    },
    {
      'question': 'How do I create a profile?',
      'answer': 'Go to Profile tab after signing up, tap "Edit Profile", and fill in your details including sport(s), achievements, and upload photos to your gallery.'
    },
    {
      'question': 'How do I enquire with a coach?',
      'answer': 'Visit any coach\'s profile and tap "Send Enquiry". Fill in your message and preferred training slots, then submit. The coach will reply within 24-48 hours.'
    },
    {
      'question': 'Are the trials free?',
      'answer': 'Trial fees vary by organizer. Some are free, others charge a nominal entry fee (₹100-₹500). Fee details are clearly mentioned on each trial\'s detail page.'
    },
    {
      'question': 'How do I apply for scholarships and sponsorships?',
      'answer': 'Open Opportunities from Home to browse scholarships, sponsorships, tryouts and camps. Tap any listing to check eligibility, then apply in the app with a short pitch. You can track everything under My Opportunities.'
    },
    {
      'question': 'How do I delete my account?',
      'answer': 'Go to Settings > Delete Account. Note that this action is permanent and will remove all your data including profile, registrations, and saved items.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: Text('Help & Support',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  icon: Icon(LucideIcons.search, size: 20, color: AppColors.textSecondary),
                  hintText: 'Search for help...',
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Frequently Asked Questions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            
            // FAQs
            ...List.generate(_faqs.length, (index) {
              final faq = _faqs[index];
              final isOpen = _expandedIndex == index;
              return Container(
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      faq['question']!,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                    ),
                    trailing: Icon(
                      isOpen ? LucideIcons.minus : LucideIcons.plus,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onExpansionChanged: (expanded) {
                      setState(() {
                        _expandedIndex = expanded ? index : null;
                      });
                    },
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          faq['answer']!,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 24),
            // Contact Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  const Text('Still need help?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  const Text(
                    'Found something inappropriate? Use the Report option on any listing, post or profile — our team reviews every report.',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
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
