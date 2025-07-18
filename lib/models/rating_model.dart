class RatingModel {
  final String raterId;
  final String rateeId;
  final String matchId;
  final double value;

  RatingModel({
    required this.raterId,
    required this.rateeId,
    required this.matchId,
    required this.value,
  });

  Map<String, dynamic> toMap() {
    return {
      'raterId': raterId,
      'rateeId': rateeId,
      'matchId': matchId,
      'value': value,
    };
  }

  factory RatingModel.fromMap(Map<String, dynamic> data) {
    return RatingModel(
      raterId: data['raterId'],
      rateeId: data['rateeId'],
      matchId: data['matchId'],
      value: (data['value'] as num).toDouble(),
    );
  }
}