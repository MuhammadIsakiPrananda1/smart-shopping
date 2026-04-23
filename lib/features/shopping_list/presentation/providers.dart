import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../data/repositories_impl.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';

final themeModeProvider = StreamProvider<ThemeMode>((ref) async* {
  final box = Hive.box('settings');
  
  ThemeMode getThemeMode() {
    final val = box.get('theme_mode', defaultValue: 0) as int;
    switch (val) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  yield getThemeMode();
  
  await for (final event in box.watch(key: 'theme_mode')) {
    yield getThemeMode();
  }
});

final currencyProvider = StreamProvider<String>((ref) async* {
  final box = Hive.box('settings');
  yield box.get('currency', defaultValue: 'Rp') as String;
  await for (final event in box.watch(key: 'currency')) {
    yield box.get('currency', defaultValue: 'Rp') as String;
  }
});

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepositoryImpl();
});

final myListsProvider = FutureProvider<List<ShoppingList>>((ref) async {
  final repo = ref.watch(shoppingRepositoryProvider);
  final result = await repo.getMyLists();
  return result.fold(
    (l) => throw Exception(l.message),
    (r) => r,
  );
});

final activeListIdProvider = StateProvider<String?>((ref) => null);
final selectedListIdsProvider = StateProvider<Set<String>>((ref) => {});

final shoppingItemsProvider = StreamProvider.family<List<ShoppingItem>, String>((ref, listId) {
  final repo = ref.watch(shoppingRepositoryProvider);
  return repo.watchItems(listId);
});

enum ListSortCriteria { newest, name, progress }

final sortCriteriaProvider = StateProvider<ListSortCriteria>((ref) => ListSortCriteria.newest);
final isSearchExpandedProvider = StateProvider<bool>((ref) => false);
final searchQueryProvider = StateProvider<String>((ref) => '');

final plansProvider = StreamProvider<List<Map>>((ref) async* {
  final box = Hive.box('shopping_plans');
  yield (box.get('items', defaultValue: []) as List).cast<Map>();
  
  await for (final _ in box.watch()) {
    yield (box.get('items', defaultValue: []) as List).cast<Map>();
  }
});

final sortedListsProvider = FutureProvider<List<ShoppingList>>((ref) async {
  final lists = await ref.watch(myListsProvider.future);
  final criteria = ref.watch(sortCriteriaProvider);
  final repo = ref.watch(shoppingRepositoryProvider);

  final sortedLists = [...lists];

  switch (criteria) {
    case ListSortCriteria.name:
      sortedLists.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case ListSortCriteria.newest:
      sortedLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
    case ListSortCriteria.progress:
      final progressMap = <String, double>{};
      for (final list in sortedLists) {
        final items = await repo.getItems(list.id);
        final result = items.getOrElse(() => []);
        final total = result.length;
        final done = result.where((i) => i.isChecked).length;
        progressMap[list.id] = total > 0 ? done / total : 0.0;
      }
      sortedLists.sort((a, b) => progressMap[b.id]!.compareTo(progressMap[a.id]!));
      break;
  }

  // Handle Search Filtering
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isNotEmpty) {
    return sortedLists.where((list) => list.name.toLowerCase().contains(query)).toList();
  }

  return sortedLists;
});

class ShoppingController extends StateNotifier<AsyncValue<void>> {
  final ShoppingRepository _repository;
  ShoppingController(this._repository) : super(const AsyncData(null));

  Future<void> addList(String name, {String? category}) async {
    state = const AsyncLoading();
    final result = await _repository.createList(name, category: category);
    state = result.fold(
      (l) => AsyncError(l.message, StackTrace.current),
      (r) => const AsyncData(null),
    );
  }

  Future<void> addItem(
    String listId, 
    String name, {
    int? quantity,
    String? unit,
    String? category,
    double? price,
    DateTime? targetDate,
  }) async {
    await _repository.addItem(
      listId, 
      name, 
      quantity: quantity, 
      unit: unit, 
      category: category,
      price: price,
      targetDate: targetDate,
    );
  }

  Future<void> toggleItem(String listId, ShoppingItem item) async {
    await _repository.toggleItem(listId, item);
  }

  Future<void> deleteItem(String listId, String itemId) async {
    await _repository.deleteItem(listId, itemId);
  }

  Future<void> deleteList(String listId) async {
    await _repository.deleteList(listId);
  }

  Future<void> deleteLists(List<String> listIds) async {
    state = const AsyncLoading();
    final result = await _repository.deleteLists(listIds);
    state = result.fold(
      (l) => AsyncError(l.message, StackTrace.current),
      (r) => const AsyncData(null),
    );
  }
  
  Future<void> joinList(String code) async {
    state = const AsyncLoading();
    final result = await _repository.joinList(code);
    state = result.fold(
      (l) => AsyncError(l.message, StackTrace.current),
      (r) => const AsyncData(null),
    );
  }

  Future<void> addPlan(String name, int iconCode) async {
    await _repository.addPlan(name, iconCode);
  }

  Future<void> deletePlan(String planId) async {
    await _repository.deletePlan(planId);
  }
}

final shoppingControllerProvider = StateNotifierProvider<ShoppingController, AsyncValue<void>>((ref) {
  return ShoppingController(ref.watch(shoppingRepositoryProvider));
});

final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});
