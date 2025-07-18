class StatModel {
  final int matchesPlayed;
  final double winRate;
  final double averageRating;

  StatModel({
    required this.matchesPlayed,
    required this.winRate,
    required this.averageRating,
  });

  factory StatModel.fromMap(Map<String, dynamic> map) {
    return StatModel(
      matchesPlayed: map['matchesPlayed'] ?? 0,
      winRate: (map['winRate'] ?? 0).toDouble(),
      averageRating: (map['averageRating'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'matchesPlayed': matchesPlayed,
      'winRate': winRate,
      'averageRating': averageRating,
    };
  }

  factory StatModel.empty() {
    return StatModel(
      matchesPlayed: 0,
      winRate: 0.0,
      averageRating: 0.0,
    );
  }
}
