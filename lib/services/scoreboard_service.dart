import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';


// --- NEW DATA MODELS ---

class DetailedScoreboard {
  final List<TournamentScore> tournaments;
  final List<OverallScore> overallLeaderboard;

  DetailedScoreboard({required this.tournaments, required this.overallLeaderboard});

  factory DetailedScoreboard.fromJson(Map<String, dynamic> json) {
    var tournamentList = json['tournaments'] as List;
    var overallList = json['overall_leaderboard'] as List;

    List<TournamentScore> tournaments = tournamentList.map((i) => TournamentScore.fromJson(i)).toList();
    List<OverallScore> overallLeaderboard = overallList.map((i) => OverallScore.fromJson(i)).toList();

    return DetailedScoreboard(
      tournaments: tournaments,
      overallLeaderboard: overallLeaderboard,
    );
  }
}

class TournamentScore {
  final String id;
  final String name;
  final List<UserTournamentScore> userScores;

  TournamentScore({required this.id, required this.name, required this.userScores});

  factory TournamentScore.fromJson(Map<String, dynamic> json) {
    var userScoresList = json['user_scores'] as List;
    List<UserTournamentScore> userScores = userScoresList.map((i) => UserTournamentScore.fromJson(i)).toList();

    return TournamentScore(
      id: json['id'],
      name: json['name'],
      userScores: userScores,
    );
  }
}

class UserTournamentScore {
  final String userId;
  final String displayName;
  final int totalEarnings;
  final List<PickDetails> picks;

  UserTournamentScore({required this.userId, required this.displayName, required this.totalEarnings, required this.picks});

  factory UserTournamentScore.fromJson(Map<String, dynamic> json) {
    var picksList = json['picks'] as List;
    List<PickDetails> picks = picksList.map((i) => PickDetails.fromJson(i)).toList();

    return UserTournamentScore(
      userId: json['user_id'],
      displayName: json['displayName'],
      totalEarnings: json['total_earnings'],
      picks: picks,
    );
  }
}

class PickDetails {
  final String golferName;
  final int earnings;

  PickDetails({required this.golferName, required this.earnings});

  factory PickDetails.fromJson(Map<String, dynamic> json) {
    return PickDetails(
      golferName: json['golfer_name'],
      earnings: json['earnings'],
    );
  }
}

class OverallScore {
  final String userId;
  final String displayName;
  final int totalScore;

  OverallScore({required this.userId, required this.displayName, required this.totalScore});

  factory OverallScore.fromJson(Map<String, dynamic> json) {
    return OverallScore(
      userId: json['user_id'],
      displayName: json['displayName'],
      totalScore: json['total_score'],
    );
  }
}


// --- SERVICE CLASS ---

class ScoreboardService {
  final String _baseUrl = 'http://127.0.0.1:5000'; // Your Flask backend URL

  // --- NEW METHOD for Detailed Scoreboard ---
  Future<DetailedScoreboard> fetchDetailedScoreboard() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/detailed-scoreboard'));

      if (response.statusCode == 200) {
        return DetailedScoreboard.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load detailed scoreboard: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend for detailed scoreboard: $e');
    }
  }

  // --- OLD METHOD (kept for reference) ---
  Future<List<Map<String, dynamic>>> fetchScoreboard() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/api/scoreboard'));

      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load scoreboard: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to connect to backend: $e');
    }
  }
}
