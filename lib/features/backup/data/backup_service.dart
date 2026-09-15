import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

class BackupService {
  /// Writes all transactions and categories to a JSON file in the app's
  /// temporary folder and returns it, ready to hand off to the share sheet.
  Future<File> exportToFile() async {
    final categories = await DatabaseProvider.db.categoryDao.getAllCategories();
    final transactions = await DatabaseProvider.db.transactionDao.getAllTransactions();

    final data = {
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories.map((c) => {
        'name': c.name,
        'icon': c.icon,
        'color': c.color,
        'type': c.type,
        'isDefault': c.isDefault,
      }).toList(),
      'transactions': transactions.map((t) => {
        'amount': t.amount,
        'type': t.type,
        'category': t.category,
        'note': t.note,
        'date': t.date.toIso8601String(),
        'receiptImageUrl': t.receiptImageUrl,
        'createdAt': t.createdAt.toIso8601String(),
        'updatedAt': t.updatedAt.toIso8601String(),
      }).toList(),
    };

    final jsonString = const JsonEncoder.withIndent('  ').convert(data);

    final tempDir = await getTemporaryDirectory();
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first;
    final file = File('${tempDir.path}/expense_tracker_backup_$timestamp.json');
    await file.writeAsString(jsonString);

    return file;
  }

  /// Reads a previously exported JSON file and inserts its contents back
  /// into the local database. Categories that already exist (matched by
  /// name + type) are skipped to avoid duplicates; transactions are always
  /// added as new rows, since there's no unique key to detect duplicates
  /// against.
  Future<({int categoriesAdded, int transactionsAdded})> restoreFromFile(
      File file,
      ) async {
    final contents = await file.readAsString();
    final data = jsonDecode(contents) as Map<String, dynamic>;

    final categoriesJson = (data['categories'] as List<dynamic>?) ?? [];
    final transactionsJson = (data['transactions'] as List<dynamic>?) ?? [];

    final existingCategories = await DatabaseProvider.db.categoryDao.getAllCategories();
    final existingKeys = existingCategories.map((c) => '${c.name}|${c.type}').toSet();

    int categoriesAdded = 0;
    for (final item in categoriesJson) {
      final name = item['name'] as String;
      final type = item['type'] as String? ?? 'Expense';
      final key = '$name|$type';
      if (existingKeys.contains(key)) continue;

      await DatabaseProvider.db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          name: name,
          icon: item['icon'] as String,
          color: item['color'] as String,
          type: Value(type),
          isDefault: Value(item['isDefault'] as bool? ?? false),
        ),
      );
      existingKeys.add(key);
      categoriesAdded++;
    }

    int transactionsAdded = 0;
    for (final item in transactionsJson) {
      await DatabaseProvider.db.transactionDao.insertTransaction(
        TransactionsCompanion.insert(
          amount: (item['amount'] as num).toDouble(),
          type: item['type'] as String,
          category: item['category'] as String,
          date: DateTime.parse(item['date'] as String),
          note: Value(item['note'] as String?),
          receiptImageUrl: Value(item['receiptImageUrl'] as String?),
          createdAt: Value(DateTime.parse(item['createdAt'] as String)),
          updatedAt: Value(DateTime.parse(item['updatedAt'] as String)),
        ),
      );
      transactionsAdded++;
    }

    return (categoriesAdded: categoriesAdded, transactionsAdded: transactionsAdded);
  }
}