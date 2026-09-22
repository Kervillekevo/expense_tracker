import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/transactions_table.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions])
class TransactionDao extends DatabaseAccessor<AppDatabase> with _$TransactionDaoMixin {
  TransactionDao(super.db);

  Future<List<Transaction>> getAllTransactions(String userId) =>
      (select(transactions)..where((t) => t.userId.equals(userId))).get();

  Stream<List<Transaction>> watchAllTransactions(String userId) =>
      (select(transactions)..where((t) => t.userId.equals(userId))).watch();

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(TransactionsCompanion entry) =>
      update(transactions).replace(entry);

  Future<int> deleteTransaction(int id, String userId) =>
      (delete(transactions)
        ..where((t) => t.id.equals(id) & t.userId.equals(userId)))
          .go();
}