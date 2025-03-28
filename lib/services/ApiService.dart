import 'dart:convert'; // Voor jsonDecode en jsonEncode
import 'package:http/http.dart' as http;
import '../models/event.dart'; // Importeer je models
import '../models/prey.dart';
import '../models/user_rating.dart';

class ApiService {

  final String _baseUrl = "JOUW_API_BASIS_URL";

  // Helper om de volledige URL te bouwen
  Uri _buildUri(String endpoint) {
    // Zorg ervoor dat er geen dubbele slashes ontstaan
    String path = '/api/$endpoint'.replaceAll('//', '/');
    return Uri.parse('$_baseUrl$path');
  }

  // Haal alle events op
  Future<List<Event>> fetchEvents() async {
    final response = await http.get(_buildUri('event'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Event> events = body
          .map((dynamic item) => Event.fromJson(item as Map<String, dynamic>))
          .toList();
      return events;
    } else {
      // Gooi een exception of handel de fout af
      throw Exception('Failed to load events. Status code: ${response.statusCode}');
    }
  }

  // Haal alle prooidieren op
  Future<List<Prey>> fetchPrey() async {
    final response = await http.get(_buildUri('prey'));

    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Prey> preyList = body
          .map((dynamic item) => Prey.fromJson(item as Map<String, dynamic>))
          .toList();
      return preyList;
    } else {
      throw Exception('Failed to load prey types. Status code: ${response.statusCode}');
    }
  }

  // Stuur gebruikersfeedback in
  Future<void> submitUserRating(UserRating rating) async {
    final response = await http.post(
      _buildUri('user_rating'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8', // Belangrijk voor POST
      },
      body: jsonEncode(rating.toJson()), // Zet het Dart object om naar JSON string
    );

    if (response.statusCode == 200) {
      // Success!
      print('User rating submitted successfully.');
    } else {
      // Handel fouten af
      throw Exception('Failed to submit rating. Status code: ${response.statusCode}, Body: ${response.body}');
    }
  }

// Voeg hier methodes toe voor andere endpoints (get event by id, get video, etc.)
// Future<Event> fetchEventById(int id) async { ... }
// Future<List<Video>> fetchVideos() async { ... }
}