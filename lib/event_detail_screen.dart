import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'dart:async'; // Nodig voor Timer en voor async in dialog

import 'models/event.dart';
import 'models/prey.dart'; // Nodig voor dialog
// Importeer de service (pas pad aan indien nodig)
// Kies of je de echte of de mock service importeert/gebruikt
import 'models/user_rating.dart';
import 'services/MockApiService.dart'; // Of 'mock_api_service.dart'

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final String preyName;
  // --- VOEG TOE ---
  final MockApiService apiService; // Gebruik MockApiService of ApiService type
  final Map<int, String> preyNames;
  // --- EINDE TOEVOEGING ---

  const EventDetailScreen({
    Key? key,
    required this.event,
    required this.preyName,
    // --- VOEG TOE ---
    required this.apiService,
    required this.preyNames,
    // --- EINDE TOEVOEGING ---
  }) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

// _EventDetailScreenState blijft grotendeels hetzelfde, maar we voegen de feedback methodes toe
class _EventDetailScreenState extends State<EventDetailScreen> {
  // ... (Video controller, initstate, dispose, etc. zoals voorheen) ...
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _showControls = true;
  Timer? _controlsTimer;
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy \'om\' HH:mm:ss');

  @override
  void initState() {
    // ... (zoals voorheen) ...
    super.initState();
    if (widget.event.videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.event.videoUrl!));
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        setState(() {});
      }).catchError((error) {
        print("Error initializing video player: $error");
      });
      _controller!.addListener(() {
        if(mounted) { setState(() {}); }
      });
      _startControlsTimer();
    } else {
      print("EventDetailScreen: No video URL provided.");
    }
  }

  @override
  void dispose() {
    _controlsTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  void _startControlsTimer() {
    // ... (zoals voorheen) ...
    _controlsTimer?.cancel();
    _controlsTimer = Timer(Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() { _showControls = false; });
      }
    });
  }

  void _toggleControls() {
    // ... (zoals voorheen) ...
    setState(() { _showControls = !_showControls; });
    if (_showControls) { _startControlsTimer(); }
    else { _controlsTimer?.cancel(); }
  }


  // --- KOPIEER DE FEEDBACK METHODES HIER ---

  // Functie om feedback te sturen (gebruikt widget.apiService)
  void _submitFeedback(int eventId, bool isCorrect, {int? suggestionId}) async {
    // Maak UserRating object (importeer UserRating model)
    // import 'models/user_rating.dart'; bovenaan toevoegen
    UserRating rating = UserRating(
      eventId: eventId,
      aiPredictionCorrect: isCorrect,
      userSuggestionPreyId: suggestionId,
    );

    // Gebruik try-catch voor error handling
    try {
      // Gebruik de meegegeven apiService instance
      await widget.apiService.submitUserRating(rating);
      // Toon bevestiging (check of context nog valid is)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback voor event $eventId verzonden!')),
      );
    } catch (e) {
      // Toon foutmelding
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij verzenden feedback: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Functie om dialoog te tonen (gebruikt widget.preyNames)
  void _showSuggestionDialog(int eventId) async {
    // Gebruik de meegegeven preyNames map
    final Map<int, String> currentPreyNames = widget.preyNames;

    if (currentPreyNames.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prooidierlijst niet beschikbaar.')),
      );
      return;
    }

    // Sorteer prooidieren (importeer Prey model)
    List<Prey> sortedPreyList = currentPreyNames.entries
        .map((entry) => Prey(preyId: entry.key, name: entry.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    int? selectedPreyId;

    if (!mounted) return; // Check voordat je de dialog toont
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) { // Gebruik andere context naam
        return StatefulBuilder(
          builder: (context, setDialogState) { // Deze context is voor de dialog
            return AlertDialog(
              title: Text('Incorrecte Detectie'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('De AI-detectie voor event $eventId was incorrect.'),
                    SizedBox(height: 15),
                    Text('Welk prooidier was het volgens jou? (Optioneel)'),
                    SizedBox(height: 10),
                    DropdownButton<int>(
                      value: selectedPreyId,
                      hint: Text('Selecteer prooidier...'),
                      isExpanded: true,
                      items: sortedPreyList.map<DropdownMenuItem<int>>((Prey prey) {
                        return DropdownMenuItem<int>(
                          value: prey.preyId,
                          child: Text(prey.name),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        setDialogState(() { selectedPreyId = newValue; });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuleren'),
                  // Gebruik dialogContext om de dialog te sluiten
                  onPressed: () => Navigator.of(dialogContext).pop(),
                ),
                TextButton(
                  child: Text('Verzenden'),
                  // Geef selectedPreyId terug bij sluiten
                  onPressed: () => Navigator.of(dialogContext).pop(selectedPreyId),
                ),
              ],
            );
          },
        );
      },
    );

    // Stuur feedback na sluiten dialog (gebruik de lokale _submitFeedback)
    // 'result' bevat de ID of null
    _submitFeedback(eventId, false, suggestionId: result);
  }

  // --- EINDE GEKOPIEERDE METHODES ---


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( /* ... zoals voorheen ... */ ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Video Player Sectie ---
              // ... (zoals voorheen, met FutureBuilder etc.) ...
              if (_controller != null && _initializeVideoPlayerFuture != null)
              // --- GEBRUIK DEZE CORRECTE FutureBuilder ---
                FutureBuilder(
                  // Gebruik de Future die we in initState hebben opgeslagen
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    // Check de connectie state en of er geen errors zijn
                    if (snapshot.connectionState == ConnectionState.done && !_controller!.value.hasError) {
                      // Video is klaar: toon de speler
                      return GestureDetector(
                        onTap: _toggleControls,
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: <Widget>[
                              VideoPlayer(_controller!),
                              // Overlay met controls
                              AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  decoration: BoxDecoration( /* ... gradient ... */ ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Play/Pause Button
                                      IconButton(
                                        iconSize: 48,
                                        color: Colors.white,
                                        icon: Icon(
                                          _controller!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            if (_controller!.value.isPlaying) {
                                              _controller!.pause();
                                              _controlsTimer?.cancel();
                                            } else {
                                              _controller!.play();
                                              _startControlsTimer();
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(height: 8),
                                      // Progress Indicator
                                      VideoProgressIndicator(
                                        _controller!,
                                        allowScrubbing: true,
                                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        colors: VideoProgressColors( /* ... colors ... */ ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    } else if (snapshot.hasError || (_controller != null && _controller!.value.hasError)) {
                      // Toon error bij initialisatie
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text('Fout bij laden video', style: TextStyle(color: Colors.red)),
                          ],
                        )),
                      );
                    } else {
                      // Toon loading indicator tijdens laden.
                      return Container(
                        height: 200,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                )
              // --- EINDE CORRECTE FutureBuilder ---
              else
              // Fallback als er geen video URL is
                Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Center(child: Text('Geen video beschikbaar.')),
                ),

              SizedBox(height: 20), // Ruimte onder de video

              // --- Event Details Sectie ---
              Text('Details', style: Theme.of(context).textTheme.headlineSmall),
              Divider(),
              SizedBox(height: 8),
              _buildDetailRow(Icons.calendar_today, 'Tijdstip', _dateFormatter.format(widget.event.time.toLocal())),
              _buildDetailRow(Icons.pest_control, 'Gedetecteerd', widget.preyName),
              _buildDetailRow(Icons.radar, 'AI Zekerheid', '${(widget.event.confidence * 100).toStringAsFixed(1)}%'),
              _buildDetailRow(Icons.tag, 'Event ID', '${widget.event.eventId}'),

              // --- VOEG FEEDBACK SECTIE TOE ---
              SizedBox(height: 24),
              Text('Feedback geven', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly, // Verdeel knoppen
                children: [
                  Column( // Combineer icoon en tekst
                    children: [
                      IconButton(
                        iconSize: 36,
                        tooltip: 'Correcte detectie',
                        icon: Icon(Icons.thumb_up_alt_outlined),
                        color: Colors.green.shade700,
                        // Roep de lokale _submitFeedback aan
                        onPressed: () => _submitFeedback(widget.event.eventId, true),
                      ),
                      Text('Correct', style: TextStyle(color: Colors.green.shade700)),
                    ],
                  ),
                  Column( // Combineer icoon en tekst
                    children: [
                      IconButton(
                        iconSize: 36,
                        tooltip: 'Incorrecte detectie (geef suggestie)',
                        icon: Icon(Icons.thumb_down_alt_outlined),
                        color: Colors.red.shade700,
                        // Roep de lokale _showSuggestionDialog aan
                        onPressed: () => _showSuggestionDialog(widget.event.eventId),
                      ),
                      Text('Incorrect', style: TextStyle(color: Colors.red.shade700)),
                    ],
                  ),
                ],
              ),
              // --- EINDE FEEDBACK SECTIE ---

            ],
          ),
        ),
      ),
    );
  }

  // Helper widget voor detail rijen
  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          SizedBox(width: 12),
          Text('$label:', style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}