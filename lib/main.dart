import 'package:flutter/material.dart';
import 'page1.dart'; // Importing the page we want to navigate to
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(), // The app starts here
    );
  }
}

// --- HOME PAGE ---
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          ),
          onPressed: () {
            // This is the logic to move to the next page
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PageOne()),
            );
          },
          child: const Text('Go to Page 1', style: TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

