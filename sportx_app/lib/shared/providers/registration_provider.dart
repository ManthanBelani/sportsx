import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

final myTournamentRegistrationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/registrations/tournaments');
  final data = resp.data['data'] as List;
  return List<Map<String, dynamic>>.from(data as List);
});

final myTrialRegistrationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/registrations/trials');
  final data = resp.data['data'] as List;
  return List<Map<String, dynamic>>.from(data as List);
});
