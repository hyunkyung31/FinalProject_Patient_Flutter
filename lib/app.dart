import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/view/dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BOMI',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: const DashboardScreen(),
  );
}
