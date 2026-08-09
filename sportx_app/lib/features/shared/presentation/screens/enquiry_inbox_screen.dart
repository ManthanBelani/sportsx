import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EnquiryInboxScreen extends StatefulWidget {
  const EnquiryInboxScreen({super.key});

  @override
  State<EnquiryInboxScreen> createState() => _EnquiryInboxScreenState();
}

class _EnquiryInboxScreenState extends State<EnquiryInboxScreen> {
  int _selectedIndex = 0;
  final _tabs = ['All', 'New', 'Replied'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Enquiry Inbox'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                    onSelected: (val) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                    selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).primaryColor,
                  ),
                );
              }),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMessageCard('Aryan Patel', 'Cricket', 'Is there a slot this weekend?', '2h ago', true, context),
                const SizedBox(height: 12),
                _buildMessageCard('Meera Shah', 'Badminton', 'What are your fees for U-12?', '1d ago', false, context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageCard(String name, String sport, String message, String time, bool isNew, BuildContext context) {
    return InkWell(
      onTap: () => context.push('/enquiry-detail'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
          color: isNew ? Theme.of(context).primaryColor.withOpacity(0.05) : Colors.white,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: isNew ? Theme.of(context).primaryColor : Colors.grey[400]),
                const SizedBox(width: 8),
                Text('$name · $sport', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 8),
            Text('"$message"', style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isNew ? time : '$time · Replied', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                if (isNew)
                  TextButton(
                    onPressed: () => context.push('/enquiry-detail'),
                    child: const Text('Reply'),
                  )
              ],
            )
          ],
        ),
      ),
    );
  }
}
