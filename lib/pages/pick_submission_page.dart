import 'package:flutter/material.dart';
import 'package:golf_app/services/tournament_service.dart'; // We'll use this service for now
import 'package:firebase_auth/firebase_auth.dart'; // <--- New Import
import 'package:golf_app/services/user_service.dart'; // <--- New Import

class PickSubmissionPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const PickSubmissionPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<PickSubmissionPage> createState() => _PickSubmissionPageState();
}

class _PickSubmissionPageState extends State<PickSubmissionPage> {
  final TournamentService _tournamentService = TournamentService();
  final FirebaseAuth _auth = FirebaseAuth.instance; // <--- New Instance
  final UserService _userService = UserService(); // <--- New Instance
  List<Map<String, dynamic>> _golfers = [];
  bool _isLoading = true;
  String? _errorMessage;
  final Set<String> _selectedGolferIds = {}; // To store the IDs of selected golfers

  @override
  void initState() {
    super.initState();
    _fetchGolfers();
  }

  Future<void> _fetchGolfers() async {
    try {
      // Call the backend endpoint to get golfers for the specific tournament
      // Note: We'll need to add a method to TournamentService for this.
      // For now, we'll simulate it or use the existing dummy endpoint.
      final data = await _tournamentService.fetchGolfersForTournament(widget.tournamentId);
      if (mounted) {
        setState(() {
          _golfers = data;
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
      // Optionally, show a user-friendly error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load golfers: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // Flutter will automatically add the BackButton here if needed
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo.png',
              height: 40,
              width: 40,
            ),
            const SizedBox(width: 8),
            // Use Expanded and FittedBox to prevent title overflow
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Picks for ${widget.tournamentName}'),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : _golfers.isEmpty
                  ? const Center(child: Text('No golfers available for this tournament.'))
                  : Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: _golfers.length,
                            itemBuilder: (context, index) {
                              final golfer = _golfers[index];
                              final isSelected = _selectedGolferIds.contains(golfer['id']);

                              return CheckboxListTile(
                                title: Text(golfer['name']),
                                value: isSelected,
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      if (_selectedGolferIds.length < 3) {
                                        _selectedGolferIds.add(golfer['id']);
                                      } else {
                                        // Optional: Show a message that they can't select more than 3
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('You can only select 3 golfers.')),
                                        );
                                      }
                                    } else {
                                      _selectedGolferIds.remove(golfer['id']);
                                    }
                                  });
                                },
                              );
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: ElevatedButton(
                            // Disable button if not exactly 3 golfers are selected
                            onPressed: _selectedGolferIds.length == 3
                                ? () async {
                                    final user = _auth.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('You must be logged in to submit picks.')),
                                      );
                                      return;
                                    }

                                    try {
                                      await _userService.submitPicks(
                                        userId: user.uid,
                                        tournamentId: widget.tournamentId,
                                        golferIds: _selectedGolferIds.toList(),
                                      );
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Picks submitted successfully!')),
                                        );
                                        // Optionally navigate back or to a confirmation page
                                        Navigator.of(context).pop(); 
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Failed to submit picks: $e')),
                                        );
                                      }
                                    }
                                  }
                                : null, // This disables the button
                            child: const Text('Submit 3 Picks'),
                          ),
                        ),
                      ],
                    ),
    );
  }
}