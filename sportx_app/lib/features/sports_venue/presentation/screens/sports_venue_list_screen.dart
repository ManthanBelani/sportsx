import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

class SportsVenueListScreen extends ConsumerWidget {
  const SportsVenueListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sportsVenuesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Sports Venues')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(sportsVenuesProvider.notifier).refresh(),
        child: state.isLoading && state.items.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.items.isEmpty
                ? const Center(child: Text('No venues found'))
                : ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, i) {
                      final item = state.items[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withAlpha(26),
                          child: const Icon(Icons.location_city_outlined, color: Colors.blue),
                        ),
                        title: Text(item.name ?? ''),
                        subtitle: Text(item.city?.name ?? ''),
                        trailing: item.bookingAvailable == true
                            ? Chip(label: const Text('Bookable'), backgroundColor: Colors.green.withAlpha(26), labelStyle: const TextStyle(fontSize: 12, color: Colors.green))
                            : null,
                        onTap: () => context.push('/sports-venue-detail/${item.id}'),
                      );
                    },
                  ),
      ),
    );
  }
}
