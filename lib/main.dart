import 'package:flutter/material.dart';
import 'package:flutter_windows_installer/Pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Windows Installer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(1, 1, 87, 155),
          onSurface: Colors.white,
        ),
        useMaterial3: true,
      ),
      home: MyHomePage(),
    );
  }
}
