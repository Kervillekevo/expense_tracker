import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() => select(categories).get();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  /// Only categories matching the given type ("Expense" or "Income").
  Stream<List<Category>> watchCategoriesByType(String type) =>
      (select(categories)..where((c) => c.type.equals(type))).watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  Future<bool> updateCategory(CategoriesCompanion entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  /// Inserts a starter set of categories the first time the app runs.
  /// Safe to call every app launch — it only inserts if the table is empty.
  Future<void> seedDefaultCategories() async {
    final existing = await getAllCategories();
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