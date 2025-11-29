import 'package:flutter/material.dart';
import 'package:mina_app/auth/signin_page.dart';
import 'package:mina_app/auth/signup_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  bool showSignIn = true;

  void togglePages() {
    setState(() {
      showSignIn = !showSignIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    return showSignIn
        ? SignInUI(showSignUpPage: togglePages)
        : SignUpUI(showSignInPage: togglePages);
  }
}
