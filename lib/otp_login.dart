import 'customer_home_screen.dart';
import 'package:flutter/material.dart';
import 'supabase_config.dart';

class OtpLoginScreen extends StatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  State<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends State<OtpLoginScreen> {
  final phoneController = TextEditingController();
  final otpController = TextEditingController();

  bool otpSent = false;
  bool loading = false;

  // Step 1: Send OTP
  Future<void> sendOtp() async {
    final phone = phoneController.text.trim();

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter phone number")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await SupabaseConfig.client.auth.signInWithOtp(phone: phone);

      setState(() => otpSent = true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("OTP sent to $phone")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending OTP: $e")),
      );
    }

    setState(() => loading = false);
  }

  // Step 2: Verify OTP
  Future<void> verifyOtp() async {
    final otp = otpController.text.trim();
    final phone = phoneController.text.trim();

    if (otp.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid OTP")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final result = await SupabaseConfig.client.auth.verifyOtp(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (result.user != null) {
        Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const CustomerHomeScreen()),
);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid OTP")),
      );
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: "Phone Number",
                hintText: "+91XXXXXXXXXX",
              ),
            ),

            if (otpSent)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: "Enter OTP"),
              ),

            const SizedBox(height: 20),

            loading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: otpSent ? verifyOtp : sendOtp,
                    child: Text(otpSent ? "Verify OTP" : "Send OTP"),
                  ),
          ],
        ),
      ),
    );
  }
}

class LoginSuccessScreen extends StatelessWidget {
  const LoginSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          "Login Successful!",
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
