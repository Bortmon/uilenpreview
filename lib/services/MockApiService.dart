import 'dart:async';
import 'dart:math'; // Voor willekeurige data
import '../models/event.dart'; // Pas pad aan indien nodig
import '../models/prey.dart';   // Pas pad aan indien nodig
import '../models/user_rating.dart'; // Pas pad aan indien nodig

// Interface (optioneel maar goede gewoonte voor mock/real swapping)
// abstract class IApiService {
//   Future<List<Event>> fetchEvents();
//   Future<List<Prey>> fetchPrey();
//   Future<void> submitUserRating(UserRating rating);
// }

// De ECHTE ApiService (zorg dat deze ook blijft bestaan)
class ApiService /* implements IApiService */ {
  final String _baseUrl = "JOUW_API_BASIS_URL"; // Blijft nodig voor de echte versie

  Uri _buildUri(String endpoint) { /* ... implementatie ... */ return Uri(); } // Body niet nodig voor mock
  Future<List<Event>> fetchEvents() async { /* ... echte implementatie ... */ throw UnimplementedError(); }
  Future<List<Prey>> fetchPrey() async { /* ... echte implementatie ... */ throw UnimplementedError(); }
  Future<void> submitUserRating(UserRating rating) async { /* ... echte implementatie ... */ throw UnimplementedError(); }
}


// --- DE MOCK VERSIE ---
class MockApiService /* implements IApiService */ {

  // Voorbeeld Prooidieren
  final List<Prey> _mockPrey = [
    Prey(preyId: 1, name: "Muis"),
    Prey(preyId: 2, name: "Rat"),
    Prey(preyId: 3, name: "Woelmuis"),
    Prey(preyId: 5, name: "Vogel (klein)"),
  ];

  // Houd bij welke de laatste eventId was
  int _lastEventId = 105;

  // Genereer mock events MET video/thumbnail URLs
  List<Event> _generateMockEvents() {
    _lastEventId = 105; // Reset voor consistentie bij elke call in dit voorbeeld
    List<Event> events = [
      Event(
          eventId: 101, preyId: 1, time: DateTime.now().subtract(Duration(minutes: 5)), confidence: 0.92,
          // VOEG TOE: URLs
          thumbnailUrl: 'https://picsum.photos/seed/101/300/200', // Gebruik eventId als 'seed'
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4' // Standaard test video
      ),
      Event(
          eventId: 102, preyId: 3, time: DateTime.now().subtract(Duration(minutes: 25)), confidence: 0.75,
          thumbnailUrl: 'https://picsum.photos/seed/102/300/200',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4' // Andere test video
      ),
      Event(
          eventId: 103, preyId: 2, time: DateTime.now().subtract(Duration(hours: 1, minutes: 15)), confidence: 0.88,
          thumbnailUrl: 'https://picsum.photos/seed/103/300/200',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4'
      ),
      Event(
          eventId: 104, preyId: 1, time: DateTime.now().subtract(Duration(hours: 2, minutes: 55)), confidence: 0.61,
          thumbnailUrl: 'https://picsum.photos/seed/104/300/200',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4'
      ),
      Event(
          eventId: 105, preyId: 5, time: DateTime.now().subtract(Duration(hours: 4)), confidence: 0.95,
          thumbnailUrl: 'https://picsum.photos/seed/105/300/200',
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4'
      ),
    ];
    events.sort((a, b) => b.time.compareTo(a.time)); // Sorteer
    return events;
  }

  @override
  Future<List<Event>> fetchEvents() async {
    print("MockApiService: Fetching mock events...");
    await Future.delayed(Duration(milliseconds: 500));

    // Simuleer af en toe nieuw event
    List<Event> currentEvents = _generateMockEvents(); // Genereer verse lijst
    if (Random().nextInt(5) == 0 && currentEvents.length < 10) {
      _lastEventId++;
      currentEvents.insert(0, Event(
          eventId: _lastEventId,
          preyId: _mockPrey[Random().nextInt(_mockPrey.length)].preyId,
          time: DateTime.now(),
          confidence: Random().nextDouble() * (0.98 - 0.5) + 0.5,
          thumbnailUrl: 'https://picsum.photos/seed/$_lastEventId/300/200', // Nieuwe seed
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/SubaruOutbackNavigatingAmbition.mp4' // Nog een andere video
      )
      );
      print("MockApiService: Added a new mock event!");
      currentEvents.sort((a, b) => b.time.compareTo(a.time)); // Hersorteer
    }

    return List<Event>.from(currentEvents); // Geef kopie terug
  }

  @override
  Future<List<Prey>> fetchPrey() async {
    print("MockApiService: Fetching mock prey...");
    // Simuleer netwerkvertraging
    await Future.delayed(Duration(milliseconds: 300));
    return List<Prey>.from(_mockPrey);
  }

  @override
  Future<void> submitUserRating(UserRating rating) async {
    print("MockApiService: Received user rating:");
    print("  Event ID: ${rating.eventId}");
    print("  Correct: ${rating.aiPredictionCorrect}");
    print("  Suggestion ID: ${rating.userSuggestionPreyId}");
    // Simuleer netwerkvertraging
    await Future.delayed(Duration(milliseconds: 400));
    print("MockApiService: Mock rating 'submitted'.");
    // Gooi geen error om succes te simuleren
    // Om error te testen: throw Exception("Mock API error submitting rating!");
  }
}