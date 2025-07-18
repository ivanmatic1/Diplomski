import 'package:terminko/models/user_model.dart';

class FriendModel {
  final String id;
  final UserModel user;

  FriendModel({
    required this.id,
    required this.user,
  });

  factory FriendModel.fromUserModel(String id, Map<String, dynamic> userData) {
    return FriendModel(
      id: id,
      user: UserModel.fromMap(id, userData),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user': user.toMap(),
    };
  }
}
