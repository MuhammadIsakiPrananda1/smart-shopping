import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../domain/entities.dart';

abstract class ShoppingRepository {
  Future<Either<Failure, List<ShoppingList>>> getMyLists();
  Future<Either<Failure, void>> createList(String name, {String? category});
  Future<Either<Failure, void>> joinList(String shareCode);
  
  Stream<List<ShoppingItem>> watchItems(String listId);
  Future<Either<Failure, List<ShoppingItem>>> getItems(String listId);
  Future<Either<Failure, void>> addItem(
    String listId, 
    String name, {
    int? quantity,
    String? unit,
    String? category,
    double? price,
    DateTime? targetDate,
  });
  Future<Either<Failure, void>> toggleItem(String listId, ShoppingItem item);
  Future<Either<Failure, void>> deleteItem(String listId, String itemId);
  Future<Either<Failure, void>> deleteList(String listId);
  Future<Either<Failure, void>> deleteLists(List<String> listIds);

  // Plans Management
  Future<Either<Failure, List<Map>>> getPlans();
  Future<Either<Failure, void>> addPlan(String name, int iconCode);
  Future<Either<Failure, void>> deletePlan(String planId);
}
