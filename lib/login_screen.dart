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

  Future<void> login() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/connect');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Login failed: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.directions_car, size: 100, color: primaryColor),
              SizedBox(height: 20),
              Text('SMART LINE FOLLOWER CAR',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              Text('Intelligent Navigation System', style: TextStyle(fontSize: 16, color: Colors.white70)),
              SizedBox(height: 40),
              TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email, color: secondaryColor),
                    filled: true,
                  )
              ),
              SizedBox(height: 20),
              TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: secondaryColor),
                    suffixIcon: Icon(Icons.visibility_off, color: Colors.white70),
                    filled: true,
                  )
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : login,
                child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Sign In'),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/create');
                },
                child: Text('Create Account', style: TextStyle(color: secondaryColor, fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}