import 'package:flutter/material.dart';
import 'package:state_saver_package/state_saver_package.dart';
import 'package:state_saver/demo_screen.dart';

void main() {
  stateSaverListener();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'State Saver Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DemoScreen(),
    );
  }
}
