import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/category_icons.dart';
import '../../auth/data/auth_service.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final AuthService _authService = AuthService();

  final formkey = GlobalKey<FormState>();
  final TextEditingController categoryNameController = TextEditingController();

  final List<String> typeOptions = ["Expense", "Income"];
  String selectedType = "Expense";
  String selectedIconKey = categoryIconOptions.keys.first;
  String selectedColorHex = categoryColorOptions.first;

  Category? _editingCategory;

  void _startEditing(Category category) {
    setState(() {
      _editingCategory = category;
      categoryNameController.text = category.name;
      selectedType = category.type;
      selectedIconKey = category.icon;
      selectedColorHex = category.color;
    });
  }

  void _resetForm() {
    setState(() {
      _editingCategory = null;
      categoryNameController.clear();
      selectedType = "Expense";
      selectedIconKey = categoryIconOptions.keys.first;
      selectedColorHex = categoryColorOptions.first;
    });
  }

  Future<void> _save() async {
    if (!formkey.currentState!.validate()) return;

    final uid = _authService.getCurrentUser()?.uid;
    if (uid == null) return;

    if (_editingCategory != null) {
      final updated = _editingCategory!.copyWith(
        name: categoryNameController.text.trim(),
        icon: selectedIconKey,
        color: selectedColorHex,
        type: selectedType,
      );
      await DatabaseProvider.db.categoryDao.updateCategory(
        updated.toCompanion(false),
      );
    } else {
      await DatabaseProvider.db.categoryDao.insertCategory(
        CategoriesCompanion.insert(
          userId: Value(uid),
          name: categoryNameController.text.trim(),
          icon: selectedIconKey,
          color: selectedColorHex,
          type: Value(selectedType),
        ),
      );
    }

    if (mounted) _resetForm();
  }

  Future<void> _handleDelete(Category category) async {
    final uid = _authService.getCurrentUser()?.uid;
    if (uid == null) return;

    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Default categories can't be deleted."),
          backgroundColor: AppColors.expense,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.sheet,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete category?"),
        content: Text(
          "Existing transactions using '${category.name}' will keep "
              "showing that name, with a generic icon instead.",
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

    if (confirmed) {
      await DatabaseProvider.db.categoryDao.deleteCategory(category.id, uid);
      if (_editingCategory?.id == category.id) {
        _resetForm();
      }
    }
  }

  @override
  void dispose() {
    categoryNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Categories",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 8),
        decoration: const BoxDecoration(
          color: AppColors.sheet,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: StreamBuilder<List<Category>>(
          stream: DatabaseProvider.db.categoryDao.watchAllCategories(uid),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            final expenseCategories =
            categories.where((c) => c.type == "Expense").toList();
            final incomeCategories =
            categories.where((c) => c.type == "Income").toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your categories",
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
                  const SizedBox(height: 16),

                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      ),
                    )
                  else ...[
                    if (expenseCategories.isNotEmpty) ...[
                      const _GroupLabel("EXPENSE"),
                      const SizedBox(height: 8),
                      ...expenseCategories.map(_buildCategoryTile),
                      const SizedBox(height: 14),
                    ],
                    if (incomeCategories.isNotEmpty) ...[
                      const _GroupLabel("INCOME"),
                      const SizedBox(height: 8),
                      ...incomeCategories.map(_buildCategoryTile),
                    ],
                  ],

                  const SizedBox(height: 26),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _editingCategory != null ? "Edit category" : "New category",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Form(
                          key: formkey,
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
                              const SizedBox(height: 18),
                              TextFormField(
                                controller: categoryNameController,
                                decoration: fieldDecoration(hint: "Category name"),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Name required";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const _GroupLabel("ICON"),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: categoryIconOptions.entries.map((entry) {
                                  final isSelected = selectedIconKey == entry.key;
                                  final activeColor = colorFromHex(selectedColorHex);
                                  return GestureDetector(
                                    onTap: () => setState(() => selectedIconKey = entry.key),
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? activeColor.withValues(alpha: 0.15)
                                            : AppColors.field,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: isSelected ? activeColor : AppColors.border,
                                          width: isSelected ? 2 : 1,
                                        ),
                                      ),
                                      child: Icon(
                                        entry.value,
                                        color: isSelected ? activeColor : AppColors.muted,
                                        size: 20,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 18),
                              const _GroupLabel("COLOR"),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: categoryColorOptions.map((hex) {
                                  final isSelected = selectedColorHex == hex;
                                  return GestureDetector(
                                    onTap: () => setState(() => selectedColorHex = hex),
                                    child: Container(
                                      width: 36,
                                      height: 36,
                                      decoration: BoxDecoration(
                                        color: colorFromHex(hex),
                                        shape: BoxShape.circle,
                                        border: isSelected
                                            ? Border.all(color: AppColors.dark, width: 3)
                                            : null,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _save,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.dark,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                        ),
                                        child: Text(
                                          _editingCategory != null ? "Update" : "Add category",
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (_editingCategory != null) ...[
                                    const SizedBox(width: 12),
                                    TextButton(
                                      onPressed: _resetForm,
                                      child: const Text(
                                        "Cancel",
                                        style: TextStyle(color: AppColors.muted),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category) {
    final color = colorFromHex(category.color);
    final isEditingThis = _editingCategory?.id == category.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(category.id),
        direction: category.isDefault
            ? DismissDirection.none
            : DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: AppColors.expense,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          await _handleDelete(category);
          return false;
        },
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _startEditing(category),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isEditingThis ? color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconFromKey(category.icon), color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.dark,
                      ),
                    ),
                  ),
                  if (category.isDefault)
                    const Text(
                      "Default",
                      style: TextStyle(fontSize: 11, color: AppColors.muted),
                    )
                  else
                    Icon(Icons.chevron_right, color: Colors.grey.shade400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1,
        color: AppColors.muted,
      ),
    );
  }
}