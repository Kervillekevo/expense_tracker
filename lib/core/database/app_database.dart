import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'tables/transactions_table.dart';
import 'tables/categories_table.dart';
import 'daos/transaction_dao.dart';
import 'daos/category_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Transactions, Categories],
  daos: [TransactionDao, CategoryDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) => m.createAll(),
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 2) {
        // Added Categories.type (Expense/Income) in schema version 2.
        await m.addColumn(categories, categories.type);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'expense_tracker.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}