import 'dart:convert';
import 'package:http/http.dart' as http;

class TournamentService {
  final String _baseUrl = ''; // Use a relative path for production

  Future<List<Map<String, dynamic>>> fetchAvailableTournaments() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/available-tournaments'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load available tournaments: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend for tournaments: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchGolfersForTournament(String tournamentId) async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/tournaments/$tournamentId/golfers'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load golfers for tournament: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend for golfers: $e');
    }
  }
}