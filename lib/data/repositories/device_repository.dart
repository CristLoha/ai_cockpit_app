import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceRepository {
  static const String _deviceKey = 'device_id';
  final Uuid _uuid = Uuid();

  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString(_deviceKey);

    if (deviceId == null) {
      deviceId = _uuid.v4();
      await prefs.setString(_deviceKey, deviceId);

      print('Generated new device ID: $deviceId');
    }
    return deviceId;
  }
}
