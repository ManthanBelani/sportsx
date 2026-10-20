import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sportx_app/features/connections/presentation/widgets/connection_requests_view.dart';
import 'package:sportx_app/theme/colors.dart';

/// Standalone page for connection requests. The same content is embedded as
/// the "Requests" tab of the Messages screen (see [ConnectionRequestsView]),
/// so this page is only the deep-link / entry point.
class ConnectionRequestsScreen extends StatelessWidget {
  const ConnectionRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text('Connection Requests',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: const ConnectionRequestsView(),
    );
  }
}
