import 'package:flutter/material.dart';
import 'supabase_config.dart';
import 'otp_login.dart';
import 'screens/customer_home.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseConfig.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Saraswathi Tiffins',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        useMaterial3: true,
      ),
      home: OtpLoginScreen(),
      routes: {
        "/customer_home": (context) => const CustomerHomeScreen(),
      },
    );
  }
}
