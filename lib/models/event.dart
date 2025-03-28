class Event {
  final int eventId;
  final int preyId;
  final DateTime time;
  final double confidence;
  final String? thumbnailUrl; // Maak nullable voor echte data later
  final String? videoUrl;     // Maak nullable voor echte data later

  Event({
    required this.eventId,
    required this.preyId,
    required this.time,
    required this.confidence,
    this.thumbnailUrl, // Optioneel
    this.videoUrl,     // Optioneel
  });

  // Pas fromJson aan als de echte API dit NIET meestuurt
  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['event_id'] as int,
      preyId: json['prey_id'] as int,
      time: DateTime.parse(json['time'] as String),
      confidence: (json['confidence'] as num).toDouble(),
      // Haal deze uit JSON als API ze levert, anders blijven ze null
      thumbnailUrl: json['thumbnail_url'] as String?,
      videoUrl: json['video_url'] as String?,
    );
  }
}