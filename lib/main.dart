import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_screen.dart';
import 'core/database/database_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Seeds default categories the first time the app runs.
  // Safe to call on every launch — it no-ops once categories already exist.
  await DatabaseProvider.db.categoryDao.seedDefaultCategories();

  Future<void> _seedDefaultCategories() async {
    final dao = DatabaseProvider.db.categoryDao;
    final existing = await dao.getAllCategories();
    if (existing.isEmpty) {
      final defaults = [
        ('Food', 'restaurant', '#EF6C00'),
        ('Transport', 'directions_car', '#1E88E5'),
        ('Entertainment', 'movie', '#7B61FF'),
        ('Rent', 'home', '#2E7D5B'),
        ('Salary', 'payments', '#2E7D5B'),
        ('Other', 'receipt_long', '#757575'),
      ];
      for (final (name, icon, color) in defaults) {
        await dao.insertCategory(
          CategoriesCompanion.insert(
            name: name,
            icon: icon,
            color: color,
            isDefault: const Value(true),
          ),
        );
      }
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expense Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const AuthGate(),
    );
  }
}

/// Decides which screen to show based on Firebase's own auth session state,
/// instead of always starting at LoginScreen.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Firebase is still checking whether a session was persisted from
        // a previous launch — show a brief loading state, not a screen flash.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D5B)),
            ),
          );
        }

        // snapshot.data is a User if signed in, or null if not.
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}