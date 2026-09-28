import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_provider.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const BankExamApp());
}

class BankExamApp extends StatelessWidget {
  const BankExamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppProvider(),
      child: MaterialApp(
        title: '银行备考知识库',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF4A9B8E),
            primary: const Color(0xFF4A9B8E),
            secondary: const Color(0xFFE08A5B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF5F0E8),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF4A9B8E),
            foregroundColor: Colors.white,
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFFE08A5B),
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
