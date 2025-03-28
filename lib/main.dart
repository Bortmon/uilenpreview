import 'dart:async'; // Voor Timer
import 'dart:convert'; // Voor jsonDecode/Encode (nodig in ApiService)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Nodig in ApiService
import 'package:intl/intl.dart';


import 'models/event.dart';
import 'models/prey.dart';
import 'models/user_rating.dart';
import 'services/MockApiService.dart'; // tijdelijk mock om te testen....
import 'services/ApiService.dart'; // echte API <<<
import 'event_detail_screen.dart';

// --- De main functie die je app start ---
void main() {
  runApp(MyApp()); // Start de app met MyApp als root
}

// --- De root widget van je app (meestal een StatelessWidget) ---
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uilen Prooi App',
      theme: ThemeData(
        primarySwatch: Colors.blue, // Kies een thema kleur
      ),
      // Gebruik EventFeedScreen als de startpagina
      home: EventFeedScreen(),
    );
  }
}


// --- KOPIEER HIER DE VOLLEDIGE EventFeedScreen en _EventFeedScreenState CLASSES ---
// Uit sectie 4 van het vorige antwoord

class EventFeedScreen extends StatefulWidget {
  @override
  _EventFeedScreenState createState() => _EventFeedScreenState();
}

class _EventFeedScreenState extends State<EventFeedScreen> {
  // Maak een instance van ApiService (nu gedefinieerd in dit bestand of geïmporteerd)

  //final ApiService _apiService = ApiService(); // << echte versie tijdelijk uitgezet mock versie
  final MockApiService _apiService = MockApiService();

  List<Event> _events = [];
  bool _isLoading = true;
  String? _error;
  Timer? _pollingTimer;
  Map<int, String> _preyNames = {}; // Om prey ID naar naam te mappen
  final DateFormat _dateFormatter = DateFormat('dd MMM yyyy, HH:mm'); // Voorbeeld: 24 mei 2023, 15:30

  @override
  void initState() {
    super.initState();
    _fetchInitialData(); // Haal events en prey namen op bij start
    _startPolling();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Combineer het ophalen van events en prey namen
  void _fetchInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Haal beide parallel op (iets efficiënter)
      final results = await Future.wait([
        _apiService.fetchEvents(),
        _apiService.fetchPrey(),
      ]);

      final events = results[0] as List<Event>;
      final preyList = results[1] as List<Prey>;

      // Maak de map voor prey namen
      final preyMap = { for (var prey in preyList) prey.preyId : prey.name };

      if (!mounted) return;
      setState(() {
        _events = events;
        _preyNames = preyMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      print("Error fetching initial data: $e");
    }
  }

  // Aangepast om alleen events op te halen (prey namen veranderen wss niet vaak)
  void _startPolling() {
    _pollingTimer = Timer.periodic(Duration(seconds: 15), (timer) async {
      print("Polling for new events...");
      try {
        final newEvents = await _apiService.fetchEvents();
        if (!mounted) return;
        if (_listEquals(_events, newEvents) == false) {
          print("New data found, updating UI.");
          // Sorteer events (nieuwste eerst) voordat je setState doet
          newEvents.sort((a, b) => b.time.compareTo(a.time));
          setState(() {
            _events = newEvents;
            _error = null;
          });
        } else {
          print("No new data.");
        }
      } catch (e) {
        if (!mounted) return;
        print("Error during polling: $e");
        // Overweeg hier een subtiele error indicator te tonen
      }
    });
  }

  bool _listEquals(List<Event> a, List<Event> b) {
    if (a.length != b.length) return false;
    Set<int> aIds = a.map((e) => e.eventId).toSet();
    Set<int> bIds = b.map((e) => e.eventId).toSet();
    return aIds.containsAll(bIds) && bIds.containsAll(aIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Uilen Prooi Events'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            // Roep _fetchInitialData aan voor een volledige refresh (incl. prey names)
            onPressed: _isLoading ? null : _fetchInitialData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // --- Loading State ---
    if (_isLoading && _events.isEmpty) {
      return Center(
        child: Column( // Gebruik Column voor tekst + indicator
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Events laden...'),
          ],
        ),
      );
    }

    // --- Error State (Iets uitgebreider) ---
    if (_error != null && _events.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column( // Gebruik Column voor icoon + tekst
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 48),
              SizedBox(height: 16),
              Text(
                'Fout bij laden van events:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                _error!, // Gebruik ! omdat we op null hebben gecheckt
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon( // Voeg een retry knop toe
                icon: Icon(Icons.refresh),
                label: Text('Opnieuw proberen'),
                onPressed: _fetchInitialData, // Roep de fetch functie opnieuw aan
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white, backgroundColor: Theme.of(context).primaryColor, // Tekstkleur, Achtergrondkleur
                ),
              )
            ],
          ),
        ),
      );
    }

    // --- Empty State (Iets vriendelijker) ---
    if (_events.isEmpty) {
      return Center(
        child: Column( // Gebruik Column voor icoon + tekst
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.visibility_off_outlined, color: Colors.grey[400], size: 60),
            SizedBox(height: 16),
            Text(
              'Geen recente prooi events gevonden.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              'De feed wordt automatisch bijgewerkt.',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextButton.icon( // Hint/knop voor handmatig vernieuwen
              icon: Icon(Icons.refresh, size: 18),
              label: Text('Handmatig vernieuwen'),
              onPressed: _fetchInitialData,
            )
          ],
        ),
      );
    }

    // --- Data Loaded State (ListView met Cards) ---
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      itemCount: _events.length,
      itemBuilder: (context, index) {
        final event = _events[index];
        final preyName = _preyNames[event.preyId] ?? 'Onbekend (ID: ${event.preyId})';

        // --- Wrap Card met InkWell voor klikbaarheid ---
        return InkWell(
          onTap: () {
            print('Tapped on Event ID: ${event.eventId}');
            if (event.videoUrl != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EventDetailScreen(
                    event: event,
                    preyName: preyName,
                    // --- VOEG DEZE TOE ---
                    apiService: _apiService, // Geef de service instance mee
                    preyNames: _preyNames,   // Geef de prey names map mee
                    // --- EINDE TOEVOEGING ---
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Geen video beschikbaar voor dit event.')),
              );
            }
          },
          child: Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
            clipBehavior: Clip.antiAlias, // Belangrijk zodat Image binnen de Card blijft
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- VIDEO THUMBNAIL ---
                if (event.thumbnailUrl != null) // Toon alleen als URL bestaat
                  Stack(
                    alignment: Alignment.center, // Om play icoon te centreren
                    children: [
                      Image.network(
                        event.thumbnailUrl!, // Gebruik ! omdat we op null checken
                        height: 180, // Geef een vaste hoogte
                        width: double.infinity, // Volle breedte van de kaart
                        fit: BoxFit.cover, // Zorg dat afbeelding vult
                        // Placeholder tijdens laden
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child; // Klaar met laden
                          return Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        // Placeholder bij fout
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            color: Colors.grey[300],
                            child: Center(
                              child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
                            ),
                          );
                        },
                      ),
                      // Overlay met Play icoon
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3), // Lichte overlay
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.play_circle_outline, color: Colors.white.withOpacity(0.9), size: 60),
                      ),
                    ],
                  ),
                // --- Padding alleen voor de tekstinhoud ---
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // --- Top Row: Prooi Naam en Event ID ---
                      Row(
                        // ... (zoals voorheen) ...
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              preyName,
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('ID: ${event.eventId}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                      SizedBox(height: 8),

                      // --- Detail Row: Tijd ---
                      Row(
                        // ... (zoals voorheen) ...
                        children: [
                          Icon(Icons.schedule, size: 16, color: Colors.grey[700]),
                          SizedBox(width: 8),
                          Text(_dateFormatter.format(event.time.toLocal()), style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                        ],
                      ),
                      SizedBox(height: 4),

                      // --- Detail Row: Confidence ---
                      Row(
                        // ... (zoals voorheen) ...
                        children: [
                          Icon(Icons.radar, size: 16, color: Colors.blueGrey),
                          SizedBox(width: 8),
                          Text('AI Zekerheid: ${(event.confidence * 100).toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, color: Colors.grey[800])),
                        ],
                      ),
                      SizedBox(height: 10),

                      // --- Bottom Row: Action Buttons ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end, // Lijn knoppen rechts uit
                        children: [
                          // --- GEBRUIK DEZE CORRECTE KNOPPEN ---
                          IconButton(
                            tooltip: 'Correcte detectie', // Handig voor toegankelijkheid
                            icon: Icon(Icons.thumb_up_alt_outlined), // Gebruik outlined iconen
                            iconSize: 22, // Iets groter
                            color: Colors.green.shade700,
                            // Deze onPressed was vergeten!
                            onPressed: () => _submitFeedback(event.eventId, true),
                            splashRadius: 24, // Visuele feedback bij drukken
                            visualDensity: VisualDensity.compact, // Maakt hit area kleiner
                          ),
                          IconButton(
                            tooltip: 'Incorrecte detectie (geef suggestie)',
                            icon: Icon(Icons.thumb_down_alt_outlined), // Gebruik outlined iconen
                            iconSize: 22,
                            color: Colors.red.shade700,
                            // Deze onPressed was vergeten!
                            onPressed: () => _showSuggestionDialog(event.eventId),
                            splashRadius: 24,
                            visualDensity: VisualDensity.compact,
                          ),
                          // --- EINDE CORRECTE KNOPPEN ---
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }






  // Functie om feedback te sturen
  void _submitFeedback(int eventId, bool isCorrect, {int? suggestionId}) async {
    UserRating rating = UserRating(
      eventId: eventId,
      aiPredictionCorrect: isCorrect,
      userSuggestionPreyId: suggestionId,
    );

    try {
      await _apiService.submitUserRating(rating);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Feedback voor event $eventId verzonden!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fout bij verzenden feedback: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Functie om dialoog te tonen voor suggestie bij incorrecte detectie
  void _showSuggestionDialog(int eventId) async {
    // Zorg dat _preyNames geladen is
    if (_preyNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Prooidierlijst nog niet geladen, probeer opnieuw.')),
      );
      return;
    }

    // Sorteer de prooidieren op naam voor de dropdown
    List<Prey> sortedPreyList = _preyNames.entries
        .map((entry) => Prey(preyId: entry.key, name: entry.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    int? selectedPreyId; // Variabele om de keuze van de gebruiker op te slaan

    // Toon een dialoogvenster
    final result = await showDialog<int>(
      context: context,
      builder: (BuildContext context) {
        // Gebruik een StatefulWidget binnen de dialog om de state van de dropdown te beheren
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Incorrecte Detectie'),
              content: SingleChildScrollView( // Voor het geval er veel prooien zijn
                child: ListBody(
                  children: <Widget>[
                    Text('De AI-detectie voor event $eventId was incorrect.'),
                    SizedBox(height: 15),
                    Text('Welk prooidier was het volgens jou? (Optioneel)'),
                    SizedBox(height: 10),
                    // Dropdown menu om een prooi te selecteren
                    DropdownButton<int>(
                      value: selectedPreyId,
                      hint: Text('Selecteer prooidier...'),
                      isExpanded: true, // Zorgt dat de dropdown de breedte vult
                      items: sortedPreyList.map<DropdownMenuItem<int>>((Prey prey) {
                        return DropdownMenuItem<int>(
                          value: prey.preyId,
                          child: Text(prey.name),
                        );
                      }).toList(),
                      onChanged: (int? newValue) {
                        // Update de state binnen de dialog om de selectie te tonen
                        setDialogState(() {
                          selectedPreyId = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Annuleren'),
                  onPressed: () {
                    Navigator.of(context).pop(); // Sluit dialog zonder waarde
                  },
                ),
                TextButton(
                  child: Text('Verzenden'),
                  onPressed: () {
                    Navigator.of(context).pop(selectedPreyId); // Sluit dialog en geef geselecteerde ID terug
                  },
                ),
              ],
            );
          },
        );
      },
    );

    // Nadat de dialog gesloten is, stuur de feedback met de (eventuele) suggestie
    // De 'result' variabele bevat de selectedPreyId of null als er geannuleerd is.
    _submitFeedback(eventId, false, suggestionId: result);
  }
}
