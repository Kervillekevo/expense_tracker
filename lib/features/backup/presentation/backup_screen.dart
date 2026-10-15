import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../data/backup_service.dart';
import '../../auth/data/auth_service.dart';
import '../../../core/theme/app_theme.dart';

class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  final BackupService _backupService = BackupService();
  final AuthService _authService = AuthService();
  bool isExporting = false;
  bool isRestoring = false;

  Future<void> _export() async {
    final uid = _authService.getCurrentUser()?.uid;
    if (uid == null) return;

    setState(() => isExporting = true);
    try {
      final file = await _backupService.exportToFile(uid);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Expense Tracker backup',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Export failed: $e"), backgroundColor: AppColors.expense),
        );
      }
    }
    if (mounted) setState(() => isExporting = false);
  }

  Future<void> _restore() async {
    final uid = _authService.getCurrentUser()?.uid;
    if (uid == null) return;

    // file_picker v12+: FilePicker.pickFiles() is a static method that
    // returns a plain List<PlatformFile> directly (empty if canceled) —
    // no more FilePicker.platform, no more nullable FilePickerResult.
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty || files.first.path == null) return;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              "Restore",
              style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ) ??
        false;

    if (!confirmed) return;

    setState(() => isRestoring = true);
    try {
      final file = File(files.first.path!);
      final counts = await _backupService.restoreFromFile(file, uid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Restored ${counts.transactionsAdded} transactions and "
                  "${counts.categoriesAdded} categories.",
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Restore failed: $e"), backgroundColor: AppColors.expense),
        );
      }
    }
    if (mounted) setState(() => isRestoring = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.dark,
      appBar: AppBar(
        backgroundColor: AppColors.dark,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Backup & Restore",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          const _Hero(),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.sheet,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  28,
                  20,
                  MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SectionLabel("SAVE A COPY"),
                    const SizedBox(height: 10),
                    _ActionTile(
                      dark: true,
                      icon: Icons.cloud_upload_outlined,
                      title: "Export backup",
                      description: isExporting
                          ? "Preparing your file..."
                          : "Save everything to a file you can share, email or keep in the cloud.",
                      busy: isExporting,
                      onTap: _export,
                    ),
                    const SizedBox(height: 26),
                    const _SectionLabel("BRING DATA BACK"),
                    const SizedBox(height: 10),
                    _ActionTile(
                      dark: false,
                      icon: Icons.settings_backup_restore_rounded,
                      title: "Restore from file",
                      description: isRestoring
                          ? "Restoring your data..."
                          : "Pick a backup .json file and add its data back into the app.",
                      busy: isRestoring,
                      onTap: _restore,
                    ),
                    const SizedBox(height: 30),
                    const _SectionLabel("GOOD TO KNOW"),
                    const SizedBox(height: 14),
                    const _Tip(
                      icon: Icons.phone_android_rounded,
                      text: "Your data is stored only on this phone, so a lost or reset device means lost data.",
                    ),
                    const _Tip(
                      icon: Icons.add_circle_outline_rounded,
                      text: "Restoring adds to what you already have. Nothing gets overwritten.",
                    ),
                    const _Tip(
                      icon: Icons.category_outlined,
                      text: "Categories with the same name won't be duplicated.",
                    ),
                    const _Tip(
                      icon: Icons.event_repeat_rounded,
                      text: "Export a fresh backup every week or two to stay covered.",
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 6, 22, 28),
      child: Row(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.shield_outlined, color: AppColors.dark, size: 30),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Keep your data safe",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Back up your transactions and categories in a single file.",
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.35),
                ),
              ],
            ),
          ),
        ],
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
        fontSize: 11,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.1,
        color: AppColors.muted,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.dark,
    required this.icon,
    required this.title,
    required this.description,
    required this.busy,
    required this.onTap,
  });

  final bool dark;
  final IconData icon;
  final String title;
  final String description;
  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final titleColor = dark ? Colors.white : AppColors.dark;
    final bodyColor = dark ? Colors.white70 : AppColors.muted;
    final iconBox = dark ? AppColors.accent : AppColors.sheet;
    final iconColor = dark ? AppColors.dark : AppColors.primary;

    return Material(
      color: dark ? AppColors.dark : Colors.white,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: busy ? null : onTap,
        child: Stack(
          children: [
            if (dark)
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: iconBox,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: iconColor, size: 26),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: titleColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: TextStyle(fontSize: 12, height: 1.4, color: bodyColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  busy
                      ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: dark ? AppColors.accent : AppColors.primary,
                    ),
                  )
                      : Icon(
                    Icons.arrow_forward_rounded,
                    color: dark ? AppColors.accent : AppColors.muted,
                    size: 22,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: AppColors.dark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}