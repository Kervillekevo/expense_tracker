import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../auth/data/auth_service.dart';
import '../../auth/presentation/login_screen.dart';
import '../../transactions/presentation/add_transaction_screen.dart';
import '../../categories/presentation/category_screen.dart';
import '../../backup/presentation/backup_screen.dart';
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';

enum _Period { today, week, month, all }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  static const Map<_Period, String> _periodLabels = {
    _Period.today: "Today",
    _Period.week: "Week",
    _Period.month: "Month",
    _Period.all: "All",
  };

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  _Period selectedPeriod = _Period.month;
  bool hideBalance = false;

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

  String _dayLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return "Today";
    if (diff == 1) return "Yesterday";
    return "${_days[date.weekday - 1]}, ${date.day} ${_months[date.month - 1]}";
  }

  String _trendLabel() {
    switch (selectedPeriod) {
      case _Period.today:
        return "Last 7 days";
      case _Period.week:
        return "This week";
      case _Period.month:
        return "This month";
      case _Period.all:
        return "By month";
    }
  }

  double _sumRange(List<Transaction> all, String type, DateTime start, DateTime end) {
    double total = 0;
    for (final tx in all) {
      if (tx.type != type) continue;
      if (!tx.date.isBefore(start) && tx.date.isBefore(end)) total += tx.amount;
    }
    return total;
  }

  List<double> _trend(List<Transaction> all, String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (selectedPeriod == _Period.all) {
      var first = DateTime(now.year, now.month);
      for (final tx in all) {
        final m = DateTime(tx.date.year, tx.date.month);
        if (m.isBefore(first)) first = m;
      }
      var start = DateTime(now.year, now.month - 11);
      if (first.isAfter(start)) start = first;
      if (start.year == now.year && start.month == now.month) {
        start = DateTime(now.year, now.month - 1);
      }
      final points = <double>[];
      for (var m = start; !m.isAfter(DateTime(now.year, now.month)); m = DateTime(m.year, m.month + 1)) {
        points.add(_sumRange(all, type, m, DateTime(m.year, m.month + 1)));
      }
      return points;
    }

    late DateTime start;
    switch (selectedPeriod) {
      case _Period.today:
        start = DateTime(today.year, today.month, today.day - 6);
        break;
      case _Period.week:
        start = DateTime(today.year, today.month, today.day - (now.weekday - 1));
        break;
      default:
        start = DateTime(today.year, today.month, 1);
    }
    if (!start.isBefore(today)) {
      start = DateTime(today.year, today.month, today.day - 1);
    }

    final points = <double>[];
    for (var d = start; !d.isAfter(today); d = DateTime(d.year, d.month, d.day + 1)) {
      points.add(_sumRange(all, type, d, DateTime(d.year, d.month, d.day + 1)));
    }
    return points;
  }

  // % change against the previous day / week / month
  double? _change(List<Transaction> all, String type) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    late DateTime curStart, curEnd, prevStart;

    switch (selectedPeriod) {
      case _Period.today:
        curStart = today;
        curEnd = DateTime(today.year, today.month, today.day + 1);
        prevStart = DateTime(today.year, today.month, today.day - 1);
        break;
      case _Period.week:
        curStart = DateTime(today.year, today.month, today.day - (now.weekday - 1));
        curEnd = DateTime(curStart.year, curStart.month, curStart.day + 7);
        prevStart = DateTime(curStart.year, curStart.month, curStart.day - 7);
        break;
      case _Period.month:
        curStart = DateTime(now.year, now.month, 1);
        curEnd = DateTime(now.year, now.month + 1, 1);
        prevStart = DateTime(now.year, now.month - 1, 1);
        break;
      case _Period.all:
        return null;
    }

    final current = _sumRange(all, type, curStart, curEnd);
    final previous = _sumRange(all, type, prevStart, curStart);
    if (previous == 0) return null;
    return (current - previous) / previous * 100;
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
        backgroundColor: AppColors.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete transaction?"),
        content: Text(
          "This will permanently delete '${tx.category}' (${_formatAmount(tx.amount)}).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Delete",
              style: TextStyle(color: AppColors.expense, fontWeight: FontWeight.bold),
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
      backgroundColor: AppColors.dark,
      body: SafeArea(
        bottom: false,
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

                // flatten into day headers + transactions for one lazy list
                final List<Object> rows = [];
                DateTime? lastDay;
                for (final tx in transactions) {
                  final day = DateTime(tx.date.year, tx.date.month, tx.date.day);
                  if (lastDay == null || day != lastDay) {
                    rows.add(day);
                    lastDay = day;
                  }
                  rows.add(tx);
                }

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(displayName),
                            const SizedBox(height: 26),
                            Text(
                              "Balance · ${_periodLabels[selectedPeriod]}",
                              style: const TextStyle(color: Colors.white60, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 6, right: 8),
                                  child: Text(
                                    "KES",
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      hideBalance ? "••••••" : _formatAmount(balance),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 38,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => setState(() => hideBalance = !hideBalance),
                                  icon: Icon(
                                    hideBalance
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: _TrendCard(
                                    label: "Income",
                                    subLabel: _trendLabel(),
                                    amount: hideBalance ? "••••" : _formatAmount(totalIncome),
                                    icon: Icons.arrow_downward_rounded,
                                    background: AppColors.accent,
                                    lineColor: const Color(0xFF1B8F6A),
                                    values: _trend(allTransactions, "Income"),
                                    changePct: _change(allTransactions, "Income"),
                                    upIsGood: true,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _TrendCard(
                                    label: "Spendings",
                                    subLabel: _trendLabel(),
                                    amount: hideBalance ? "••••" : _formatAmount(totalExpense),
                                    icon: Icons.arrow_upward_rounded,
                                    background: AppColors.sheet,
                                    lineColor: const Color(0xFFE5573E),
                                    values: _trend(allTransactions, "Expense"),
                                    changePct: _change(allTransactions, "Expense"),
                                    upIsGood: false,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                        decoration: const BoxDecoration(
                          color: AppColors.sheet,
                          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            PillToggle(
                              options: _periodLabels.values.toList(),
                              selected: _periodLabels[selectedPeriod]!,
                              onChanged: (label) => setState(() {
                                selectedPeriod = _periodLabels.entries
                                    .firstWhere((e) => e.value == label)
                                    .key;
                              }),
                            ),
                            const SizedBox(height: 18),
                            if (expenseByCategory.isNotEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(22),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      "Spending by category",
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.dark,
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
                            const SizedBox(height: 22),
                            const Text(
                              "Transactions",
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.dark,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Tap to edit · swipe to delete",
                              style: TextStyle(fontSize: 11, color: AppColors.muted),
                            ),
                            const SizedBox(height: 6),
                          ],
                        ),
                      ),
                    ),

                    if (!snapshot.hasData)
                      _fillSheet(
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ),
                        ),
                      )
                    else if (allTransactions.isEmpty)
                      _fillSheet(_emptyState(
                        Icons.receipt_long_outlined,
                        "No transactions yet",
                        "Tap + to add your first one",
                      ))
                    else if (transactions.isEmpty)
                        _fillSheet(_emptyState(
                          Icons.event_busy_outlined,
                          "No transactions this ${_periodLabels[selectedPeriod]!.toLowerCase()}",
                          null,
                        ))
                      else ...[
                          SliverList.builder(
                            itemCount: rows.length,
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              if (row is DateTime) {
                                return Container(
                                  color: AppColors.sheet,
                                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                                  child: Text(
                                    _dayLabel(row),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                );
                              }
                              return Container(
                                color: AppColors.sheet,
                                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                                child: _buildTransactionTile(
                                  row as Transaction,
                                  uid,
                                  categoryByName,
                                ),
                              );
                            },
                          ),
                          _fillSheet(const SizedBox(height: 90)),
                        ],
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
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.dark,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _fillSheet(Widget child) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(color: AppColors.sheet, child: child),
    );
  }

  Widget _emptyState(IconData icon, String title, String? hint) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 46, color: AppColors.border),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
          ),
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint, style: const TextStyle(color: AppColors.muted, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildTopBar(String? displayName) {
    final name = displayName != null && displayName.isNotEmpty ? displayName : "Welcome back";
    final initial = name.characters.first.toUpperCase();

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            initial,
            style: const TextStyle(
              color: AppColors.dark,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "${_greeting()} \u{1F44B}",
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
          ),
          color: AppColors.sheet,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          onSelected: (value) {
            switch (value) {
              case 'categories':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CategoryScreen()),
                );
                break;
              case 'backup':
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BackupScreen()),
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
                  Icon(Icons.category_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 10),
                  Text("Manage categories"),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'backup',
              child: Row(
                children: [
                  Icon(Icons.backup_outlined, size: 18, color: AppColors.primary),
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
                  Icon(Icons.logout, size: 18, color: AppColors.expense),
                  SizedBox(width: 10),
                  Text("Log out", style: TextStyle(color: AppColors.expense)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTransactionTile(
      Transaction tx,
      String uid,
      Map<String, Category> categoryByName,
      ) {
    final isExpense = tx.type == "Expense";
    final amountColor = isExpense ? AppColors.expense : AppColors.income;
    final categoryColor = _colorForTx(tx.category, categoryByName);

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.expense,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(tx),
      onDismissed: (_) {
        DatabaseProvider.db.transactionDao.deleteTransaction(tx.id, uid);
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddTransactionScreen(existingTransaction: tx),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: categoryColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconForTx(tx.category, categoryByName),
                    color: categoryColor,
                    size: 22,
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
                          color: AppColors.dark,
                        ),
                      ),
                      if (tx.note != null && tx.note!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tx.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
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
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({
    required this.label,
    required this.subLabel,
    required this.amount,
    required this.icon,
    required this.background,
    required this.lineColor,
    required this.values,
    required this.changePct,
    required this.upIsGood,
  });

  final String label;
  final String subLabel;
  final String amount;
  final IconData icon;
  final Color background;
  final Color lineColor;
  final List<double> values;
  final double? changePct;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.dark,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: background, size: 14),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: AppColors.dark,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subLabel,
                      style: TextStyle(
                        color: AppColors.dark.withValues(alpha: 0.55),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: const TextStyle(
                color: AppColors.dark,
                fontWeight: FontWeight.bold,
                fontSize: 19,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 20,
            child: Align(
              alignment: Alignment.centerLeft,
              child: changePct == null ? null : _ChangeBadge(pct: changePct!, upIsGood: upIsGood),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 62,
            child: _Sparkline(values: values, color: lineColor),
          ),
        ],
      ),
    );
  }
}

class _ChangeBadge extends StatelessWidget {
  const _ChangeBadge({required this.pct, required this.upIsGood});

  final double pct;
  final bool upIsGood;

  @override
  Widget build(BuildContext context) {
    final isUp = pct >= 0;
    final isGood = upIsGood ? isUp : !isUp;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFF1B8F5A) : AppColors.expense,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            color: Colors.white,
            size: 10,
          ),
          const SizedBox(width: 2),
          Text(
            "${pct.abs().toStringAsFixed(1)}%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(0, (a, b) => a > b ? a : b);
    final top = maxValue == 0 ? 1.0 : maxValue * 1.25;
    final average =
    values.isEmpty ? 0.0 : values.reduce((a, b) => a + b) / values.length;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (values.length - 1).toDouble(),
        minY: 0,
        maxY: top,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: average,
              color: color.withValues(alpha: 0.5),
              strokeWidth: 1,
              dashArray: [4, 4],
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (int i = 0; i < values.length; i++) FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            curveSmoothness: 0.25,
            preventCurveOverShooting: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.35),
                  color.withValues(alpha: 0.03),
                ],
              ),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 300),
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
          width: 120,
          height: 120,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sections: sortedEntries.map((e) {
                    return PieChartSectionData(
                      value: e.value,
                      color: colorForCategory(e.key),
                      radius: 16,
                      showTitle: false,
                    );
                  }).toList(),
                  sectionsSpace: 3,
                  centerSpaceRadius: 42,
                ),
                duration: const Duration(milliseconds: 400),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatAmount(total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const Text(
                      "spent",
                      style: TextStyle(fontSize: 10, color: AppColors.muted),
                    ),
                  ],
                ),
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
                      width: 10,
                      height: 10,
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
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    Text(
                      "${pct.toStringAsFixed(0)}%",
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
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