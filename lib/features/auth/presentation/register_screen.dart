import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/auth_shell.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => RegisterScreenState();
}

class RegisterScreenState extends State<RegisterScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  void _showError(Object e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
    );
  }

  Future<void> register() async {
    setState(() => isLoading = true);
    try {
      await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created! Please log in."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    } catch (e) {
      _showError(e);
    }
    if (mounted) setState(() => isLoading = false);
  }

  void _submit() {
    if (isLoading) return;
    if (_formKey.currentState!.validate()) register();
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      title: "Create your account",
      subtitle: "Start tracking every shilling in under a minute.",
      footer: AuthFooter(
        text: "Already have an account?",
        action: "Login",
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
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
              const AuthLabel("Full name"),
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.name],
                decoration: fieldDecoration(
                  hint: "John Doe",
                  icon: Icons.person_outline,
                  fill: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Name required";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

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
                  if (!value.contains("@") || !value.contains(".")) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              const AuthLabel("Password"),
              TextFormField(
                controller: passwordController,
                obscureText: obscurePassword,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onFieldSubmitted: (_) => _submit(),
                decoration: fieldDecoration(
                  hint: "Create a password",
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
              const Padding(
                padding: EdgeInsets.only(top: 6, left: 4),
                child: Text(
                  "Use at least 6 characters.",
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 20),

              AuthButton(
                label: "Create account",
                loading: isLoading,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}