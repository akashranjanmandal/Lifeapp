import 'dart:async';
import 'dart:io';

class InternetUtils {
  static Future<bool> hasInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return true;
      }
      return false;
    } on SocketException catch (_) {
      return false;
    }
  }

  // Alternative: Check multiple domains for better reliability
  static Future<bool> checkInternetWithFallback() async {
    const List<String> domains = [
      'google.com',
      'cloudflare.com',
      'apple.com',
      'microsoft.com'
    ];

    for (final domain in domains) {
      try {
        final result = await InternetAddress.lookup(domain)
            .timeout(const Duration(seconds: 3));
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }
    return false;
  }
}