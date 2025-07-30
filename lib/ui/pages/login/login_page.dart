import 'package:flutter/material.dart';
import 'package:your_cooked/ui/pages/login/login_form.dart';
import 'package:your_cooked/ui/pages/login/register_form.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool register = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              // Set a max width
              child: register
                  ? RegisterForm(onSignIn: _switchToSignIn)
                  : LoginForm(onSignUp: _switchToRegister),
            ),
          ),
        ],
      ),
    );
  }

  void _switchToSignIn() {
    setState(() {
      register = false;
    });
  }

  void _switchToRegister() {
    setState(() {
      register = true;
    });
  }
}
