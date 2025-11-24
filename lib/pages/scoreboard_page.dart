import 'package:flutter/material.dart';
import 'package:golf_app/services/scoreboard_service.dart';
import 'package:intl/intl.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  final ScoreboardService _scoreboardService = ScoreboardService();
  
  // State variables to hold data, loading, and error status
  DetailedScoreboard? _scoreboard;
  bool _isLoading = true;
  String? _errorMessage;

  // State to keep track of which tournament panels are expanded
  late List<bool> _isTournamentExpanded;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final data = await _scoreboardService.fetchDetailedScoreboard();
      if (mounted) {
        setState(() {
          _scoreboard = data;
          // Initialize the expansion state list here, once, after data is fetched
          _isTournamentExpanded = List<bool>.filled(data.tournaments.length, false);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  // Helper to format currency
  final currencyFormatter = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo.png', // Path to your logo file
              height: 30, // Adjust height as needed
              width: 30,  // Adjust width as needed
            ),
            const SizedBox(width: 8), // Add some space between logo and title
            const Text('The Breakdown'),
          ],
        ),
        // No need for a custom leading widget; Flutter will handle the BackButton automatically.
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
              _fetchData();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(child: Text('Error: $_errorMessage'));
    }
    if (_scoreboard == null || (_scoreboard!.tournaments.isEmpty && _scoreboard!.overallLeaderboard.isEmpty)) {
      return const Center(child: Text('No scoreboard data available.'));
    }

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: [
        _buildOverallLeaderboard(_scoreboard!.overallLeaderboard),
        const SizedBox(height: 20),
        const Text('Tournament Breakdown', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        _buildTournamentExpansionList(_scoreboard!.tournaments),
      ],
    );
  }

  Widget _buildOverallLeaderboard(List<OverallScore> overallScores) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overall Leaderboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            DataTable(
              columns: const [
                DataColumn(label: Text('Rank')),
                DataColumn(label: Text('Player')),
                DataColumn(label: Text('Total Score'), numeric: true),
              ],
              rows: overallScores.asMap().entries.map((entry) {
                int rank = entry.key + 1;
                OverallScore score = entry.value;
                return DataRow(cells: [
                  DataCell(Text('$rank')),
                  DataCell(Text(score.displayName)),
                  DataCell(Text(currencyFormatter.format(score.totalScore))),
                ]);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentExpansionList(List<TournamentScore> tournaments) {
    if (tournaments.isEmpty) {
      return const Center(child: Text('No tournament results yet.'));
    }

    return ExpansionPanelList(
      expansionCallback: (int index, bool isExpanded) {
        print('Tapped panel at index: $index. It was expanded: $isExpanded.');
        setState(() {
          _isTournamentExpanded[index] = isExpanded;
          print('New expanded state for index $index is now: ${_isTournamentExpanded[index]}');
        });
      },
      children: tournaments.asMap().entries.map<ExpansionPanel>((entry) {
        int index = entry.key;
        TournamentScore t = entry.value;
        return ExpansionPanel(
          headerBuilder: (BuildContext context, bool isExpanded) {
            return ListTile(
              title: Text(t.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            );
          },
          body: _buildTournamentUserScores(t.userScores),
          isExpanded: _isTournamentExpanded[index],
        );
      }).toList(),
    );
  }

  Widget _buildTournamentUserScores(List<UserTournamentScore> userScores) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      child: Column(
        children: userScores.map((userScore) {
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ExpansionTile(
              title: Text(userScore.displayName),
              subtitle: Text('Tournament Earnings: ${currencyFormatter.format(userScore.totalEarnings)}'),
              children: userScore.picks.map((pick) {
                return ListTile(
                  title: Text(pick.golferName),
                  trailing: Text(
                    pick.earnings > 0 
                      ? currencyFormatter.format(pick.earnings) 
                      : 'Pending',
                    style: TextStyle(
                      color: pick.earnings > 0 ? Colors.black87 : Colors.grey,
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}