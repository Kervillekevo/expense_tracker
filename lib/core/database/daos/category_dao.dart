import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/categories_table.dart';

part 'category_dao.g.dart';

@DriftAccessor(tables: [Categories])
class CategoryDao extends DatabaseAccessor<AppDatabase> with _$CategoryDaoMixin {
  CategoryDao(super.db);

  Future<List<Category>> getAllCategories() => select(categories).get();
  Stream<List<Category>> watchAllCategories() => select(categories).watch();

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
      CategoriesCompanion.insert(
        name: "Food",
        icon: "restaurant",
        color: "#2E7D5B",
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: "Entertainment",
        icon: "movie",
        color: "#2E7D5B",
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: "Rent",
        icon: "home",
        color: "#2E7D5B",
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: "Salary",
        icon: "payments",
        color: "#2E7D5B",
        isDefault: const Value(true),
      ),
      CategoriesCompanion.insert(
        name: "Other",
        icon: "receipt_long",
        color: "#2E7D5B",
        isDefault: const Value(true),
      ),
    ];

    for (final entry in defaults) {
      await insertCategory(entry);
    }
  }
}