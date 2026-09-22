import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories(String userId) =>
      (select(categories)..where((c) => c.userId.equals(userId))).get();

  Stream<List<Category>> watchAllCategories(String userId) =>
      (select(categories)..where((c) => c.userId.equals(userId))).watch();

  /// Only categories matching the given type ("Expense" or "Income")
  /// AND belonging to this user.
  Stream<List<Category>> watchCategoriesByType(String userId, String type) =>
      (select(categories)
        ..where((c) => c.userId.equals(userId) & c.type.equals(type)))
          .watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id, String userId) =>
      (delete(categories)
        ..where((c) => c.id.equals(id) & c.userId.equals(userId)))
          .go();

  /// Inserts a starter set of categories the first time this user's
  /// account is used. Safe to call every app launch — it only inserts
  /// if this user has no categories yet.
  Future<void> seedDefaultCategories(String userId) async {
    final existing = await getAllCategories(userId);
    if (existing.isNotEmpty) return;

    final defaults = [
      ('Food', 'restaurant', '#EF6C00', 'Expense'),
      ('Entertainment', 'movie', '#7B61FF', 'Expense'),
      ('Rent', 'home', '#2E7D5B', 'Expense'),
      ('Salary', 'payments', '#2E7D5B', 'Income'),
      ('Other', 'receipt_long', '#757575', 'Expense'),
    ];

    for (final (name, icon, color, type) in defaults) {
      await insertCategory(
        CategoriesCompanion.insert(
          userId: Value(userId),
          name: name,
          icon: icon,
          color: color,
          type: Value(type),
          isDefault: const Value(true),
        ),
      );
    }
  }
}