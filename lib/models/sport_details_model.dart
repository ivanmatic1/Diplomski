class SportDetailsModel {
  final List<String> positions;
  final List<String> matchTypes;
  final String preferredTime;
  final Map<String, dynamic>? location;

  SportDetailsModel({
    required this.positions,
    required this.matchTypes,
    required this.preferredTime,
    this.location,
  });

  factory SportDetailsModel.fromMap(Map<String, dynamic> data) {
    return SportDetailsModel(
      positions: List<String>.from(data['positions'] ?? []),
      matchTypes: List<String>.from(data['matchTypes'] ?? []),
      preferredTime: data['preferredTime'] ?? '',
      location: data['location'],
    );
  }

  Map<String, dynamic> toMap() => {
    'positions': positions,
    'matchTypes': matchTypes,
    'preferredTime': preferredTime,
    'location': location,
  };
}
