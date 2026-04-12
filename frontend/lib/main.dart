import 'package:flutter/material.dart';
import 'pages/main.navigations.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Keuangan App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const MainNavigation(),
    );
  }
}
