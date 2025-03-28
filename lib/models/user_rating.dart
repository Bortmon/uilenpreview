class UserRating {
  final int eventId;
  final bool aiPredictionCorrect;
  final int? userSuggestionPreyId; // Nullable

  UserRating({
    required this.eventId,
    required this.aiPredictionCorrect,
    this.userSuggestionPreyId,
  });

  // Methode om object om te zetten naar JSON voor POST request
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'event_id': eventId,
      'ai_prediction_correct': aiPredictionCorrect,
    };
    if (userSuggestionPreyId != null) {
      data['user_suggestion_prey_id'] = userSuggestionPreyId;
    }
    return data;
  }
}

