 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool _obscure = true;

  // 🔔 Elegant error message
  void _showLoginError() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.redAccent.withOpacity(0.95),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Invalid email or password.\nPlease try again.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/connect');
    } catch (_) {
      _showLoginError();
    } finally {
      setState(() => isLoading = false);
    }
  }

  InputDecoration _inputDeco({
    required String label,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: secondaryColor),
      suffixIcon: suffix,
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: secondaryColor, width: 1.6),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              backgroundColor,
              backgroundColor.withOpacity(0.92),
              primaryColor.withOpacity(0.12),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.25),
                        ),
                      ),
                      child: Icon(
                        Icons.directions_car,
                        size: 62,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'SMART LINE FOLLOWER CAR',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Intelligent Navigation System',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.10),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Sign in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDeco(
                              label: 'Email Address',
                              icon: Icons.email,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: passwordController,
                            obscureText: _obscure,
                            decoration: _inputDeco(
                              label: 'Password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 3,
                              ),
                              child: isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style:
                                    TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/create');
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: secondaryColor,
                                ),
                                child: const Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Secure access via Firebase Authentication',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.45),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}