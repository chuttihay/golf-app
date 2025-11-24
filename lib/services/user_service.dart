import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final String _baseUrl = 'http://127.0.0.1:5000';

  Future<void> registerUser(User firebaseUser) async {
    final url = Uri.parse('$_baseUrl/users');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'id': firebaseUser.uid,
          'displayName': firebaseUser.displayName ?? 'Anonymous',
          'email': firebaseUser.email ?? 'no-email@example.com',
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        // 201 Created or 200 OK (if user already exists)
        print('User registered/updated with backend: ${firebaseUser.uid}');
      } else {
        throw Exception('Failed to register user with backend: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend for user registration: $e');
    }
  }

  Future<void> submitPicks({
    required String userId,
    required String tournamentId,
    required List<String> golferIds,
  }) async {
    final url = Uri.parse('$_baseUrl/api/picks');
    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'user_id': userId,
          'tournament_id': tournamentId,
          'golfer_ids': golferIds,
        }),
      );

      if (response.statusCode == 201) {
        print('Picks submitted successfully for user $userId and tournament $tournamentId');
      } else {
        throw Exception('Failed to submit picks: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend for pick submission: $e');
    }
  }
}