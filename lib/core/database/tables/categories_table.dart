import 'package:drift/drift.dart';

class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get userId => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get color => text()();
  TextColumn get type => text().withDefault(const Constant('Expense'))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
}