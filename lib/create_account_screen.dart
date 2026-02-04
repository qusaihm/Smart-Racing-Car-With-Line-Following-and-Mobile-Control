 import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'theme.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  bool isLoading = false;
  bool _obscurePass = true;
  bool _obscureConfirm = true;

  Future<void> createAccount() async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/connect');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Sign Up failed: $e")),
      );
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide:
            const BorderSide(color: secondaryColor, width: 1.6),
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
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                            color: primaryColor.withOpacity(0.25)),
                      ),
                      child: Icon(Icons.person_add,
                          size: 62, color: primaryColor),
                    ),
                    const SizedBox(height: 18),

                    Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Register to control and monitor your smart car',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 14, color: Colors.white70),
                    ),

                    const SizedBox(height: 22),

                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(18),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.10)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: nameController,
                            decoration: _inputDeco(
                              label: 'Full Name',
                              icon: Icons.person,
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
                            obscureText: _obscurePass,
                            decoration: _inputDeco(
                              label: 'Password',
                              icon: Icons.lock,
                              suffix: IconButton(
                                onPressed: () =>
                                    setState(() => _obscurePass = !_obscurePass),
                                icon: Icon(
                                  _obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirm,
                            decoration: _inputDeco(
                              label: 'Confirm Password',
                              icon: Icons.lock_reset,
                              suffix: IconButton(
                                onPressed: () => setState(
                                    () => _obscureConfirm = !_obscureConfirm),
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          SizedBox(
                            height: 54,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : createAccount,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: secondaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
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
                                      'Create Account',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Already have an account? ',
                                style: TextStyle(color: Colors.white70),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                child: const Text(
                                  'Sign In',
                                  style: TextStyle(
                                      color: secondaryColor,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Text(
                      'Powered by Firebase Authentication',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12),
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