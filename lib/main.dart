import 'package:flutter/material.dart';
import 'package:jadal_app/features/auth/presentation/screens/login_screen.dart';

void main() {
  runApp(const JadalApp());
}

class JadalApp extends StatelessWidget {
  const JadalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Jadal',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        // add other routes if needed
      },
    );
  }
}
