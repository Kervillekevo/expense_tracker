import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/backup_service.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  static const _primary = Color(0xFF2E7D5B);
  static const _primaryDark = Color(0xFF0D3B2E);
  static const _fill = Color(0xFFF0F7F4);
  static const _border = Color(0xFFCDE7DB);
  static const _expenseColor = Color(0xFFC62828);

  final BackupService _backupService = BackupService();
  bool isExporting = false;
  bool isRestoring = false;

  Future<void> _export() async {
    setState(() => isExporting = true);
    try {
      final file = await _backupService.exportToFile();
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Expense Tracker backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e"), backgroundColor: _expenseColor),
        );
      }
    }
    if (mounted) setState(() => isExporting = false);
  }

  Future<void> _restore() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.single.path == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Restore backup?"),
        content: const Text(
          "This adds all transactions and categories from the backup "
              "file into your current data. Existing categories with the "
              "same name won't be duplicated, but transactions will be "
              "added as new entries.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Restore",
              style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    setState(() => isRestoring = true);
    try {
      final file = File(result.files.single.path!);
      final counts = await _backupService.restoreFromFile(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Restored ${counts.transactionsAdded} transactions and "
                  "${counts.categoriesAdded} categories.",
            ),
            backgroundColor: _primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restore failed: $e"), backgroundColor: _expenseColor),
        );
      }
    }
    if (mounted) setState(() => isRestoring = false);
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
          "Backup & Restore",
          style: TextStyle(color: _primaryDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _fill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: _primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Your data lives only on this device. Export a "
                            "backup regularly so you don't lose it if something "
                            "happens to your phone.",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                "Export backup",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDark),
              ),
              const SizedBox(height: 6),
              Text(
                "Saves all your transactions and categories to a file you "
                    "can share, email, or save to cloud storage.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: isExporting ? null : _export,
                  icon: isExporting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Icon(Icons.upload_file_outlined),
                  label: Text(isExporting ? "Preparing..." : "Export backup"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Divider(color: Colors.grey.shade200),
              const SizedBox(height: 24),

              const Text(
                "Restore backup",
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _primaryDark),
              ),
              const SizedBox(height: 6),
              Text(
                "Pick a previously exported .json file to add its data "
                    "back into the app.",
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: isRestoring ? null : _restore,
                  icon: isRestoring
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: _primary, strokeWidth: 2),
                  )
                      : const Icon(Icons.download_outlined, color: _primary),
                  label: Text(
                    isRestoring ? "Restoring..." : "Restore from file",
                    style: const TextStyle(color: _primary),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: _primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}