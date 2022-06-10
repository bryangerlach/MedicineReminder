class NotificationsCode {
  static Future<void> taken() async {
    print("taken");
  }

  static Future<void> snoozed() async {
    print("snoozed");
  }

  static Future<void> tapped() async {
    print("tapped");
  }
}