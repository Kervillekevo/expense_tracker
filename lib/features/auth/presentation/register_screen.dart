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
  final _formkey = GlobalKey<FormState>();
  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> register() async {
    try {
      setState(() => isLoading = true);

      await _authService.register(
        emailController.text.trim(),
        passwordController.text.trim(),
        nameController.text.trim(),
      );

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

    setState(() => isLoading = false);
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
        key: _formkey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AuthLabel("Full name"),
            TextFormField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: fieldDecoration(
                hint: "John Doe",
                icon: Icons.person_outline,
                fill: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Name required";
                return null;
              },
            ),
            const SizedBox(height: 18),
            const AuthLabel("Email"),
            TextFormField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: fieldDecoration(
                hint: "you@example.com",
                icon: Icons.email_outlined,
                fill: Colors.white,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Email required";
                if (!value.contains("@") || !value.contains(".")) {
                  return "Enter a valid email";
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            const AuthLabel("Password"),
            TextFormField(
              controller: passwordController,
              obscureText: obscurePassword,
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
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) return "Password required";
                if (value.length < 6) return "Minimum 6 characters";
                return null;
              },
            ),
            const Padding(
              padding: EdgeInsets.only(top: 8, left: 4),
              child: Text(
                "Use at least 6 characters.",
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 28),
            AuthButton(
              label: "Create account",
              loading: isLoading,
              onPressed: () {
                if (_formkey.currentState!.validate()) register();
              },
            ),
          ],
        ),
      ),
    );
  }
}