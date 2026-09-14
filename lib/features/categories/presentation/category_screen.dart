import 'package:flutter/material.dart';
import 'package:drift/drift.dart' show Value;
import '../../../core/database/database_provider.dart';
import '../../../core/database/app_database.dart';
import '../../../core/utils/category_icons.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key});

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  static const _primary = Color(0xFF2E7D5B);
  static const _primaryDark = Color(0xFF0D3B2E);
  static const _fill = Color(0xFFF0F7F4);
  static const _border = Color(0xFFCDE7DB);
  static const _expenseColor = Color(0xFFC62828);

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
    if (category.isDefault) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Default categories can't be deleted."),
          backgroundColor: _expenseColor,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete category?"),
        content: Text(
          "Existing transactions using '${category.name}' will keep "
              "showing that name, with a generic icon instead.",
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

    if (confirmed) {
      await DatabaseProvider.db.categoryDao.deleteCategory(category.id);
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

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: _primaryDark),
        title: const Text(
          "Categories",
          style: TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Category>>(
          stream: DatabaseProvider.db.categoryDao.watchAllCategories(),
          builder: (context, snapshot) {
            final categories = snapshot.data ?? [];
            final expenseCategories =
            categories.where((c) => c.type == "Expense").toList();
            final incomeCategories =
            categories.where((c) => c.type == "Income").toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Your categories",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Tap to edit \u00b7 swipe to delete",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),

                  if (!snapshot.hasData)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else ...[
                    if (expenseCategories.isNotEmpty) ...[
                      Text(
                        "EXPENSE",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...expenseCategories.map(_buildCategoryTile),
                      const SizedBox(height: 16),
                    ],
                    if (incomeCategories.isNotEmpty) ...[
                      Text(
                        "INCOME",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...incomeCategories.map(_buildCategoryTile),
                    ],
                  ],

                  const SizedBox(height: 28),
                  Divider(color: Colors.grey.shade200),
                  const SizedBox(height: 20),

                  Text(
                    _editingCategory != null ? "Edit category" : "New category",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _primaryDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  Form(
                    key: formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Type",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                              final color =
                              type == "Expense" ? _expenseColor : _primary;
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
                                        color: selected
                                            ? Colors.white
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextFormField(
                          controller: categoryNameController,
                          decoration: _decoration("Category name"),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Name required";
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Icon",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
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
                                      : _fill,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? activeColor : _border,
                                    width: isSelected ? 2 : 1,
                                  ),
                                ),
                                child: Icon(
                                  entry.value,
                                  color: isSelected ? activeColor : Colors.grey.shade600,
                                  size: 20,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 20),
                        const Text(
                          "Color",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
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
                                      ? Border.all(color: _primaryDark, width: 3)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 28),

                        Row(
                          children: [
                            Expanded(
                              child: SizedBox(
                                height: 50,
                                child: ElevatedButton(
                                  onPressed: _save,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _primary,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: Text(
                                    _editingCategory != null ? "Update" : "Add category",
                                  ),
                                ),
                              ),
                            ),
                            if (_editingCategory != null) ...[
                              const SizedBox(width: 12),
                              TextButton(
                                onPressed: _resetForm,
                                child: const Text("Cancel"),
                              ),
                            ],
                          ],
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
            color: _expenseColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          await _handleDelete(category);
          return false;
        },
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _startEditing(category),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isEditingThis ? color.withValues(alpha: 0.12) : _fill,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isEditingThis ? color : _border,
                width: isEditingThis ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
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
                      color: _primaryDark,
                    ),
                  ),
                ),
                if (category.isDefault)
                  Text(
                    "Default",
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  )
                else
                  Icon(Icons.chevron_right, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }
}