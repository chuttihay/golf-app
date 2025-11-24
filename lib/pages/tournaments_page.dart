import 'package:flutter/material.dart';
import 'package:golf_app/services/tournament_service.dart'; // <--- New Import
import 'package:golf_app/pages/pick_submission_page.dart';

class TournamentsPage extends StatefulWidget {
  const TournamentsPage({super.key});

  @override
  State<TournamentsPage> createState() => _TournamentsPageState();
}

class _TournamentsPageState extends State<TournamentsPage> {
  final TournamentService _tournamentService = TournamentService(); // <--- New Service Instance
  List<Map<String, dynamic>> _tournamentsData = []; // <--- Data holder
  bool _isLoading = true; // <--- Loading indicator
  String? _errorMessage; // <--- Error message holder

  @override
  void initState() {
    super.initState();
    _fetchTournaments(); // <--- Fetch data when the page initializes
  }

  Future<void> _fetchTournaments() async {
    try {
      final data = await _tournamentService.fetchAvailableTournaments();
      if (mounted) { // Check if the widget is still in the tree
        setState(() {
          _tournamentsData = data;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Flutter will automatically add the BackButton here if needed
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center, // Center the row content
          children: [
            Image.asset(
              'lib/assets/images/logo.png', // Path to your logo file
              height: 30, // Adjust height as needed
              width: 30,  // Adjust width as needed
            ),
            const SizedBox(width: 8), // Add some space between logo and title
            const Text('Available Tournaments'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // <--- Show loading indicator
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage')) // <--- Show error message
              : _tournamentsData.isEmpty
                  ? const Center(child: Text('No available tournaments for picks.')) // <--- Handle empty data
                  : ListView.builder(
                      itemCount: _tournamentsData.length,
                      itemBuilder: (context, index) {
                        final tournament = _tournamentsData[index];
                        return Card(
                          margin: const EdgeInsets.all(8.0),
                          child: ListTile(
                            title: Text('${tournament['name']} (${tournament['year']})'),
                            subtitle: Text(
                              'Submission Window: ${tournament['submission_start'].substring(0, 10)} to ${tournament['submission_end'].substring(0, 10)}'
                            ),
                            trailing: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PickSubmissionPage(
                                      tournamentId: tournament['id'],
                                      tournamentName: '${tournament['name']} (${tournament['year']})',
                                    ),
                                  ),
                                );
                              },
                              child: const Text('Make Picks'),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}