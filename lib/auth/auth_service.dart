import 'package:flutter/material.dart';
import 'signin_page.dart';
import 'signup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showSignIn = true;

  void togglePages() {
    setState(() => showSignIn = !showSignIn);
  }

  @override
  Widget build(BuildContext context) {
    return showSignIn
        ? SignInUI(showSignUpPage: togglePages)
        : SignUpUI(showSignInPage: togglePages);
  }
}