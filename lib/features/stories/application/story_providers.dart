import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../offers/data/offers_repository.dart';
import '../../session/data/session_repository.dart';
import '../data/story_repository.dart';
import '../domain/story.dart';

final latestStoryProvider = FutureProvider((ref) {
  ref.watch(accountProvider.select((account) => account.id));
  return ref.watch(storyRepositoryProvider).latest();
});

final storyProvider = FutureProvider.autoDispose.family<Story, String>(
  (ref, id) => ref.watch(storyRepositoryProvider).byId(id),
);

/// Une création par demande ; « Réessayer » rejoue la même demande (idempotente côté serveur).
final storyCreationProvider = FutureProvider.autoDispose.family<Story, StoryRequest>((ref, request) async {
  final story = await ref.watch(storyRepositoryProvider).create(request);
  ref
    ..invalidate(entitlementsProvider)
    ..invalidate(latestStoryProvider);
  return story;
});

/// Identifiant UUID v4 d'une demande de création.
String newRequestId() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  bytes[6] = bytes[6] & 0x0f | 0x40;
  bytes[8] = bytes[8] & 0x3f | 0x80;
  final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
      '${hex.substring(16, 20)}-${hex.substring(20)}';
}
