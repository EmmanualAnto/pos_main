import 'package:asset_management/homepage.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POS Manager',
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: const AssetHome(),
    );
  }
}

class AppColors {
  static const background = Color(0xFFF5F5F5);
  static const card = Color(0xFFFFFFFF);
  static const icon = Color(0xFF616161);
  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const textHint = Color(0xFF9E9E9E);
  static const inputFill = Color(0xFFF0F0F0);
  static const button = Color(0xFF455A64);
  static const buttonText = Colors.white;
}
