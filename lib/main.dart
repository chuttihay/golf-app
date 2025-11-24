import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'pages/signup_page.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'pages/scoreboard_page.dart';
import 'pages/tournaments_page.dart';
import 'pages/pick_submission_page.dart'; // <--- New Import

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
    return MaterialApp(
      title: 'Home Page',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        
        // Define the color scheme
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF0A2342),    // Deep Navy
          onPrimary: Colors.white,
          secondary: Color(0xFFBDA55D),  // Flat Gold
          onSecondary: Colors.black,
          surface: Color(0xFFF8F8F8),   // Off-white surface
          onSurface: Color(0xFF0A2342),   // Navy text on surfaces
          background: Color(0xFFF0F0F0), // Light grey background
          onBackground: Color(0xFF0A2342),
        ),

        // Apply the color scheme to specific components
        scaffoldBackgroundColor: const Color(0xFFF0F0F0), // Light grey background

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0A2342), // Navy AppBar
          foregroundColor: Colors.white,      // White title
          elevation: 2,
          centerTitle: true, // Center the title globally
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFBDA55D), // Gold buttons
            foregroundColor: Colors.black,          // Black text on buttons
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),

        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF0A2342), // Navy text buttons
          ),
        ),

        cardTheme: const CardThemeData( // Corrected from CardTheme to CardThemeData
          elevation: 1,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0A2342), width: 2),
          ),
        ),

        expansionTileTheme: const ExpansionTileThemeData(
          iconColor: Color(0xFFBDA55D),
          textColor: Color(0xFF0A2342),
        ),
      ),
      routes: {
        '/signup': (context) => const SignupPage(),
        '/login': (context) => const LoginPage(),
        '/home': (context) => const HomePage(),
        "/scoreboard": (context) => const ScoreboardPage(),
        "/tournaments": (context) => const TournamentsPage(),
        "/pick-submission": (context) => const PickSubmissionPage(tournamentId: '', tournamentName: ''), // <--- New Route
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If user is logged in, show home page
        if (snapshot.hasData && snapshot.data != null) {
          return const HomePage();
        }

        // If no user, show signup page (first-time users)
        return const SignupPage();
      },
    );
  }
}
