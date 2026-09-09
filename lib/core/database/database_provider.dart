import 'app_database.dart';
class DatabaseProvider {
  static final AppDatabase db = AppDatabase();

}
//DatabaseProvider is a single shared gateway — instead of every screen
//"reaching directly" into a new database connection,
    //they all go through this one door, guaranteeing
//they're all talking to the same underlying connection.
//AppDatabase represents an actual open connection to a SQLite file on disk.