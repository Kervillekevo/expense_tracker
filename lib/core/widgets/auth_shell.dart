import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AuthShell extends StatelessWidget {
  const AuthShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  static const _background = Color(0xFFF3F9E8);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _Blob(size: 240, color: AppColors.accent.withValues(alpha: 0.5)),
          ),
          Positioned(
            bottom: -110,
            left: -80,
            child: _Blob(size: 240, color: AppColors.primary.withValues(alpha: 0.08)),
          ),
          SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Brand hero: takes the free height and centers itself
                        const Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: _Hero()),
                          ),
                        ),

                        // Form block
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 28,
                            height: 1.15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.dark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 24),
                        child,
                        const SizedBox(height: 16),
                        footer,
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 76,
          height: 76,
          decoration: BoxDecoration(
            color: AppColors.dark,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.dark.withValues(alpha: 0.18),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_outlined,
            color: AppColors.accent,
            size: 38,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          "Expense Tracker",
          style: TextStyle(
            color: AppColors.dark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class AuthLabel extends StatelessWidget {
  const AuthLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.dark,
        ),
      ),
    );
  }
}

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.dark,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.dark.withValues(alpha: 0.7),
          disabledForegroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: loading
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        )
            : Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.text,
    required this.action,
    required this.onTap,
  });

  final String text;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text.rich(
            TextSpan(
              text: "$text ",
              style: const TextStyle(color: AppColors.muted, fontSize: 14),
              children: [
                TextSpan(
                  text: action,
                  style: const TextStyle(
                    color: AppColors.dark,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.accent,
                    decorationThickness: 2,
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