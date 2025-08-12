import 'package:anoter/pages/free_page.dart';
import 'package:anoter/sl.dart';
import 'package:flutter/material.dart';

void main() async {
  await initializeServices();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.from(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
      ),
      home: FreePage([], 'home'),
    );
  }
}
