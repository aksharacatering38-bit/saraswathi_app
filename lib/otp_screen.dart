import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OTPScreen extends StatefulWidget {
  final String phone;

  OTPScreen({required this.phone});

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final TextEditingController otpController = TextEditingController();
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text(
              "OTP sent to ${widget.phone}",
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 20),
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: loading ? null : () async {
                setState(() => loading = true);

                final response = await Supabase.instance.client.auth.verifyOTP(
                  token: otpController.text.trim(),
                  type: OtpType.sms,
                  phone: widget.phone,
                );

                setState(() => loading = false);

                if (response.session != null) {
                  Navigator.pushReplacementNamed(context, "/profile");
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Invalid OTP"))
                  );
                }
              },
              child: loading ? CircularProgressIndicator(color: Colors.white)
                     : Text("Verify OTP"),
            )
          ],
        ),
      ),
    );
  }
}
