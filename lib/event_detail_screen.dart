import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart'; // Voor datum format

import 'models/event.dart'; // Importeer je Event model

class EventDetailScreen extends StatefulWidget {
  final Event event;
  final String preyName; // Geef ook de naam mee

  const EventDetailScreen({
    Key? key,
    required this.event,
    required this.preyName,
  }) : super(key: key);

  @override
  _EventDetailScreenState createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;
  bool _showControls = true; // State om controls te tonen/verbergen
  Timer? _controlsTimer;
  final DateFormat _dateFormatter = DateFormat('dd MMMM yyyy \'om\' HH:mm:ss');

  @override
  void initState() {
    super.initState();
    // Maak en initialiseer de controller.
    if (widget.event.videoUrl != null) {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.event.videoUrl!),
      );

      // Initialiseer de controller en sla de future op voor de builder
      _initializeVideoPlayerFuture = _controller!.initialize().then((_) {
        // Zorg dat de eerste frame getoond wordt na initialisatie, zelfs als play nog niet is gedrukt.
        setState(() {});
      }).catchError((error) {
        // Handel initialisatie errors af
        print("Error initializing video player: $error");
        // Optioneel: toon een error message in de UI
      });

      // Voeg een listener toe om de play/pause knop state te updaten
      _controller!.addListener(() {
        if(mounted) { // Voorkom setState na dispose
          setState(() {}); // Update UI bij elke verandering (play/pause/progress)
        }
      });

      // Optioneel: begin direct met afspelen
      // _controller!.play();
      // Optioneel: video loopen
      // _controller!.setLooping(true);

      // Start timer om controls te verbergen na paar seconden
      _startControlsTimer();

    } else {
      // Geen video URL, doe niets met de controller
      print("EventDetailScreen: No video URL provided.");
    }
  }

  @override
  void dispose() {
    // Zorg dat de controller wordt vrijgegeven om resources te besparen.
    _controlsTimer?.cancel(); // Stop de timer
    _controller?.dispose();
    super.dispose();
  }

  // Timer om controls te verbergen
  void _startControlsTimer() {
    _controlsTimer?.cancel(); // Reset bestaande timer
    _controlsTimer = Timer(Duration(seconds: 4), () {
      if (mounted && _controller != null && _controller!.value.isPlaying) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  // Schakel controls aan/uit en reset timer
  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startControlsTimer(); // Start timer opnieuw als controls getoond worden
    } else {
      _controlsTimer?.cancel(); // Stop timer als controls verborgen worden
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Event ${widget.event.eventId} - ${widget.preyName}'),
      ),
      // Gebruik een FutureBuilder om een loading spinner te tonen
      // terwijl de video laadt.
      body: SingleChildScrollView( // Maakt scrollen mogelijk als inhoud te lang is
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Video Player Sectie ---
              if (_controller != null && _initializeVideoPlayerFuture != null)
                FutureBuilder(
                  future: _initializeVideoPlayerFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done && !_controller!.value.hasError) {
                      // Als de VideoPlayer klaar is met initialiseren, gebruik dan de data
                      // van de controller om de aspect ratio te limiteren en toon de video.
                      return GestureDetector( // Detecteer taps op de video area
                        onTap: _toggleControls,
                        child: AspectRatio(
                          aspectRatio: _controller!.value.aspectRatio,
                          // Gebruik Stack om controls over de video te leggen
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: <Widget>[
                              VideoPlayer(_controller!),
                              // Overlay met controls (alleen als _showControls true is)
                              AnimatedOpacity(
                                opacity: _showControls ? 1.0 : 0.0,
                                duration: Duration(milliseconds: 300),
                                child: Container(
                                  // Semi-transparante achtergrond voor controls
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.6),
                                      ],
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // Neem minimale hoogte
                                    children: [
                                      // --- Play/Pause Button ---
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
                                              _controlsTimer?.cancel(); // Stop timer bij pauze
                                            } else {
                                              _controller!.play();
                                              _startControlsTimer(); // Start timer bij spelen
                                            }
                                          });
                                        },
                                      ),
                                      SizedBox(height: 8), // Ruimte boven progress bar
                                      // --- Progress Indicator ---
                                      VideoProgressIndicator(
                                        _controller!,
                                        allowScrubbing: true, // Maakt zoeken mogelijk
                                        padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                        colors: VideoProgressColors(
                                          playedColor: Theme.of(context).colorScheme.primary,
                                          bufferedColor: Colors.grey.shade400,
                                          backgroundColor: Colors.black.withOpacity(0.4),
                                        ),
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
                      // Toon een error bericht als initialisatie faalt
                      return Container(
                        height: 200,
                        color: Colors.grey[300],
                        child: Center(child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, color: Colors.red, size: 40),
                            SizedBox(height: 8),
                            Text('Fout bij laden video', style: TextStyle(color: Colors.red)),
                            // Text('${snapshot.error ?? _controller?.value.errorDescription}', style: TextStyle(fontSize: 12)),
                          ],
                        )),
                      );
                    } else {
                      // Toon een loading indicator terwijl de video laadt.
                      return Container(
                        height: 200, // Geef een vaste hoogte tijdens laden
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                  },
                )
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
              _buildDetailRow(Icons.pest_control, 'Gedetecteerd', widget.preyName), // pest_control is een placeholder icon ;)
              _buildDetailRow(Icons.radar, 'AI Zekerheid', '${(widget.event.confidence * 100).toStringAsFixed(1)}%'),
              _buildDetailRow(Icons.tag, 'Event ID', '${widget.event.eventId}'),
              // Voeg hier eventueel meer details toe
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