import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../categories/presentation/category_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/category_icons.dart';

enum _Period { today, week, month, all }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  static const _primary = Color(0xFF2E7D5B);
  static const _primaryDark = Color(0xFF0D3B2E);
  static const _fill = Color(0xFFF0F7F4);
  static const _border = Color(0xFFCDE7DB);
  static const _expenseColor = Color(0xFFC62828);
  static const _incomeColor = Color(0xFF2E7D5B);

  static const Map<_Period, String> _periodLabels = {
    _Period.today: "Today",
    _Period.week: "Week",
    _Period.month: "Month",
    _Period.all: "All",
  };

  _Period selectedPeriod = _Period.month;

  @override
  void initState() {
    super.initState();
    final uid = _authService.getCurrentUser()?.uid;
    if (uid != null) {
      DatabaseProvider.db.categoryDao.seedDefaultCategories(uid);
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return "Good morning";
    if (hour < 17) return "Good afternoon";
    return "Good evening";
  }

  bool _isInPeriod(DateTime date, _Period period) {
    final now = DateTime.now();
    switch (period) {
      case _Period.today:
        return date.year == now.year && date.month == now.month && date.day == now.day;
      case _Period.week:
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final startOfWeekDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        return !date.isBefore(startOfWeekDate);
      case _Period.month:
        return date.year == now.year && date.month == now.month;
      case _Period.all:
        return true;
    }
  }

  String _formatAmount(double amount) {
    final isNegative = amount < 0;
    final fixed = amount.abs().toStringAsFixed(2);
    final parts = fixed.split('.');
    final wholeDigits = parts[0];
    final buffer = StringBuffer();
    for (int i = 0; i < wholeDigits.length; i++) {
      final posFromEnd = wholeDigits.length - i;
      buffer.write(wholeDigits[i]);
      if (posFromEnd > 1 && posFromEnd % 3 == 1) buffer.write(',');
    }
    return '${isNegative ? '-' : ''}$buffer.${parts[1]}';
  }

  IconData _iconForTx(String categoryName, Map<String, Category> byName) {
    final category = byName[categoryName];
    if (category == null) return Icons.receipt_long_outlined;
    return iconFromKey(category.icon);
  }

  Color _colorForTx(String categoryName, Map<String, Category> byName) {
    final category = byName[categoryName];
    if (category == null) {
      final hue = (categoryName.hashCode % 360).toDouble().abs();
      return HSLColor.fromAHSL(1, hue, 0.55, 0.5).toColor();
    }
    return colorFromHex(category.color);
  }

  Future<bool> _confirmDelete(Transaction tx) async {
    return await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete transaction?"),
        content: Text(
          "This will permanently delete '${tx.category}' (${_formatAmount(tx.amount)}).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: _expenseColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.getCurrentUser();
    final uid = currentUser?.uid;
    final displayName = currentUser?.displayName;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<List<Category>>(
          stream: DatabaseProvider.db.categoryDao.watchAllCategories(uid),
          builder: (context, categorySnapshot) {
            final categoryByName = {
              for (final c in categorySnapshot.data ?? <Category>[]) c.name: c,
            };

            return StreamBuilder<List<Transaction>>(
              stream: DatabaseProvider.db.transactionDao.watchAllTransactions(uid),
              builder: (context, snapshot) {
                final allTransactions = snapshot.data ?? [];
                final transactions = allTransactions
                    .where((tx) => _isInPeriod(tx.date, selectedPeriod))
                    .toList();

                double totalIncome = 0;
                double totalExpense = 0;
                final Map<String, double> expenseByCategory = {};
                for (final tx in transactions) {
                  if (tx.type == "Income") {
                    totalIncome += tx.amount;
                  } else {
                    totalExpense += tx.amount;
                    expenseByCategory[tx.category] =
                        (expenseByCategory[tx.category] ?? 0) + tx.amount;
                  }
                }
                final balance = totalIncome - totalExpense;

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${_greeting()} \u{1F44B}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        displayName != null && displayName.isNotEmpty
                                            ? displayName
                                            : "Welcome back",
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                          color: _primaryDark,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: _fill,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: _border),
                                    ),
                                    child: const Icon(
                                      Icons.more_vert,
                                      color: _primaryDark,
                                      size: 20,
                                    ),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'categories':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const CategoryScreen(),
                                          ),
                                        );
                                        break;
                                      case 'backup':
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => const BackupScreen(),
                                          ),
                                        );
                                        break;
                                      case 'logout':
                                        logout();
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    const PopupMenuItem(
                                      value: 'categories',
                                      child: Row(
                                        children: [
                                          Icon(Icons.category_outlined, size: 18, color: _primary),
                                          SizedBox(width: 10),
                                          Text("Manage categories"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuItem(
                                      value: 'backup',
                                      child: Row(
                                        children: [
                                          Icon(Icons.backup_outlined, size: 18, color: _primary),
                                          SizedBox(width: 10),
                                          Text("Backup & restore"),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem(
                                      value: 'logout',
                                      child: Row(
                                        children: [
                                          Icon(Icons.logout, size: 18, color: _expenseColor),
                                          SizedBox(width: 10),
                                          Text("Log out", style: TextStyle(color: _expenseColor)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [_primary, _primaryDark],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primary.withValues(alpha: 0.28),
                                    blurRadius: 20,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      right: -30,
                                      top: -30,
                                      child: Container(
                                        width: 130,
                                        height: 130,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.06),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 30,
                                      bottom: -60,
                                      child: Container(
                                        width: 110,
                                        height: 110,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withValues(alpha: 0.05),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(22),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(8),
                                                decoration: BoxDecoration(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons.account_balance_wallet_outlined,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                              const SizedBox(width: 10),
                                              Text(
                                                "Balance \u00b7 ${_periodLabels[selectedPeriod]}",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            "KES ${_formatAmount(balance)}",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 30,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: -0.5,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _SummaryPill(
                                                  icon: Icons.arrow_downward_rounded,
                                                  label: "Income",
                                                  amount: _formatAmount(totalIncome),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _SummaryPill(
                                                  icon: Icons.arrow_upward_rounded,
                                                  label: "Expenses",
                                                  amount: _formatAmount(totalExpense),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _fill,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: Row(
                                children: _Period.values.map((period) {
                                  final selected = selectedPeriod == period;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => selectedPeriod = period),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 180),
                                        padding: const EdgeInsets.symmetric(vertical: 9),
                                        decoration: BoxDecoration(
                                          color: selected ? _primary : Colors.transparent,
                                          borderRadius: BorderRadius.circular(11),
                                        ),
                                        child: Text(
                                          _periodLabels[period]!,
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: selected ? Colors.white : Colors.grey.shade600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 20),

                            if (expenseByCategory.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: _fill,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: _border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.03),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Spending by category",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: _primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    _CategoryDonutChart(
                                      categoryTotals: expenseByCategory,
                                      colorForCategory: (name) =>
                                          _colorForTx(name, categoryByName),
                                      formatAmount: _formatAmount,
                                    ),
                                  ],
                                ),
                              ),

                            const SizedBox(height: 24),

                            const Text(
                              "Transactions",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _primaryDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Tap to edit \u00b7 swipe to delete",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),

                    if (!snapshot.hasData)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: _primary),
                          ),
                        ),
                      )
                    else if (allTransactions.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "No transactions yet",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Tap + to add your first one",
                                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (transactions.isEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.event_busy_outlined,
                                  size: 44,
                                  color: Colors.grey.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  "No transactions this ${_periodLabels[selectedPeriod]!.toLowerCase()}",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          sliver: SliverList.separated(
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final tx = transactions[index];
                              final isExpense = tx.type == "Expense";
                              final amountColor = isExpense ? _expenseColor : _incomeColor;
                              final categoryColor = _colorForTx(tx.category, categoryByName);

                              return Dismissible(
                                key: ValueKey(tx.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    color: _expenseColor,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.delete_outline, color: Colors.white),
                                ),
                                confirmDismiss: (_) => _confirmDelete(tx),
                                onDismissed: (_) {
                                  DatabaseProvider.db.transactionDao.deleteTransaction(tx.id, uid);
                                },
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            AddTransactionScreen(existingTransaction: tx),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: _fill,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: _border),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.02),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: categoryColor.withValues(alpha: 0.14),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            _iconForTx(tx.category, categoryByName),
                                            color: categoryColor,
                                            size: 20,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                tx.category,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: _primaryDark,
                                                ),
                                              ),
                                              if (tx.note != null && tx.note!.isNotEmpty) ...[
                                                const SizedBox(height: 2),
                                                Text(
                                                  tx.note!,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                              const SizedBox(height: 2),
                                              Text(
                                                "${tx.date.day}/${tx.date.month}/${tx.date.year}",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "${isExpense ? '-' : '+'}${_formatAmount(tx.amount)}",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: amountColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  ],
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        backgroundColor: _primary,
        elevation: 3,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.amount,
  });

  final IconData icon;
  final String label;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryDonutChart extends StatelessWidget {
  const _CategoryDonutChart({
    required this.categoryTotals,
    required this.colorForCategory,
    required this.formatAmount,
  });

  final Map<String, double> categoryTotals;
  final Color Function(String) colorForCategory;
  final String Function(double) formatAmount;

  @override
  Widget build(BuildContext context) {
    final total = categoryTotals.values.fold<double>(0, (a, b) => a + b);
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sortedEntries.map((e) {
                    return PieChartSectionData(
                      value: e.value,
                      color: colorForCategory(e.key),
                      radius: 18,
                      showTitle: false,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                ),
                duration: const Duration(milliseconds: 400),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatAmount(total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0D3B2E),
                    ),
                  ),
                  Text(
                    "spent",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 18),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sortedEntries.take(5).map((e) {
              final pct = total > 0 ? (e.value / total * 100) : 0.0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: colorForCategory(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        e.key,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D3B2E),
                        ),
                      ),
                    ),
                    Text(
                      "${pct.toStringAsFixed(0)}%",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}