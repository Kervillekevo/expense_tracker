import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, this.existingTransaction});

  final Transaction? existingTransaction;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _primary = Color(0xFF2E7D5B);
  static const _primaryDark = Color(0xFF0D3B2E);
  static const _fill = Color(0xFFF0F7F4);
  static const _border = Color(0xFFCDE7DB);
  static const _expenseColor = Color(0xFFC62828);

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
            colorScheme: const ColorScheme.light(primary: _primary),
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

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: _fill,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _expenseColor),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = selectedType == "Expense";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _primaryDark),
        title: Text(
          isEditing ? "Edit Transaction" : "Add Transaction",
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          child: Form(
            key: formkey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: _fill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: typeOptions.map((type) {
                      final selected = selectedType == type;
                      final color = type == "Expense" ? _expenseColor : _primary;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => selectedType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: selected ? color : Colors.transparent,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Text(
                              type,
                              textAlign: TextAlign.center,
                              style: TextStyle(
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

                const SizedBox(height: 24),

                Text(
                  "Amount",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _primaryDark,
                  ),
                  decoration: _decoration(
                    label: "0.00",
                    icon: Icons.attach_money,
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

                const SizedBox(height: 20),

                TextFormField(
                  controller: noteController,
                  decoration: _decoration(
                    label: "Note (optional)",
                    icon: Icons.note_add_outlined,
                  ),
                ),

                const SizedBox(height: 20),

                StreamBuilder<List<Category>>(
                  stream: DatabaseProvider.db.categoryDao.watchAllCategories(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: _primary,
                        ),
                      );
                    }

                    final categoryList = snapshot.data!;
                    if (categoryList.isEmpty) {
                      return const Text(
                        "No categories yet. Add one first.",
                        style: TextStyle(color: _expenseColor, fontSize: 13),
                      );
                    }

                    final names = categoryList.map((c) => c.name).toList();

                    // If the currently selected category no longer exists
                    // (e.g. it was deleted), fall back to the first available
                    // one instead of crashing the dropdown.
                    if (!names.contains(selectedCategory)) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() => selectedCategory = names.first);
                        }
                      });
                    }

                    return DropdownButtonFormField<String>(
                      initialValue:
                      names.contains(selectedCategory) ? selectedCategory : names.first,
                      decoration: _decoration(
                        label: "Category",
                        icon: Icons.category_outlined,
                      ),
                      items: names.map((name) {
                        return DropdownMenuItem(value: name, child: Text(name));
                      }).toList(),
                      onChanged: (value) => setState(() => selectedCategory = value!),
                    );
                  },
                ),

                const SizedBox(height: 20),

                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: _fill,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _border),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, color: _primary, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                          style: const TextStyle(
                            color: _primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isSaving ? null : save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isExpense ? _expenseColor : _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
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
    );
  }
}