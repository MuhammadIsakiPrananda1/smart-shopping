import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/category_detector.dart';
import '../domain/entities.dart';
import '../domain/repositories.dart';

class ShoppingRepositoryImpl implements ShoppingRepository {
  static const String listsBoxName = 'shopping_lists';
  static const String itemsBoxName = 'shopping_items';
  static const String historyBoxName = 'purchase_history';
  static const String plansBoxName = 'shopping_plans';

  final Box<ShoppingList> _listsBox;
  final Box<ShoppingItem> _itemsBox;
  final Box _historyBox;
  final Box _plansBox;

  ShoppingRepositoryImpl({
    Box<ShoppingList>? listsBox,
    Box<ShoppingItem>? itemsBox,
    Box? historyBox,
    Box? plansBox,
  })  : _listsBox = listsBox ?? Hive.box<ShoppingList>(listsBoxName),
        _itemsBox = itemsBox ?? Hive.box<ShoppingItem>(itemsBoxName),
        _historyBox = historyBox ?? Hive.box(historyBoxName),
        _plansBox = plansBox ?? Hive.box(plansBoxName);

  @override
  Future<Either<Failure, List<ShoppingList>>> getMyLists() async {
    try {
      final lists = _listsBox.values.toList();
      return Right(lists);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> createList(String name, {String? category}) async {
    try {
      final list = ShoppingList.create(
        name: name,
        ownerId: 'local_user',
        category: category ?? 'Umum',
      );
      await _listsBox.put(list.id, list);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> joinList(String shareCode) async {
    // Sharing is disabled in local-only mode
    return Left(ServerFailure('Fitur berbagi tidak tersedia di mode lokal.'));
  }

  @override
  Stream<List<ShoppingItem>> watchItems(String listId) {
    // Return a stream that emits current items and updates on box changes
    final controller = StreamController<List<ShoppingItem>>();
    
    void emit() {
      final items = _itemsBox.values
          .where((item) => item.listId == listId)
          .toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      controller.add(items);
    }

    emit(); // Initial emission

    final subscription = _itemsBox.watch().listen((event) => emit());
    
    controller.onCancel = () {
      subscription.cancel();
      controller.close();
    };

    return controller.stream;
  }

  @override
  Future<Either<Failure, List<ShoppingItem>>> getItems(String listId) async {
    try {
      final items = _itemsBox.values
          .where((item) => item.listId == listId)
          .toList()
        ..sort((a, b) => b.addedAt.compareTo(a.addedAt));
      return Right(items);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addItem(
    String listId, 
    String name, {
    int? quantity,
    String? unit,
    String? category,
    double? price,
    DateTime? targetDate,
  }) async {
    try {
      final detectedCategory = category ?? CategoryDetector.detect(name);
      final item = ShoppingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        listId: listId,
        name: name,
        category: detectedCategory,
        quantity: quantity,
        unit: unit,
        price: price,
        targetDate: targetDate,
        addedAt: DateTime.now(),
        isChecked: false,
      );
      
      await _itemsBox.put(item.id, item);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> toggleItem(String listId, ShoppingItem item) async {
    try {
      final isNowChecked = !item.isChecked;
      final newItem = item.copyWith(isChecked: isNowChecked);
      await _itemsBox.put(item.id, newItem);
      
      final history = List.from(_historyBox.get('items', defaultValue: []) as List);
      
      if (isNowChecked) {
        // Add to history only if it doesn't already exist to prevent duplicates
        final alreadyInHistory = history.any((e) => (e as Map)['itemId'] == item.id);
        if (!alreadyInHistory) {
          history.add({
            'itemId': item.id,
            'listId': listId, // Add listId for better synchronization
            'itemName': item.name,
            'category': item.category,
            'price': item.price,
            'purchasedAt': DateTime.now().toIso8601String(),
          });
          await _historyBox.put('items', history);
        }
      } else {
        // Remove from history if it exists
        history.removeWhere((e) => (e as Map)['itemId'] == item.id);
        await _historyBox.put('items', history);
      }
          
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteItem(String listId, String itemId) async {
    try {
      await _itemsBox.delete(itemId);
      
      // Sync Activity: Remove from history when item is deleted
      final history = List.from(_historyBox.get('items', defaultValue: []) as List);
      history.removeWhere((e) => (e as Map)['itemId'] == itemId);
      await _historyBox.put('items', history);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteList(String listId) async {
    try {
      // 1. Collect all item IDs for this list BEFORE deleting anything
      final itemIds = _itemsBox.values
          .where((item) => item.listId == listId)
          .map((item) => item.id)
          .toList();
      
      // 2. Sync Activity: Remove all items of this list from history
      final history = List.from(_historyBox.get('items', defaultValue: []) as List);
      history.removeWhere((e) {
        final entry = e as Map;
        
        // Priority 1: Match by listId (newly added field)
        if (entry['listId'] == listId) return true;
        
        // Priority 2: Fallback for older entries using itemId
        if (itemIds.isNotEmpty) {
          final itemId = entry['itemId']?.toString();
          return itemIds.any((id) => id.toString() == itemId);
        }
        
        return false;
      });
      await _historyBox.put('items', history);
      
      // 3. Delete associated items from items box
      final itemKeys = _itemsBox.keys.where((key) {
        final item = _itemsBox.get(key);
        return item?.listId == listId;
      }).toList();
      await _itemsBox.deleteAll(itemKeys);
      
      // 4. Delete the list itself
      await _listsBox.delete(listId);
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteLists(List<String> listIds) async {
    try {
      final allItemIds = <String>[];
      
      for (final listId in listIds) {
        // 1. Collect item IDs for this list
        final itemIds = _itemsBox.values
            .where((item) => item.listId == listId)
            .map((item) => item.id)
            .toList();
        allItemIds.addAll(itemIds);
        
        // 2. Delete items associated with this list
        final itemKeys = _itemsBox.keys.where((key) {
          final item = _itemsBox.get(key);
          return item?.listId == listId;
        }).toList();
        await _itemsBox.deleteAll(itemKeys);
        
        // 3. Delete the list itself
        await _listsBox.delete(listId);
      }

      // 4. Sync Activity: Remove all collected items from history
      if (allItemIds.isNotEmpty || listIds.isNotEmpty) {
        final history = List.from(_historyBox.get('items', defaultValue: []) as List);
        history.removeWhere((e) {
          final entry = e as Map;
          
          // Priority 1: Match by listId
          if (listIds.contains(entry['listId'])) return true;
          
          // Priority 2: Fallback for older entries
          if (allItemIds.isNotEmpty) {
            final itemId = entry['itemId']?.toString();
            return allItemIds.any((id) => id.toString() == itemId);
          }
          
          return false;
        });
        await _historyBox.put('items', history);
      }
      
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Map>>> getPlans() async {
    try {
      final plans = _plansBox.get('items', defaultValue: []) as List;
      return Right(plans.cast<Map>());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addPlan(String name, int iconCode) async {
    try {
      final plans = List.from(_plansBox.get('items', defaultValue: []) as List);
      plans.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'name': name,
        'iconCode': iconCode,
        'createdAt': DateTime.now().toIso8601String(),
      });
      await _plansBox.put('items', plans);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deletePlan(String planId) async {
    try {
      final plans = List.from(_plansBox.get('items', defaultValue: []) as List);
      plans.removeWhere((p) => (p as Map)['id'] == planId);
      await _plansBox.put('items', plans);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
