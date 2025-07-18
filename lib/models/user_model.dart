import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? language;
  final DateTime? birthDate;
  final List<String> selectedSports;
  final List<String> positions;
  final double? socialScore;
  final bool isSetupComplete;
  final String? activeSport;
  final String? country;

  UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.language,
    this.birthDate,
    this.selectedSports = const [],
    this.positions = const [],
    this.socialScore,
    this.isSetupComplete = false,
    this.activeSport,
    this.country,
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    return UserModel(
      id: id,
      firstName: data['firstName'] ?? '',
      lastName: data['lastName'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'],
      avatarUrl: data['avatarUrl'],
      language: data['language'],
      birthDate: () {
        final raw = data['birthDate'];
        if (raw is Timestamp) return raw.toDate();
        if (raw is String) return DateTime.tryParse(raw);
        return null;
      }(),
      selectedSports: List<String>.from(data['selectedSports'] ?? []),
      positions: List<String>.from(data['positions'] ?? []),
      socialScore: data['socialScore'] != null
          ? (data['socialScore'] as num).toDouble()
          : null,
      isSetupComplete: data['isSetupComplete'] == true,
      activeSport: data['activeSport'],
      country: data['country'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'language': language,
      'birthDate': birthDate,
      'selectedSports': selectedSports,
      'positions': positions,
      'socialScore': socialScore,
      'isSetupComplete': isSetupComplete,
      'activeSport': activeSport,
      'country': country
    };
  }

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? avatarUrl,
    String? language,
    DateTime? birthDate,
    List<String>? selectedSports,
    List<String>? positions,
    double? socialScore,
    bool? isSetupComplete,
    String? activeSport,
    String? country,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      language: language ?? this.language,
      birthDate: birthDate ?? this.birthDate,
      selectedSports: selectedSports ?? this.selectedSports,
      positions: positions ?? this.positions,
      socialScore: socialScore ?? this.socialScore,
      isSetupComplete: isSetupComplete ?? this.isSetupComplete,
      activeSport: activeSport ?? this.activeSport,
      country: country ?? this.country
    );
  }
}
