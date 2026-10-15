import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../home/presentation/home_screen.dart';
import 'register_screen.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isGoogleLoading = false;
  bool obscurePassword = true;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }

  void _goHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (!mounted) return;
      _goHome();
      return;
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => isLoading = false);
  }

  Future<void> _googleSignIn() async {
    setState(() => isGoogleLoading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (result != null && mounted) {
        _goHome();
        return;
      }
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => isGoogleLoading = false);
  }

  void _submit() {
    if (isLoading) return;
    if (_formKey.currentState!.validate()) login();
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: emailController.text.trim(),
    );
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Reset Password",
          style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Enter your email here and we will send an email to update your password",
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetEmailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration(hint: "Email address"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel", style: TextStyle(color: AppColors.muted)),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(dialogContext);

              try {
                await _authService.resetPassword(email);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Password reset email sent! Check your inbox."),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                _showError(e);
              }
            },
            child: const Text(
              "Send Reset Link",
              style: TextStyle(color: AppColors.dark, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    ).then((_) => resetEmailController.dispose());
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: "Welcome back",
      subtitle: "Sign in to pick up where you left off.",
      footer: AuthFooter(
        text: "Don't have an account?",
        action: "Register",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RegisterScreen()),
          );
        },
      ),
      child: Form(
        key: _formKey,
        child: AutofillGroup(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AuthLabel("Email"),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                decoration: fieldDecoration(
                  hint: "you@example.com",
                  icon: Icons.email_outlined,
                  fill: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email required";
                  }
                  if (!value.contains("@")) return "Enter valid email";
                  return null;
                },
              ),
              const SizedBox(height: 14),

              const AuthLabel("Password"),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: fieldDecoration(
                  hint: "Enter your password",
                  fill: Colors.white,
                  icon: Icons.lock_outline,
                  suffix: IconButton(
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: AppColors.muted,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "Password required";
                  if (value.length < 6) return "Minimum 6 characters";
                  return null;
                },
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _showForgotPasswordDialog,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.only(top: 10, bottom: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              AuthButton(
                label: "Login",
                loading: isLoading,
                onPressed: _submit,
              ),
              const SizedBox(height: 18),

              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "or continue with",
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.border)),
                ],
              ),
              const SizedBox(height: 18),

              SizedBox(
                height: 54,
                child: OutlinedButton(
                  onPressed: (isLoading || isGoogleLoading) ? null : _googleSignIn,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: const BorderSide(color: AppColors.border, width: 1.4),
                  ),
                  child: isGoogleLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "G",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4285F4),
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        "Google",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.dark,
                        ),
                      ),
                    ],
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