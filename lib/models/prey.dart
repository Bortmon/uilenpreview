class Prey {
  final int preyId;
  final String name;

  Prey({required this.preyId, required this.name});

  factory Prey.fromJson(Map<String, dynamic> json) {
    return Prey(
      preyId: json['prey_id'] as int,
      name: json['name'] as String,
    );
  }
}
