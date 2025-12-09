import 'package:flutter/material.dart';

class OTPLoginScreen extends StatelessWidget {
  const OTPLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: const Center(
        child: Text(
          "OTP login feature disabled.\nComing soon.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
