import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'page1.dart'; 
import 'screens/doctor_dashboard.dart';
import 'screens/doctor_login_screen.dart';
import 'screens/home_selection_screen.dart';
import 'screens/patient_dashboard.dart';
import 'screens/patient_login_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/ai_assistant_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Button 1
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PageOne()),
                );
              },
              child: const Text('Go to Page 1', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // Button 2
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorDashboard()),
                );
              },
              child: const Text('Go to Doctor Dashboard', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // Button 3
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SplashScreen()),
                );
              },
              child: const Text('Go to Splash Screen', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorLoginScreen()),
                );
              },
              child: const Text('Go to Doctor Login Screen', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeSelectionScreen()),
                );
              },
              child: const Text('Go to Home Selection Screen', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientDashboard()),
                );
              },
              child: const Text('Go to Patient Dashboard', style: TextStyle(fontSize: 18)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PatientLoginScreen()),
                );
              },
              child: const Text('Go to Patient Login Screen', style: TextStyle(fontSize: 18)),
            ),

            const SizedBox(height: 20),

            // AI Emergency Assistant Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AiAssistantScreen()),
                );
              },
              child: const Text('AI Emergency Assistant', style: TextStyle(fontSize: 18)),
            ),

          ],
        ),
      ),
    );
  }
}
