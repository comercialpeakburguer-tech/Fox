import 'package:shared_preferences/shared_preferences.dart';

class DeliverymanAvailabilityHelper {
  static const String _availabilityKey = 'deliveryman_availability_status';
  static const String online = 'online';
  static const String offline = 'offline';

  static Future<void> setOnline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_availabilityKey, online);
  }

  static Future<void> setOffline() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_availabilityKey, offline);
  }

  static Future<String?> getStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_availabilityKey);
  }

  static Future<bool> isOnlineSafe() async {
    final status = await getStatus();
    return status == online;
  }
}
