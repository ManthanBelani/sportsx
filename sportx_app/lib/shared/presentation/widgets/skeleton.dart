import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:sportx_app/theme/colors.dart';

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;
  const SkeletonBox({super.key, this.width, required this.height, this.borderRadius = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

class ShimmerSkeleton extends StatelessWidget {
  final Widget child;
  const ShimmerSkeleton({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.border.withValues(alpha: 0.6),
      highlightColor: AppColors.surface,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }
}

class CoachProfileViewSkeleton extends StatelessWidget {
  final bool isTabContent;
  const CoachProfileViewSkeleton({super.key, this.isTabContent = false});

  @override
  Widget build(BuildContext context) {
    final content = SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: ShimmerSkeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Row(children: [
                const SkeletonBox(width: 84, height: 84, borderRadius: 42),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SkeletonBox(width: 140, height: 18, borderRadius: 4),
                    const SizedBox(height: 8),
                    SkeletonBox(width: 100, height: 12, borderRadius: 4),
                    const SizedBox(height: 10),
                    SkeletonBox(width: double.infinity, height: 10, borderRadius: 4),
                    const SizedBox(height: 6),
                    SkeletonBox(width: 160, height: 10, borderRadius: 4),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            _cardSkeleton(lines: 3),
            _cardSkeleton(lines: 5),
            _cardSkeleton(lines: 2),
            _cardSkeleton(lines: 3),
            _cardSkeleton(lines: 4),
          ],
        ),
      ),
    );

    if (isTabContent) {
      return Column(
        children: [
          Container(
            color: AppColors.background,
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: ShimmerSkeleton(
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                SkeletonBox(width: 100, height: 18, borderRadius: 4),
                SkeletonBox(width: 120, height: 36, borderRadius: 8),
              ]),
            ),
          ),
          Expanded(child: content),
        ],
      );
    }
    return content;
  }

  Widget _cardSkeleton({required int lines}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SkeletonBox(width: 120, height: 14, borderRadius: 4),
        const SizedBox(height: 12),
        ...List.generate(lines, (i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SkeletonBox(width: i == lines - 1 ? 180 : double.infinity, height: 12, borderRadius: 4),
            )),
      ]),
    );
  }
}

class CoachDashboardHomeSkeleton extends StatelessWidget {
  const CoachDashboardHomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: ShimmerSkeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const SkeletonBox(width: 56, height: 56, borderRadius: 28),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  SkeletonBox(width: 120, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 160, height: 12, borderRadius: 4),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (i) => Expanded(child: Container(margin: EdgeInsets.only(left: i == 0 ? 0 : 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: const Column(children: [SkeletonBox(width: 40, height: 20, borderRadius: 4), SizedBox(height: 8), SkeletonBox(width: 60, height: 10, borderRadius: 4)]))))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [SkeletonBox(width: 140, height: 14, borderRadius: 4), SkeletonBox(width: 40, height: 14, borderRadius: 4)]),
              const SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 8, borderRadius: 4),
              const SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
              const SizedBox(height: 6),
              SkeletonBox(width: 200, height: 12, borderRadius: 4),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 120, height: 14, borderRadius: 4),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(4, (_) => const Column(children: [SkeletonBox(width: 48, height: 48, borderRadius: 8), SizedBox(height: 6), SkeletonBox(width: 40, height: 10, borderRadius: 4)]))),
            ]),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [SkeletonBox(width: 130, height: 14, borderRadius: 4), SkeletonBox(width: 60, height: 12, borderRadius: 4)]),
              const SizedBox(height: 12),
              ...List.generate(3, (_) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [const SkeletonBox(width: 44, height: 44, borderRadius: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: double.infinity, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 180, height: 10, borderRadius: 4)]))]))),
            ]),
          ),
        ]),
      ),
    );
  }
}

class CoachDashboardScheduleSkeleton extends StatelessWidget {
  const CoachDashboardScheduleSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: ShimmerSkeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)),
            child: Column(children: [
              Row(children: [const SkeletonBox(width: 40, height: 40, borderRadius: 8), const SizedBox(width: 12), Expanded(child: SkeletonBox(width: double.infinity, height: 14, borderRadius: 4))]),
              const SizedBox(height: 12),
              SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
              const SizedBox(height: 6),
              SkeletonBox(width: 220, height: 12, borderRadius: 4),
            ]),
          ),
          const SizedBox(height: 24),
          SkeletonBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          ...List.generate(3, (_) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Row(children: [const SkeletonBox(width: 44, height: 44, borderRadius: 8), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 140, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 180, height: 10, borderRadius: 4)]))]))),
        ]),
      ),
    );
  }
}

class CoachEditFormSkeleton extends StatelessWidget {
  const CoachEditFormSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: ShimmerSkeleton(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [const SkeletonBox(width: 80, height: 80, borderRadius: 40), const SizedBox(width: 16), SkeletonBox(width: 120, height: 36, borderRadius: 8)]),
          const SizedBox(height: 24),
          SkeletonBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 16),
          Row(children: const [Expanded(child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8)), SizedBox(width: 12), Expanded(child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8))]),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 24),
          SkeletonBox(width: 160, height: 16, borderRadius: 4),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 16),
          Row(children: const [Expanded(child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8)), SizedBox(width: 12), Expanded(child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8))]),
          const SizedBox(height: 20),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => Padding(padding: const EdgeInsets.only(bottom: 16), child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 8))),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 8),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
        ]),
      ),
    );
  }
}

class CoachEnquiryListSkeleton extends StatelessWidget {
  const CoachEnquiryListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 6,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [SkeletonBox(width: 110, height: 14, borderRadius: 4), const SizedBox(width: 8), SkeletonBox(width: 50, height: 18, borderRadius: 4)]),
                const SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
                const SizedBox(height: 8),
                Row(children: [SkeletonBox(width: 60, height: 10, borderRadius: 4), const Spacer(), SkeletonBox(width: 70, height: 10, borderRadius: 4)]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}

class CoachEnquiryDetailSkeleton extends StatelessWidget {
  const CoachEnquiryDetailSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(padding: const EdgeInsets.all(20), children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
          child: Row(children: [const SkeletonBox(width: 56, height: 56, borderRadius: 28), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 130, height: 14, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 90, height: 10, borderRadius: 4)]))]),
        ),
        const SizedBox(height: 20),
        Row(children: List.generate(4, (i) => Container(margin: EdgeInsets.only(right: i == 3 ? 0 : 8), child: SkeletonBox(width: 110, height: 36, borderRadius: 20)))),
        const SizedBox(height: 20),
        ...List.generate(3, (_) => Align(alignment: Alignment.centerLeft, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 220, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 180, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 70, height: 10, borderRadius: 4)])))),
      ]),
    );
  }
}

class MediaGallerySkeleton extends StatelessWidget {
  const MediaGallerySkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Column(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 20), decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))), child: Row(children: List.generate(3, (_) => Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16), child: SkeletonBox(width: 90, height: 14, borderRadius: 4))))),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 4, crossAxisSpacing: 4),
            itemCount: 9,
            itemBuilder: (_, _) => const SkeletonBox(width: double.infinity, height: 100, borderRadius: 8),
          ),
        ),
      ]),
    );
  }
}

class AddAchievementSkeleton extends StatelessWidget {
  const AddAchievementSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView(padding: const EdgeInsets.all(16), children: [
        SkeletonBox(width: 200, height: 12, borderRadius: 4),
        const SizedBox(height: 24),
        SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
        const SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 100, borderRadius: 8),
        const SizedBox(height: 16),
        SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
        const SizedBox(height: 24),
        SkeletonBox(width: 140, height: 16, borderRadius: 4),
        const SizedBox(height: 12),
        SkeletonBox(width: double.infinity, height: 150, borderRadius: 12),
        const SizedBox(height: 32),
        SkeletonBox(width: double.infinity, height: 50, borderRadius: 8),
      ]),
    );
  }
}

class FacilitiesSkeleton extends StatelessWidget {
  const FacilitiesSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 2,
        itemBuilder: (_, _) => Container(margin: const EdgeInsets.only(bottom: 16), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [SkeletonBox(width: 100, height: 14, borderRadius: 4), SkeletonBox(width: 24, height: 24, borderRadius: 12)]), const SizedBox(height: 16), SkeletonBox(width: double.infinity, height: 48, borderRadius: 8), const SizedBox(height: 16), SkeletonBox(width: double.infinity, height: 80, borderRadius: 8), const SizedBox(height: 16), SkeletonBox(width: double.infinity, height: 48, borderRadius: 8)])),
      ),
    );
  }
}

class ShowcaseSkeleton extends StatelessWidget {
  const ShowcaseSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: SkeletonBox(width: double.infinity, height: 48, borderRadius: 12)),
        SizedBox(height: 70, child: ListView.separated(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 5, separatorBuilder: (_, _) => const SizedBox(width: 12), itemBuilder: (_, _) => const Column(children: [SkeletonBox(width: 60, height: 60, borderRadius: 30), SizedBox(height: 6), SkeletonBox(width: 50, height: 10, borderRadius: 4)]))),
        const SizedBox(height: 16),
        Expanded(child: ListView.separated(padding: const EdgeInsets.symmetric(horizontal: 16), itemCount: 5, separatorBuilder: (_, _) => const SizedBox(height: 8), itemBuilder: (_, _) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)), child: Row(children: [const SkeletonBox(width: 44, height: 44, borderRadius: 22), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 120, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 80, height: 10, borderRadius: 4)]))])))),
      ]),
    );
  }
}

// ── Generic app-wide skeletons ──

class GenericListSkeleton extends StatelessWidget {
  final int itemCount;
  const GenericListSkeleton({super.key, this.itemCount = 6});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: itemCount,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBox(width: 64, height: 64, borderRadius: 8),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 140, height: 14, borderRadius: 4),
              const SizedBox(height: 8),
              SkeletonBox(width: double.infinity, height: 12, borderRadius: 4),
              const SizedBox(height: 6),
              SkeletonBox(width: 180, height: 12, borderRadius: 4),
              const SizedBox(height: 8),
              Row(children: [SkeletonBox(width: 60, height: 20, borderRadius: 20), const SizedBox(width: 8), SkeletonBox(width: 60, height: 20, borderRadius: 20)]),
            ])),
          ]),
        ),
      ),
    );
  }
}

class GenericGridSkeleton extends StatelessWidget {
  final int itemCount;
  const GenericGridSkeleton({super.key, this.itemCount = 6});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.85),
        itemCount: itemCount,
        itemBuilder: (_, _) => Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SkeletonBox(width: double.infinity, height: 110, borderRadius: 12),
            Padding(padding: const EdgeInsets.all(10), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 110, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 80, height: 10, borderRadius: 4), const SizedBox(height: 8), SkeletonBox(width: 60, height: 20, borderRadius: 20)])),
          ]),
        ),
      ),
    );
  }
}

class GenericDetailSkeleton extends StatelessWidget {
  const GenericDetailSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SkeletonBox(width: double.infinity, height: 180, borderRadius: 12),
          const SizedBox(height: 16),
          SkeletonBox(width: 180, height: 18, borderRadius: 4),
          const SizedBox(height: 8),
          SkeletonBox(width: 120, height: 12, borderRadius: 4),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (_) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.border)), child: Column(children: [SkeletonBox(width: 24, height: 24, borderRadius: 12), const SizedBox(height: 6), SkeletonBox(width: 40, height: 10, borderRadius: 4)]))))),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 80, borderRadius: 8),
          const SizedBox(height: 16),
          SkeletonBox(width: 140, height: 14, borderRadius: 4),
          const SizedBox(height: 8),
          ...List.generate(3, (_) => Padding(padding: const EdgeInsets.only(bottom: 8), child: SkeletonBox(width: double.infinity, height: 12, borderRadius: 4))),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 48, borderRadius: 8),
        ]),
      ),
    );
  }
}

class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: double.infinity, height: 160, borderRadius: 12),
          const SizedBox(height: 16),
          SkeletonBox(width: 140, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          SizedBox(height: 110, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: 4, separatorBuilder: (_, _) => const SizedBox(width: 12), itemBuilder: (_, _) => const SkeletonBox(width: 140, height: 110, borderRadius: 12))),
          const SizedBox(height: 16),
          SkeletonBox(width: 120, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          const GenericListSkeleton(itemCount: 3),
        ]),
      ),
    );
  }
}

class NotificationsSkeleton extends StatelessWidget {
  const NotificationsSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 8,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: double.infinity, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 180, height: 10, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 80, height: 10, borderRadius: 4)])),
          ]),
        ),
      ),
    );
  }
}

class ConnectionsSkeleton extends StatelessWidget {
  const ConnectionsSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, _) => Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const SkeletonBox(width: 48, height: 48, borderRadius: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [SkeletonBox(width: 120, height: 14, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 160, height: 10, borderRadius: 4)])),
            const SkeletonBox(width: 70, height: 32, borderRadius: 8),
          ]),
        ),
      ),
    );
  }
}

class ChatListSkeleton extends StatelessWidget {
  const ChatListSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 7,
        separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.border),
        itemBuilder: (_, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(children: [const SkeletonBox(width: 48, height: 48, borderRadius: 24), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [SkeletonBox(width: 100, height: 12, borderRadius: 4), SkeletonBox(width: 50, height: 10, borderRadius: 4)]), const SizedBox(height: 6), SkeletonBox(width: double.infinity, height: 10, borderRadius: 4)]))]),
        ),
      ),
    );
  }
}

class DiscoverSkeleton extends StatelessWidget {
  const DiscoverSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: Column(children: [
        Padding(padding: const EdgeInsets.all(16), child: SkeletonBox(width: double.infinity, height: 44, borderRadius: 12)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: List.generate(3, (_) => Container(margin: const EdgeInsets.only(right: 8), child: SkeletonBox(width: 80, height: 32, borderRadius: 20))))),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: List.generate(4, (_) => Container(margin: const EdgeInsets.only(right: 8), child: SkeletonBox(width: 70, height: 28, borderRadius: 20))))),
        const SizedBox(height: 12),
        const Expanded(child: GenericGridSkeleton(itemCount: 6)),
      ]),
    );
  }
}

class SponsorDashboardSkeleton extends StatelessWidget {
  const SponsorDashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SkeletonBox(width: double.infinity, height: 120, borderRadius: 12),
          const SizedBox(height: 16),
          Row(children: List.generate(3, (_) => Expanded(child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)), child: Column(children: [SkeletonBox(width: 40, height: 20, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 70, height: 10, borderRadius: 4)]))))),
          const SizedBox(height: 16),
          SkeletonBox(width: double.infinity, height: 80, borderRadius: 12),
          const SizedBox(height: 16),
          SkeletonBox(width: 150, height: 16, borderRadius: 4),
          const SizedBox(height: 12),
          const GenericListSkeleton(itemCount: 3),
        ]),
      ),
    );
  }
}

class ScoutDashboardSkeleton extends StatelessWidget {
  const ScoutDashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Welcome banner: avatar box + two text lines
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Row(children: [
              const SkeletonBox(width: 56, height: 56, borderRadius: 8),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SkeletonBox(width: 140, height: 16, borderRadius: 4),
                  const SizedBox(height: 8),
                  SkeletonBox(width: 180, height: 12, borderRadius: 4),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          // Profile completeness meter
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const SkeletonBox(width: 130, height: 12, borderRadius: 4),
                const SkeletonBox(width: 36, height: 12, borderRadius: 4),
              ]),
              const SizedBox(height: 8),
              const SkeletonBox(width: double.infinity, height: 6, borderRadius: 4),
            ]),
          ),
          const SizedBox(height: 16),
          // Stats row: Shortlisted / Connections / Pending
          Row(children: List.generate(3, (_) => Expanded(child: Container(margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)), child: Column(children: [SkeletonBox(width: 32, height: 22, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 64, height: 10, borderRadius: 4)]))))),
          const SizedBox(height: 16),
          // Quick actions: Discover / Shortlist / Connections / Profile
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SkeletonBox(width: 110, height: 14, borderRadius: 4),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: List.generate(4, (_) => Column(children: [SkeletonBox(width: 48, height: 48, borderRadius: 8), const SizedBox(height: 6), SkeletonBox(width: 44, height: 10, borderRadius: 4)]))),
            ]),
          ),
          const SizedBox(height: 16),
          // Recent shortlist
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: Column(children: List.generate(2, (_) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(children: [const SkeletonBox(width: 40, height: 40, borderRadius: 20), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SkeletonBox(width: 120, height: 12, borderRadius: 4), const SizedBox(height: 6), SkeletonBox(width: 80, height: 10, borderRadius: 4)]))])))),
          ),
        ]),
      ),
    );
  }
}
