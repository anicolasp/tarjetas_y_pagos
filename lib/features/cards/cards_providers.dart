import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/report.dart';
import '../../data/finance_snapshot.dart';
import '../../data/models/app_user.dart';
import '../../data/models/category.dart';
import '../../data/models/credit_card.dart';
import '../../data/models/expense.dart';
import '../../data/providers.dart';
import '../../data/repositories/cards_repository.dart';
import '../../data/repositories/categories_repository.dart';
import '../../data/repositories/debts_repository.dart';
import '../../data/repositories/expenses_repository.dart';
import '../../services/exchange_rate_service.dart';
import '../../services/providers.dart';
import '../auth/auth_controller.dart';

/// The logged-in user, or null.
final currentUserProvider = Provider<AppUser?>((ref) {
  final auth = ref.watch(authControllerProvider);
  return auth is AuthLoggedIn ? auth.user : null;
});

typedef Repos = ({
  CardsRepository cards,
  ExpensesRepository expenses,
  DebtsRepository debts,
  CategoriesRepository categories,
});

/// Both repositories over the opened database. They never change once open,
/// so the providers below watch a single `.future` (chains of derived async
/// providers trigger a Riverpod 3 "markNeedsBuild during build" when a
/// paused screen resumes).
final reposProvider = FutureProvider<Repos>((ref) async {
  final db = await ref.watch(appDatabaseProvider.future);
  final clock = ref.watch(clockProvider);
  return (
    cards: CardsRepository(db, clock: clock),
    expenses: ExpensesRepository(db, clock: clock),
    debts: DebtsRepository(db, clock: clock),
    categories: CategoriesRepository(db),
  );
}, retry: (retryCount, error) => null);

/// The single source for cards, balances, rankings and totals. Call
/// [refreshFinance] after any change.
final financeProvider = FutureProvider<FinanceSnapshot>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return FinanceSnapshot.empty;
  final repos = await ref.watch(reposProvider.future);
  final userId = user.id!;
  // Independent reads: run them together.
  final (cards, expenses, payments, debts, debtPayments) = await (
    repos.cards.listActive(userId),
    repos.expenses.list(userId),
    repos.expenses.payments(userId),
    repos.debts.list(userId),
    repos.debts.payments(userId),
  ).wait;
  return FinanceSnapshot(
    cards: cards,
    expenses: expenses,
    payments: payments,
    debts: debts,
    debtPayments: debtPayments,
  );
}, retry: (retryCount, error) => null);

/// One active card of the current user, or null if it does not exist, is
/// not theirs, or is archived (archived cards cannot be opened or edited).
final cardByIdProvider = FutureProvider.autoDispose.family<CreditCard?, int>((
  ref,
  id,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repos = await ref.watch(reposProvider.future);
  final card = await repos.cards.getById(user.id!, id);
  return card == null || card.archived ? null : card;
}, retry: (retryCount, error) => null);

/// Expenses matching [filter] (SQL side), newest first.
final filteredExpensesProvider = FutureProvider.autoDispose
    .family<List<Expense>, ExpenseFilter>((ref, filter) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return const [];
      final repos = await ref.watch(reposProvider.future);
      return repos.expenses.list(user.id!, filter);
    }, retry: (retryCount, error) => null);

/// Totals and series for [filter] (SQL side), per currency.
final reportProvider = FutureProvider.autoDispose
    .family<ExpenseReport, ExpenseFilter>((ref, filter) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) return ExpenseReport.empty;
      final repos = await ref.watch(reposProvider.future);
      return repos.expenses.report(user.id!, filter);
    }, retry: (retryCount, error) => null);

/// Active and archived cards, to name the card of any expense.
final allCardsProvider = FutureProvider.autoDispose<List<CreditCard>>((
  ref,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final repos = await ref.watch(reposProvider.future);
  return repos.cards.listAll(user.id!);
}, retry: (retryCount, error) => null);

final expenseByIdProvider = FutureProvider.autoDispose.family<Expense?, int>((
  ref,
  id,
) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repos = await ref.watch(reposProvider.future);
  return repos.expenses.getById(user.id!, id);
}, retry: (retryCount, error) => null);

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return const [];
  final repos = await ref.watch(reposProvider.future);
  return repos.expenses.categories(user.id!);
}, retry: (retryCount, error) => null);

final exchangeRateSourceProvider = Provider<ExchangeRateSource>(
  (ref) => OpenErApiSource(),
);

final exchangeRateServiceProvider = Provider<ExchangeRateService>(
  (ref) => ExchangeRateService(
    ref.watch(exchangeRateSourceProvider),
    ref.watch(sharedPreferencesProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Refreshes every money view after creating, editing or deleting a card,
/// expense or payment.
void refreshFinance(WidgetRef ref) {
  ref.invalidate(financeProvider);
  ref.invalidate(cardByIdProvider);
  ref.invalidate(filteredExpensesProvider);
  ref.invalidate(expenseByIdProvider);
  ref.invalidate(reportProvider);
  ref.invalidate(allCardsProvider);
}

/// After creating, editing or deleting a category (a deletion may move
/// expenses to another one).
void refreshCategories(WidgetRef ref) {
  ref.invalidate(categoriesProvider);
  refreshFinance(ref);
}
