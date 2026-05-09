import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/budget_expense.dart';
import 'settings_provider.dart';

class BudgetState {
  final double totalBudget;
  final String currency;
  final List<BudgetExpense> expenses;

  const BudgetState({
    this.totalBudget = 0,
    this.currency = 'TND',
    this.expenses = const [],
  });

  double get spent => expenses.fold(0.0, (sum, e) => sum + e.amount);

  double get remaining => totalBudget - spent;

  double get percentUsed =>
      totalBudget <= 0 ? 0 : (spent / totalBudget).clamp(0.0, 1.0);

  BudgetState copyWith({
    double? totalBudget,
    String? currency,
    List<BudgetExpense>? expenses,
  }) => BudgetState(
    totalBudget: totalBudget ?? this.totalBudget,
    currency: currency ?? this.currency,
    expenses: expenses ?? this.expenses,
  );
}

class BudgetNotifier extends StateNotifier<BudgetState> {
  final SharedPreferences _prefs;

  BudgetNotifier(this._prefs) : super(const BudgetState()) {
    _load();
  }

  static const _keyTotal = 'budget_total';
  static const _keyCurrency = 'budget_currency';
  static const _keyExpenses = 'budget_expenses';

  void _load() {
    final total = _prefs.getDouble(_keyTotal) ?? 0;
    final currency = _prefs.getString(_keyCurrency) ?? 'TND';
    final raw = _prefs.getStringList(_keyExpenses) ?? [];
    final expenses =
        raw
            .map((s) {
              try {
                return BudgetExpense.fromJson(
                  jsonDecode(s) as Map<String, dynamic>,
                );
              } catch (_) {
                return null;
              }
            })
            .whereType<BudgetExpense>()
            .toList()
          ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    state = BudgetState(
      totalBudget: total,
      currency: currency,
      expenses: expenses,
    );
  }

  Future<void> _save() async {
    await _prefs.setDouble(_keyTotal, state.totalBudget);
    await _prefs.setString(_keyCurrency, state.currency);
    await _prefs.setStringList(
      _keyExpenses,
      state.expenses.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  Future<void> setBudget(double amount, String currency) async {
    state = state.copyWith(totalBudget: amount, currency: currency);
    await _save();
  }

  Future<void> addExpense(double amount, String label) async {
    final expense = BudgetExpense(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      currency: state.currency,
      label: label,
      timestamp: DateTime.now(),
    );
    final updated = [expense, ...state.expenses];
    state = state.copyWith(expenses: updated);
    await _save();
  }

  Future<void> removeExpense(String id) async {
    final updated = state.expenses.where((e) => e.id != id).toList();
    state = state.copyWith(expenses: updated);
    await _save();
  }

  Future<void> resetBudget() async {
    state = BudgetState(currency: state.currency);
    await _prefs.remove(_keyTotal);
    await _prefs.remove(_keyCurrency);
    await _prefs.remove(_keyExpenses);
  }
}

final budgetProvider = StateNotifierProvider<BudgetNotifier, BudgetState>((
  ref,
) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return BudgetNotifier(prefs);
});
