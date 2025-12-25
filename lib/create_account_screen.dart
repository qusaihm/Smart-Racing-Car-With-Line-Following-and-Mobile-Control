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

  Future<void> createAccount() async {
    if (passwordController.text.trim() != confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Passwords do not match")));
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sign Up failed: $e")));
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
              Text('SMART LINE FOLLOWER CAR', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              Text('Create your account to get started with autonomous vehicle control', style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
              SizedBox(height: 30),
              TextField(
                controller: nameController,
                decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person, color: secondaryColor)),
              ),
              SizedBox(height: 15),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email, color: secondaryColor)),
              ),
              SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock, color: secondaryColor)),
              ),
              SizedBox(height: 15),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock_reset, color: secondaryColor)),
              ),
              SizedBox(height: 30),
              ElevatedButton(
                onPressed: isLoading ? null : createAccount,
                child: isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Create Account'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                child: Text('Already have an account? Sign In', style: TextStyle(color: secondaryColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}