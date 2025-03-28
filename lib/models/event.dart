class Event {
  final int eventId;
  final int preyId;
  final DateTime time;
  final double confidence;

  Event({
    required this.eventId,
    required this.preyId,
    required this.time,
    required this.confidence,
  });

  // Factory constructor om JSON om te zetten naar een Event object
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as int,
      preyId: json['prey_id'] as int,
      time: DateTime.parse(json['time'] as String), // API gebruikt ISO 8601 string
      confidence: (json['confidence'] as num).toDouble(),
    );
  }
}