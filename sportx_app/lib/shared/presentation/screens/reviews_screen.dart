import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_cards.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

class ReviewItem {
  final String author;
  final int rating; // 1..5
  final String text;
  final String timeAgo;
  const ReviewItem({
    required this.author,
    required this.rating,
    required this.text,
    required this.timeAgo,
  });
}

/// D.14 Reviews List — average rating, distribution, review cards.
class ReviewsListScreen extends StatelessWidget {
  final String title;
  final double average;
  final List<ReviewItem> reviews;

  const ReviewsListScreen({
    super.key,
    this.title = 'Reviews',
    this.average = 4.6,
    this.reviews = const [],
  });

  @override
  Widget build(BuildContext context) {
    final items = reviews.isEmpty ? _sample : reviews;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: SportXTopBar(title: title, showBack: true),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _summary(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: SecondaryButton(
              label: 'Write a review',
              icon: LucideIcons.penLine,
              onPressed: () => context.push('/write-review',
                  extra: {'title': title}),
            ),
          ),
          const SizedBox(height: 20),
          for (final r in items) _card(r),
        ],
      ),
    );
  }

  Widget _summary() {
    return SportXCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Column(
            children: [
              Text(average.toStringAsFixed(1),
                  style: GoogleFonts.sora(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink)),
              const _Stars(rating: 5, size: 14),
              const SizedBox(height: 4),
              Text('${_sample.length} reviews',
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (var star = 5; star >= 1; star--) _distRow(star),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _distRow(int star) {
    final frac = switch (star) {
      5 => 0.72,
      4 => 0.18,
      3 => 0.06,
      2 => 0.03,
      _ => 0.01,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$star',
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textSecondary)),
          const SizedBox(width: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: frac,
                minHeight: 6,
                backgroundColor: AppColors.surface,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFF5B400)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(ReviewItem r) {
    return SportXCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                      colors: [Color(0xFFFFE9A8), Color(0xFFFFC107)]),
                ),
                alignment: Alignment.center,
                child: Text(
                    r.author.isNotEmpty ? r.author[0].toUpperCase() : '?',
                    style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.author,
                        style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                    _Stars(rating: r.rating, size: 12),
                  ],
                ),
              ),
              Text(r.timeAgo,
                  style: GoogleFonts.inter(
                      fontSize: 11.5, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 10),
          Text(r.text,
              style: GoogleFonts.inter(
                  fontSize: 13.5, height: 1.5, color: AppColors.dark)),
        ],
      ),
    );
  }

  static const _sample = [
    ReviewItem(author: 'Rahul M.', rating: 5, timeAgo: '2d', text: 'Great facilities and coaches. My son improved a lot in 3 months.'),
    ReviewItem(author: 'Priya S.', rating: 4, timeAgo: '1w', text: 'Well organised trials. Communication could be faster.'),
    ReviewItem(author: 'Aman K.', rating: 5, timeAgo: '2w', text: 'Professional staff and a safe environment for kids.'),
  ];
}

/// D.15 Write Review — stars + text (only after a verified interaction).
class WriteReviewScreen extends StatefulWidget {
  final String title;
  const WriteReviewScreen({super.key, this.title = ''});

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 0;
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: const SportXTopBar(title: 'Write a Review', showBack: true),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.title.isNotEmpty)
                Text(widget.title,
                    style: GoogleFonts.sora(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink)),
              const SizedBox(height: 16),
              SportXCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your rating',
                        style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.dark)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        for (var i = 1; i <= 5; i++)
                          GestureDetector(
                            onTap: () => setState(() => _rating = i),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Icon(
                                LucideIcons.star,
                                size: 32,
                                color: i <= _rating
                                    ? AppColors.yellowDeep
                                    : AppColors.border,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _text,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Share your experience',
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: 'Submit review',
                  icon: LucideIcons.check,
                  onPressed: (_rating > 0 && _text.text.trim().isNotEmpty)
                      ? () => context.pop()
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stars extends StatelessWidget {
  final int rating;
  final double size;
  const _Stars({required this.rating, this.size = 12});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            LucideIcons.star,
            size: size,
            color: i <= rating ? AppColors.yellowDeep : AppColors.border,
          ),
      ],
    );
  }
}
