import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class EnquiryInboxScreen extends ConsumerStatefulWidget {
  const EnquiryInboxScreen({super.key});

  @override
  ConsumerState<EnquiryInboxScreen> createState() => _EnquiryInboxScreenState();
}

class _EnquiryInboxScreenState extends ConsumerState<EnquiryInboxScreen> {
  int _selectedIndex = 0;
  final _tabs = ['All', 'New', 'Replied'];

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(enquiryInboxProvider.notifier).load());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(enquiryInboxProvider);
    final items = state.items.where((e) {
      switch (_selectedIndex) {
        case 1:
          return e.status == 'new' && !e.isRead;
        case 2:
          return e.status != 'new' || e.isRead;
        default:
          return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Enquiry Inbox',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: List.generate(_tabs.length, (index) {
                final isSelected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(_tabs[index]),
                    selected: isSelected,
                    onSelected: (val) => setState(() => _selectedIndex = index),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    checkmarkColor: AppColors.primary,
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(enquiryInboxProvider.notifier).load(),
              child: state.isLoading && state.items.isEmpty
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : items.isEmpty
                      ? const Center(
                          child: Text('No enquiries', style: TextStyle(color: AppColors.textSecondary)))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: items.length,
                          itemBuilder: (context, i) {
                            final e = items[i];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildMessageCard(e, context, ref),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(Enquiry e, BuildContext context, WidgetRef ref) {
    final isNew = e.status == 'new' && !e.isRead;
    return InkWell(
      onTap: () => context.push('/enquiry-detail', extra: {'id': e.id}),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(12),
          color: isNew ? AppColors.primary.withOpacity(0.05) : AppColors.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle,
                    size: 12, color: isNew ? AppColors.primary : AppColors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('${e.athleteName} · ${e.sport ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('"${e.message}"', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(e.createdAt ?? '',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                if (isNew)
                  TextButton(
                    onPressed: () => context.push('/enquiry-detail', extra: {'id': e.id}),
                    child: const Text('Reply'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
