import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static Future<bool> isAndroid13OrAbove() async {
    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.version.sdkInt >= 33; // Android 13 = SDK 33
  }
}