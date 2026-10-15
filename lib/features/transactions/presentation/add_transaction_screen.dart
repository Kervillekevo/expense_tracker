import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../auth/data/auth_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.existingTransaction});

  final Transaction? existingTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final AuthService _authService = AuthService();

  final formkey = GlobalKey<FormState>();
  TextEditingController amountController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  String selectedCategory = "Food";

  final List<String> typeOptions = ["Expense", "Income"];
  String selectedType = "Expense";

  DateTime selectedDate = DateTime.now();
  bool isSaving = false;

  bool get isEditing => widget.existingTransaction != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      amountController.text = existing.amount.toString();
      noteController.text = existing.note ?? '';
      selectedType = existing.type;
      selectedCategory = existing.category;
      selectedDate = existing.date;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.dark),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> save() async {
    if (!formkey.currentState!.validate()) return;

    final currentUser = _authService.getCurrentUser();
    if (currentUser == null) return;

    setState(() => isSaving = true);
    try {
      if (isEditing) {
        final updated = widget.existingTransaction!.copyWith(
          amount: double.parse(amountController.text.trim()),
          type: selectedType,
          category: selectedCategory,
          date: selectedDate,
          note: Value(noteController.text.trim()),
          updatedAt: DateTime.now(),
        );
        await DatabaseProvider.db.transactionDao.updateTransaction(
          updated.toCompanion(false),
        );
      } else {
        final entry = TransactionsCompanion.insert(
          userId: Value(currentUser.uid),
          amount: double.parse(amountController.text.trim()),
          type: selectedType,
          category: selectedCategory,
          date: selectedDate,
          note: Value(noteController.text.trim()),
        );
        await DatabaseProvider.db.transactionDao.insertTransaction(entry);
      }
      if (context.mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e"), backgroundColor: Colors.red),
        );
      }
    }
    if (mounted) setState(() => isSaving = false);
  }

  @override
  void dispose() {
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType == "Expense";
    final uid = _authService.getCurrentUser()?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          isEditing ? "Edit Transaction" : "Add Transaction",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Form(
        key: formkey,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 6, 22, 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Amount",
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    cursorColor: AppColors.accent,
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: "0.00",
                      hintStyle: TextStyle(color: Colors.white24),
                      prefixText: "KES  ",
                      prefixStyle: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorStyle: TextStyle(color: Color(0xFFFF8A80)),
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Enter an amount";
                      }
                      final parsed = double.tryParse(value);
                      if (parsed == null) {
                        return "Enter a valid number";
                      }
                      if (parsed <= 0) {
                        return "Enter a value greater than zero";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.sheet,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PillToggle(
                        options: typeOptions,
                        selected: selectedType,
                        onChanged: (type) => setState(() => selectedType = type),
                        activeColors: const {
                          "Expense": AppColors.expense,
                          "Income": AppColors.primary,
                        },
                      ),
                      const SizedBox(height: 22),
                      const _SectionLabel("Category"),
                      const SizedBox(height: 10),

                      // only this user's categories of the selected type
                      StreamBuilder<List<Category>>(
                        key: ValueKey(selectedType),
                        stream: DatabaseProvider.db.categoryDao
                            .watchCategoriesByType(uid, selectedType),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: LinearProgressIndicator(
                                minHeight: 2,
                                color: AppColors.primary,
                              ),
                            );
                          }

                          final categoryList = snapshot.data!;
                          if (categoryList.isEmpty) {
                            return Text(
                              "No $selectedType categories yet. Add one in Categories.",
                              style: const TextStyle(
                                color: AppColors.expense,
                                fontSize: 13,
                              ),
                            );
                          }

                          final names = categoryList.map((c) => c.name).toList();

                          // fall back to the first one if the selected category
                          // isn't in this list (type switched or category deleted)
                          if (!names.contains(selectedCategory)) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted) {
                                setState(() => selectedCategory = names.first);
                              }
                            });
                          }

                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: categoryList.map((category) {
                              final color = colorFromHex(category.color);
                              final isSelected = category.name == selectedCategory;
                              return GestureDetector(
                                onTap: () =>
                                    setState(() => selectedCategory = category.name),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 160),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.dark : Colors.white,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: isSelected ? AppColors.dark : AppColors.border,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        iconFromKey(category.icon),
                                        size: 16,
                                        color: isSelected ? AppColors.accent : color,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        category.name,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected ? Colors.white : AppColors.dark,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),

                      const SizedBox(height: 22),
                      const _SectionLabel("Note"),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: noteController,
                        decoration: fieldDecoration(
                          hint: "Add a note (optional)",
                          icon: Icons.edit_note_outlined,
                        ),
                      ),

                      const SizedBox(height: 22),
                      const _SectionLabel("Date"),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: AppColors.field,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                                style: const TextStyle(
                                  color: AppColors.dark,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.chevron_right, color: Colors.grey.shade400),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isExpense ? AppColors.expense : AppColors.dark,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: isSaving
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : Text(
                            isEditing
                                ? "Update"
                                : (isExpense ? "Save Expense" : "Save Income"),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppColors.dark,
      ),
    );
  }
}