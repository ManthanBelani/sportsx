import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/connections/presentation/widgets/scout_requests_view.dart';
import 'package:sportx_app/theme/colors.dart';

/// Standalone page for incoming talent-scout requests. The same content is
/// shown as a tab inside the Messages screen (see [ScoutRequestsView]), so
/// this page only exists as the deep-link / notification entry point.
class ScoutRequestsScreen extends StatelessWidget {
  const ScoutRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Scout Requests',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: const ScoutRequestsView(),
    );
  }
}
