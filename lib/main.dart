import 'otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://hukprbgcrjfmrwrxlyif.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1a3ByYmdjcmpmbXJ3cnhseWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzE0ODAsImV4cCI6MjA4MDYwNzQ4MH0.XgigJw55p9KUsGYouUzeWtqQNi1RydWdk-SG7v9T5B8',
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(25.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Welcome to Saraswathi Tiffins",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 35),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Enter Mobile Number",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
  final phone = phoneController.text.trim();

  if (phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Enter phone number"))
    );
    return;
  }

  await Supabase.instance.client.auth.signInWithOtp(
    phone: phone,
  );

  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => OTPScreen(phone: phone)),
  );
},
 
                child: Text("Continue"),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
