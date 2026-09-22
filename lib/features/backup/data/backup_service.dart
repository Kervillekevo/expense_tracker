import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:path_provider/path_provider.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

class BackupService {
  /// Writes this user's transactions and categories to a JSON file.
  Future<File> exportToFile(String userId) async {
    final categories = await DatabaseProvider.db.categoryDao.getAllCategories(userId);
    final transactions = await DatabaseProvider.db.transactionDao.getAllTransactions(userId);

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

  /// Restores a previously exported file into this user's account only.
  Future<({int categoriesAdded, int transactionsAdded})> restoreFromFile(
      File file,
      String userId,
      ) async {
    final contents = await file.readAsString();
    final data = jsonDecode(contents) as Map<String, dynamic>;

    final categoriesJson = (data['categories'] as List<dynamic>?) ?? [];
    final transactionsJson = (data['transactions'] as List<dynamic>?) ?? [];

    final existingCategories = await DatabaseProvider.db.categoryDao.getAllCategories(userId);
    final existingKeys = existingCategories.map((c) => '${c.name}|${c.type}').toSet();

    int categoriesAdded = 0;
    for (final item in categoriesJson) {
      final name = item['name'] as String;
      final type = item['type'] as String? ?? 'Expense';
      final key = '$name|$type';
      if (existingKeys.contains(key)) continue;

      await DatabaseProvider.db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          userId: Value(userId),
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
          userId: Value(userId),
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