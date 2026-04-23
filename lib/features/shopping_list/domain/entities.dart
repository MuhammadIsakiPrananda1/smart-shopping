import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'entities.g.dart';

@HiveType(typeId: 0)
class ShoppingList {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String ownerId;
  @HiveField(3)
  final List<String> members;
  @HiveField(4)
  final DateTime createdAt;
  @HiveField(5)
  final String shareCode;
  @HiveField(6)
  final String? category;

  ShoppingList({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    required this.createdAt,
    required this.shareCode,
    this.category,
  });

  factory ShoppingList.create({
    required String name,
    required String ownerId,
    String category = 'Umum',
  }) {
    return ShoppingList(
      id: const Uuid().v4(),
      name: name,
      ownerId: ownerId,
      members: [ownerId],
      createdAt: DateTime.now(),
      shareCode: const Uuid().v4().substring(0, 8).toUpperCase(),
      category: category,
    );
  }
}

@HiveType(typeId: 1)
class ShoppingItem {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String listId;
  @HiveField(2)
  final String name;
  @HiveField(3)
  final String category;
  @HiveField(4)
  final bool isChecked;
  @HiveField(5)
  final int? quantity;
  @HiveField(6)
  final String? unit;
  @HiveField(7)
  final DateTime addedAt;
  @HiveField(8)
  final String? barcode;
  @HiveField(9)
  final double? price;
  @HiveField(10)
  final DateTime? targetDate;

  ShoppingItem({
    required this.id,
    required this.listId,
    required this.name,
    required this.category,
    this.isChecked = false,
    this.quantity,
    this.unit,
    required this.addedAt,
    this.barcode,
    this.price,
    this.targetDate,
  });

  ShoppingItem copyWith({
    bool? isChecked,
    String? name,
    String? category,
    int? quantity,
    String? unit,
    double? price,
    DateTime? targetDate,
  }) {
    return ShoppingItem(
      id: id,
      listId: listId,
      name: name ?? this.name,
      category: category ?? this.category,
      isChecked: isChecked ?? this.isChecked,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      addedAt: addedAt,
      barcode: barcode,
      price: price ?? this.price,
      targetDate: targetDate ?? this.targetDate,
    );
  }
}
