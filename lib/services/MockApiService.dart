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

  // Voorbeeld Events (gebruik preyId's van hierboven)
  final List<Event> _mockEvents = [
    Event(
      eventId: 101,
      preyId: 1, // Muis
      time: DateTime.now().subtract(Duration(minutes: 5)),
      confidence: 0.92,
    ),
    Event(
      eventId: 102,
      preyId: 3, // Woelmuis
      time: DateTime.now().subtract(Duration(minutes: 25)),
      confidence: 0.75,
    ),
    Event(
      eventId: 103,
      preyId: 2, // Rat
      time: DateTime.now().subtract(Duration(hours: 1, minutes: 15)),
      confidence: 0.88,
    ),
    Event(
      eventId: 104,
      preyId: 1, // Muis
      time: DateTime.now().subtract(Duration(hours: 2, minutes: 55)),
      confidence: 0.61,
    ),
    Event(
      eventId: 105,
      preyId: 5, // Vogel (klein)
      time: DateTime.now().subtract(Duration(hours: 4)),
      confidence: 0.95,
    ),
  ];

  // Houd bij welke de laatste eventId was om "nieuwe" te simuleren
  int _lastEventId = 105;

  @override
  Future<List<Event>> fetchEvents() async {
    print("MockApiService: Fetching mock events...");
    // Simuleer netwerkvertraging
    await Future.delayed(Duration(milliseconds: 500));

    // Optioneel: Simuleer af en toe een nieuw event voor de polling test
    // if (Random().nextInt(4) == 0 && _mockEvents.length < 10) { // 1 op 4 kans
    //   _lastEventId++;
    //   _mockEvents.insert(0, Event(
    //       eventId: _lastEventId,
    //       preyId: _mockPrey[Random().nextInt(_mockPrey.length)].preyId,
    //       time: DateTime.now(),
    //       confidence: Random().nextDouble() * (0.98 - 0.5) + 0.5 // Tussen 0.5 en 0.98
    //     )
    //   );
    //   print("MockApiService: Added a new mock event!");
    // }

    // Sorteer altijd op tijd (nieuwste eerst) zoals de UI verwacht
    _mockEvents.sort((a, b) => b.time.compareTo(a.time));

    // Geef een kopie terug om onbedoelde aanpassingen te voorkomen
    return List<Event>.from(_mockEvents);
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