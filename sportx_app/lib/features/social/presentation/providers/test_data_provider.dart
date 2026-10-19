import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/features/social/presentation/providers/posts_provider.dart';

/// Test/mock data for development and empty states
final testPostsProvider = Provider<List<SocialPost>>((ref) {
  final now = DateTime.now();
  return [
    SocialPost(
      id: 'test_1',
      authorName: 'Rohit Sharma',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=rohit',
      body: 'Just completed my first marathon! 🏃‍♂️ The training paid off. Thanks to my coach @coach_patel for the guidance.',
      imageUrl: 'https://picsum.photos/seed/marathon1/800/450',
      createdAt: now.subtract(const Duration(hours: 2)).toIso8601String(),
      likesCount: 47,
      commentsCount: 12,
      liked: false,
    ),
    SocialPost(
      id: 'test_2',
      authorName: 'Priya Patel',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=priya',
      body: 'New personal best in 100m sprint! 11.8 seconds 🏆 Hard work pays off. #Athletics #Sprint #TrackAndField',
      imageUrl: 'https://picsum.photos/seed/sprint/800/450',
      createdAt: now.subtract(const Duration(hours: 5)).toIso8601String(),
      likesCount: 89,
      commentsCount: 23,
      liked: true,
    ),
    SocialPost(
      id: 'test_3',
      authorName: 'Cricket Academy Mumbai',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=academy',
      body: 'Registrations open for our Summer Cricket Camp! Ages 8-16. Professional coaching, match practice, fitness training. Limited spots - register now! 🏏',
      imageUrl: 'https://picsum.photos/seed/cricket_camp/800/450',
      createdAt: now.subtract(const Duration(hours: 8)).toIso8601String(),
      likesCount: 156,
      commentsCount: 34,
      liked: false,
    ),
    SocialPost(
      id: 'test_4',
      authorName: 'Arjun Kumar',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=arjun',
      body: 'Great session with the team today. Working on set pieces and defensive shape. The chemistry is building! ⚽🤝',
      imageUrl: null,
      createdAt: now.subtract(const Duration(hours: 12)).toIso8601String(),
      likesCount: 34,
      commentsCount: 8,
      liked: false,
    ),
    SocialPost(
      id: 'test_5',
      authorName: 'Neha Singh',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=neha',
      body: 'Just earned my Level 2 Coaching Certification! 📜 Excited to bring new techniques to my athletes. The learning never stops.',
      imageUrl: 'https://picsum.photos/seed/certification/800/450',
      createdAt: now.subtract(const Duration(days: 1)).toIso8601String(),
      likesCount: 72,
      commentsCount: 15,
      liked: false,
    ),
    SocialPost(
      id: 'test_6',
      authorName: 'Vikram Singh',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=vikram',
      body: 'Trial season is here! 🎯 Reminder: U-17 football trials at Sports Complex, Sector 12 this Saturday 9 AM. Bring your A-game!',
      imageUrl: null,
      createdAt: now.subtract(const Duration(days: 1, hours: 3)).toIso8601String(),
      likesCount: 45,
      commentsCount: 19,
      liked: true,
    ),
    SocialPost(
      id: 'test_7',
      authorName: 'SportsX Official',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=sportx',
      body: '🎉 Welcome to the new Community feed! Share your journey, connect with athletes, coaches & academies. Your sports network starts here.',
      imageUrl: 'https://picsum.photos/seed/welcome/800/450',
      createdAt: now.subtract(const Duration(days: 2)).toIso8601String(),
      likesCount: 234,
      commentsCount: 67,
      liked: false,
    ),
    SocialPost(
      id: 'test_8',
      authorName: 'Coach Rahul',
      authorAvatar: 'https://api.dicebear.com/7.x/avataaars/svg?seed=rahul',
      body: 'Pro tip: Focus on fundamentals before advanced techniques. Strong basics = consistent performance. Tag an athlete who needs to hear this! 💪',
      imageUrl: null,
      createdAt: now.subtract(const Duration(days: 2, hours: 5)).toIso8601String(),
      likesCount: 56,
      commentsCount: 11,
      liked: false,
    ),
  ];
});

/// Combined provider that merges test data with real API data
/// In production, this would just use postsFeedProvider
final combinedPostsProvider = FutureProvider<List<SocialPost>>((ref) async {
  // Try to fetch real data first
  try {
    final realPosts = await ref.watch(postsFeedProvider.future);
    if (realPosts.isNotEmpty) return realPosts;
  } catch (_) {
    // Fall back to test data on error
  }
  // Return test data as fallback
  return ref.read(testPostsProvider);
});