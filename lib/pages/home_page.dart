import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'package:golf_app/services/user_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final authService = AuthService();
  final UserService _userService = UserService();
  String? displayName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = authService.currentUser;
    if (user != null) {
      // Register user with backend
      try {
        await _userService.registerUser(user);
      } catch (e) {
        print('Error registering user with backend: $e');
        // Optionally, show a snackbar or alert to the user
      }

      final userData = await authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          displayName = userData?['displayName'];
          isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the row content
          children: [
            Image.asset(
              'lib/assets/images/logo.png', // Path to your logo file
              height: 40, // Adjust height as needed
              width: 40,  // Adjust width as needed
            ),
            const SizedBox(width: 8), // Add some space between logo and title
            const Text('Home Page'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: Color(0xFFBDA55D),
              size: 80,
            ),
            const SizedBox(height: 24),
            Text(
              'Welcome!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const CircularProgressIndicator(),
            if (!isLoading && user != null) ...[
              Text(
                'Email: ${user.email ?? "N/A"}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Display Name: ${displayName ?? "N/A"}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await authService.signOut();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              },
              child: const Text('Sign Out'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/scoreboard');
              },
              child: const Text('View Scoreboard'),
            ),
            const SizedBox(height: 16), // Add some spacing
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/tournaments'); // Navigate to TournamentsPage
              },
              child: const Text('Make Picks'), // Button text
            ),
          ],
        ),
      ),
    );
  }
}

