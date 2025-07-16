import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'package:bcrypt/bcrypt.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  String _error = "";

  void _checkPassword() {
    const hashedPassword = r'$2a$12$v1e6Vq5yAeyESsJGRLJlzeHG8OwxbPSsG/dokdT3.cIEu9oWO9NQ6';

    if (BCrypt.checkpw(_passwordController.text, hashedPassword)) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() {
        _error = "Incorrect password";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Enter Password", style: TextStyle(fontSize: 24)),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Password",
                ),
              ),
              if (_error.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPassword,
                child: const Text("Enter"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
