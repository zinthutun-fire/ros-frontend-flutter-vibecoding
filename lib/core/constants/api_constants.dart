import 'dart:convert';
import 'dart:io' show Platform;
import 'package:flutter/services.dart' show rootBundle;

class ApiConstants {
  ApiConstants._();

  static String? _cachedBaseUrl;
  static String? _cachedWsBaseUrl;
  static String? _cachedReverbWsUrl;
  static int? _cachedReverbPort;

  static Future<void> init() async {
    try {
      final content = await rootBundle.loadString('assets/.env');
      for (final line in content.split('\n')) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        final eq = trimmed.indexOf('=');
        if (eq < 1) continue;
        final key = trimmed.substring(0, eq).trim();
        final value = trimmed.substring(eq + 1).trim();
        if (key == 'API_BASE_URL') _cachedBaseUrl = value;
        if (key == 'WS_BASE_URL') _cachedWsBaseUrl = value;
        if (key == 'REVERB_WS_URL') _cachedReverbWsUrl = value;
        if (key == 'REVERB_PORT') _cachedReverbPort = int.tryParse(value);
      }
    } catch (_) {}
  }

  static Map<String, dynamic> parseResponse(dynamic data) {
    if (data is String) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return data as Map<String, dynamic>;
  }

  static String get baseUrl {
    const envUrl = String.fromEnvironment('API_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (_cachedBaseUrl != null) return _cachedBaseUrl!;
    return Platform.isAndroid ? 'http://10.0.2.2:8000/api' : 'http://localhost:8000/api';
  }

  static String get wsBaseUrl {
    const envUrl = String.fromEnvironment('WS_BASE_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (_cachedWsBaseUrl != null) return _cachedWsBaseUrl!;
    return Platform.isAndroid ? 'ws://10.0.2.2:8000' : 'ws://localhost:8000';
  }

  static String get reverbWsUrl {
    const envUrl = String.fromEnvironment('REVERB_WS_URL');
    if (envUrl.isNotEmpty) return envUrl;
    if (_cachedReverbWsUrl != null) return _cachedReverbWsUrl!;
    return Platform.isAndroid ? 'ws://10.0.2.2:8080' : 'ws://localhost:8080';
  }

  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 15);

  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String tables = '/tables';
  static const String menuItems = '/menu-items';
  static const String orders = '/orders';
  static const String tableTransfer = '/table-transfers';
  static const String tableMerge = '/table-merges';
  static const String categories = '/categories';
  static const String cashierOrders = '/cashier/orders';
  static const String payments = '/payments';
  static const String kitchenOrders = '/kitchen/orders';
  static const String kitchenItemStatus = '/kitchen/item-status';
  static const String taxRates = '/tax-rates';
  static const String tableAreas = '/table-areas';
  static const String kitchens = '/kitchens';

  static const String reverbAppKey = 'restaurant-key';
  static const String reverbHost = 'restaurant-key';

  static int get reverbPort {
    const envPort = String.fromEnvironment('REVERB_PORT');
    if (envPort.isNotEmpty) return int.tryParse(envPort) ?? 8080;
    if (_cachedReverbPort != null) return _cachedReverbPort!;
    return 8080;
  }
}
