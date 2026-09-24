import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Regression test for RenderFlex overflows on narrow devices with
/// enlarged text. Pumps the shared v2 kit grids/cards that previously
/// clipped by a few pixels. In flutter_test, layout overflows surface
/// as FlutterError failures.
void main() {
  Future<void> pumpNarrow(WidgetTester tester, Widget body) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(
            size: Size(320, 600),
            textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          home: Scaffold(
            backgroundColor: AppColors.surface,
            body: SingleChildScrollView(child: body),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  }

  testWidgets('QuickTile grid does not overflow at 320dp + 1.3x text',
      (tester) async {
    await pumpNarrow(
      tester,
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
        children: const [
          QuickTile(
              label: 'Scholarships',
              icon: LucideIcons.graduationCap,
              tintBg: AppColors.yellowTint,
              tintFg: AppColors.warnText),
          QuickTile(
              label: 'Tournaments',
              icon: LucideIcons.medal,
              tintBg: AppColors.infoLight,
              tintFg: AppColors.info),
        ],
      ),
    );
  });

  testWidgets('OppCard + EntityRow + StatusPill do not overflow',
      (tester) async {
    await pumpNarrow(
      tester,
      const Column(
        children: [
          OppCard(title: 'State Level Football Trial', org: 'GFA'),
          EntityRow(
              title: 'XSports India',
              subtitle: 'Kit · ₹50k · U-19',
              avatarText: 'X'),
          StatusPill(label: 'Under Review', kind: PillKind.pending),
        ],
      ),
    );
  });

  testWidgets('Dashboard quick action tiles do not overflow',
      (tester) async {
    await pumpNarrow(
      tester,
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.3,
        children: const [
          QuickTile(
              label: 'Discover', icon: LucideIcons.search, tintBg: AppColors.infoLight, tintFg: AppColors.scout),
          QuickTile(
              label: 'Shortlist', icon: LucideIcons.star, tintBg: AppColors.yellowTint, tintFg: AppColors.warnText),
          QuickTile(
              label: 'Connections', icon: LucideIcons.users, tintBg: AppColors.successLight, tintFg: Color(0xFF15803D)),
          QuickTile(
              label: 'Profile', icon: LucideIcons.user, tintBg: Color(0xFFF1F3F5), tintFg: AppColors.dark),
        ],
      ),
    );
  });

  testWidgets('DetailPageTemplate detail grid does not overflow',
      (tester) async {
    await pumpNarrow(
      tester,
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          _detailCell('Venue', 'Sardar Patel Stadium'),
          _detailCell('Date', '15 Oct 2026 · 10:00 AM'),
          _detailCell('Age Group', 'U-19 · Boys & Girls'),
          _detailCell('Fee', '₹200 entry'),
        ],
      ),
    );
  });
}

Widget _detailCell(String label, String value) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.borderSoft),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}
