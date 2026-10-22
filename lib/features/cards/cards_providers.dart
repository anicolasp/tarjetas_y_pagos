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

/// One card of the current user, or null if it does not exist (or is not
/// theirs).
final cardByIdProvider = FutureProvider.family<CreditCard?, int>((
  ref,
  id,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = await ref.watch(cardsRepositoryProvider.future);
  return repo.getById(user.id!, id);
}, retry: (retryCount, error) => null);

/// "Mejor tarjeta hoy": active cards ranked for today. Balances are 0 until
/// expenses exist (#5).
final cardRankingProvider = FutureProvider<List<CardRecommendation>>((
  ref,
) async {
  final cards = await ref.watch(userCardsProvider.future);
  return rankCards(cards, ref.watch(clockProvider)());
}, retry: (retryCount, error) => null);

/// Refreshes every card view after a create/update/archive.
void refreshCards(WidgetRef ref) {
  ref.invalidate(userCardsProvider);
  ref.invalidate(cardByIdProvider);
}
