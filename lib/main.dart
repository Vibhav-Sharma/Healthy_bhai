import 'package:flutter/material.dart';
<<<<<<< HEAD
import 'screens/splash_screen.dart';
import 'screens/home_selection_screen.dart';
import 'screens/doctor_login_screen.dart';
import 'screens/doctor_dashboard.dart';
import 'screens/patient_login_screen.dart';
import 'screens/patient_dashboard.dart';

=======
import 'page1.dart'; // Importing the page we want to navigate to
>>>>>>> b23c1917981fce9e7260b6a6794d68042693556c
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
    return MaterialApp(
      title: 'Healthy Bhai',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xffDC2626)),
        useMaterial3: true,
      ),
      // Set to the screen you want to test
      home: const MainMenu(),
=======
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(), // The app starts here
>>>>>>> b23c1917981fce9e7260b6a6794d68042693556c
    );
  }
}

<<<<<<< HEAD
class MainMenu extends StatelessWidget {
  const MainMenu({super.key});

  @override
  Widget build(BuildContext context) {
     return Scaffold(
       appBar: AppBar(title: const Text("Stitch To Flutter Menu")),
       body: ListView(
         padding: const EdgeInsets.all(16),
         children: [
           ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SplashScreen())),
              child: const Text("1. Splash Screen"),
           ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HomeSelectionScreen())),
              child: const Text("2. Home Selection Screen"),
           ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorLoginScreen())),
              child: const Text("3. Doctor Login Screen"),
           ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DoctorDashboard())),
              child: const Text("4. Doctor Dashboard"),
           ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientLoginScreen())),
              child: const Text("5. Patient Login Screen"),
           ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PatientDashboard())),
              child: const Text("6. Patient Dashboard"),
           ),
         ]
       )
     );
  }
}
=======
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

>>>>>>> b23c1917981fce9e7260b6a6794d68042693556c
