import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';


void main() {
  runApp(const WasalniApp());
}

class WasalniApp extends StatelessWidget {
  const WasalniApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wasalni',
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1), // Navy Blue
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF0D47A1),
          secondary: const Color(0xFF2ECC71), // Emerald Green
        ),
        scaffoldBackgroundColor: Colors.grey[50], // Soft White
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            elevation: 3,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.grey, width: 0.5)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0D47A1), width: 1.5)),
          contentPadding: const EdgeInsets.all(16),
          labelStyle: const TextStyle(color: Colors.grey),
        ),

      ),
      home: const SplashScreen(),
    );
  }
}
