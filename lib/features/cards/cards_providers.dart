import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/billing_cycle.dart';
import '../../core/clock.dart';
import '../../data/models/app_user.dart';
import '../../data/models/credit_card.dart';
import '../../data/providers.dart';
import '../../data/repositories/cards_repository.dart';
import '../auth/auth_controller.dart';

/// The logged-in user, or null.
final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is AuthLoggedIn ? auth.user : null;
});

final cardsRepositoryProvider = FutureProvider<CardsRepository>((ref) async {
  return CardsRepository(
    await ref.watch(appDatabaseProvider.future),
    clock: ref.watch(clockProvider),
  );
}, retry: (retryCount, error) => null);

/// Active cards of the current user. Invalidate after any change.
final userCardsProvider = FutureProvider<List<CreditCard>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final repo = await ref.watch(cardsRepositoryProvider.future);
  return repo.listActive(user.id!);
}, retry: (retryCount, error) => null);

/// One active card of the current user, or null if it does not exist, is
/// not theirs, or is archived (archived cards cannot be opened or edited).
final cardByIdProvider = FutureProvider.family<CreditCard?, int>((
  ref,
  id,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = await ref.watch(cardsRepositoryProvider.future);
  final card = await repo.getById(user.id!, id);
  return card == null || card.archived ? null : card;
}, retry: (retryCount, error) => null);

/// "Mejor tarjeta hoy": active cards ranked for today. Balances are 0 until
/// expenses exist (#5).
final cardRankingProvider = FutureProvider<List<CardRecommendation>>((
  ref,
) async {
  final cards = await ref.watch(userCardsProvider.future);
  return rankCards(cards, ref.watch(clockProvider)());
}, retry: (retryCount, error) => null);

/// [ranked] in the order the cards were added, as [cards] (from
/// [userCardsProvider]) lists them. Kept as a plain function: a derived
/// provider here triggers a Riverpod 3 "markNeedsBuild during build" when a
/// paused screen resumes.
List<CardRecommendation> inAddedOrder(
  List<CreditCard> cards,
  List<CardRecommendation> ranked,
) {
  final byId = {for (final r in ranked) r.card.id: r};
  return [for (final c in cards) ?byId[c.id]];
}

/// Refreshes every card view after a create/update/archive.
void refreshCards(WidgetRef ref) {
  ref.invalidate(userCardsProvider);
  ref.invalidate(cardByIdProvider);
}
