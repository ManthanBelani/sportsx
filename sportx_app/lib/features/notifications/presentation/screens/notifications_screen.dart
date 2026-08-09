import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: false,
        actions: [
          if (state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton(
                onPressed: () => ref.read(notificationsProvider.notifier).markAllRead(),
                child: const Text('Mark all read', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.primary)),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
        child: _buildBody(context, ref, state),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, NotificationsState state) {
    if (state.isLoading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.items.isEmpty) {
      return Center(child: Text(state.error!));
    }

    if (state.items.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.bellOff, size: 64, color: AppColors.textTertiary),
            SizedBox(height: 16),
            Text('No notifications yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          ],
        ),
      );
    }

    // Sort items by date descending just to be safe
    final sortedItems = List.of(state.items)..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      itemCount: sortedItems.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == sortedItems.length) {
          ref.read(notificationsProvider.notifier).loadMore();
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final item = sortedItems[i];
        final previousItem = i > 0 ? sortedItems[i - 1] : null;
        
        final dateGroup = _getDateGroup(item.createdAt);
        final previousDateGroup = previousItem != null ? _getDateGroup(previousItem.createdAt) : null;
        
        final showHeader = dateGroup != previousDateGroup;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                color: AppColors.surface,
                child: Text(
                  dateGroup,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
                ),
              ),
            _buildNotificationItem(context, ref, item),
          ],
        );
      },
    );
  }

  Widget _buildNotificationItem(BuildContext context, WidgetRef ref, dynamic item) {
    final typeData = _getTypeData(item.type);
    
    return InkWell(
      onTap: () {
        if (!item.isRead) {
          ref.read(notificationsProvider.notifier).markAsRead(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: typeData.bgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Icon(typeData.icon, color: typeData.iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: item.isRead ? AppColors.textSecondary : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.body,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(item.createdAt),
                    style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
            if (!item.isRead)
              Container(
                margin: const EdgeInsets.only(top: 6, left: 8),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getDateGroup(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);
    
    if (itemDate == today) return 'TODAY';
    if (itemDate == yesterday) return 'YESTERDAY';
    if (now.difference(date).inDays < 7) return 'THIS WEEK';
    return 'EARLIER';
  }

  String _formatTime(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    if (diff.inDays == 1) return 'Yesterday, ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    return '${date.day}/${date.month}/${date.year}';
  }

  _TypeData _getTypeData(String? type) {
    switch (type) {
      case 'trial_reminder': 
      case 'deadline':
        return _TypeData(icon: LucideIcons.clock, bgColor: const Color(0xFFfef3c7), iconColor: const Color(0xFF92400e));
      case 'registration': 
      case 'trial':
        return _TypeData(icon: LucideIcons.checkCircle, bgColor: const Color(0xFFdbeafe), iconColor: const Color(0xFF1e40af));
      case 'enquiry': 
      case 'reply':
        return _TypeData(icon: LucideIcons.messageCircle, bgColor: const Color(0xFFd1fae5), iconColor: const Color(0xFF065f46));
      case 'shortlist': 
      case 'application':
        return _TypeData(icon: LucideIcons.trophy, bgColor: const Color(0xFFede9fe), iconColor: const Color(0xFF5b21b6));
      default: 
        return _TypeData(icon: LucideIcons.bell, bgColor: AppColors.surface, iconColor: AppColors.textSecondary);
    }
  }
}

class _TypeData {
  final IconData icon;
  final Color bgColor;
  final Color iconColor;

  _TypeData({required this.icon, required this.bgColor, required this.iconColor});
}
