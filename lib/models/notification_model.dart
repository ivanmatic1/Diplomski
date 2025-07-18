class NotificationModel {
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;

  NotificationModel({required this.title, required this.body, required this.timestamp, this.read = false});
}
