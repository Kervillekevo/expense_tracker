import 'package:expense_tracker/features/auth/presentation/register_screen.dart';
import 'package:flutter/material.dart';
import '../data/auth_service.dart';
import '../../home/presentation/home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => LoginScreenState();
}

class LoginScreenState extends State<LoginScreen> {
  static const _primary = Color(0xFF2E7D5B);
  static const _primaryDark = Color(0xFF0D3B2E);
  static const _fill = Color(0xFFF0F7F4);
  static const _border = Color(0xFFCDE7DB);

  final AuthService _authService = AuthService();
  final _formkey = GlobalKey<FormState>();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    try {
      setState(() => isLoading = true);
      await _authService.login(
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
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

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Reset Password"),
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
              decoration: InputDecoration(
                hintText: "Email address",
                filled: true,
                fillColor: _fill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _border),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty) return;

              Navigator.pop(dialogContext);

              try {
                await _authService.resetPassword(email);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Password reset email sent! Check your inbox."),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                  );
                }
              }
            },
            child: const Text(
              "Send Reset Link",
              style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  InputDecoration _decoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      suffixIcon: suffix,
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
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [


              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 56),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_primary, _primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.06),
                          ),
                        ),
                      ),
                      Positioned(
                        left: -20,
                        bottom: -40,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            width: 78,
                            height: 78,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                            child: const Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 34,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Expense Tracker",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Track every shilling, spend smarter",
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),


              Transform.translate(
                offset: const Offset(0, -28),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Welcome back",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          "Sign in to continue",
                          style: TextStyle(fontSize: 13, color: Colors.grey),
                        ),
                        const SizedBox(height: 22),

                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _decoration(
                            hint: "Email address",
                            icon: Icons.email_outlined,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Email required";
                            if (!value.contains("@")) return "Enter valid email";
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: passwordController,
                          obscureText: obscurePassword,
                          decoration: _decoration(
                            hint: "Password",
                            icon: Icons.lock_outlined,
                            suffix: IconButton(
                              icon: Icon(
                                obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey,
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

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _showForgotPasswordDialog,
                            child: const Text(
                              "Forgot password?",
                              style: TextStyle(color: _primary, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                              if (_formkey.currentState!.validate()) login();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "Login",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text("OR", style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 16),

                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () async {
                              try {
                                final result = await _authService.signInWithGoogle();
                                if (result != null && context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                                  );
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: BorderSide(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 20,
                                  height: 20,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    border: Border.all(color: Colors.grey.shade300),
                                  ),
                                  child: const Text(
                                    "G",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF4285F4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  "Continue with Google",
                                  style: TextStyle(fontSize: 14, color: Colors.black87),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: Colors.grey)),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                                );
                              },
                              child: const Text(
                                "Register",
                                style: TextStyle(color: _primary, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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