import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';
import '../services/api_client.dart';

class Session extends ChangeNotifier {
  Session._(this._prefs, this.api);

  static const _tokenKey = 'auth_token';
  static const _serverKey = 'server_url';
  static const _defineUrl = String.fromEnvironment('API_BASE_URL');

  final SharedPreferences _prefs;
  final ApiClient api;
  Company? _company;

  Company? get company => _company;
  bool get isAuthenticated => _company != null;

  static String get defaultServerUrl {
    if (_defineUrl.isNotEmpty) return _defineUrl;
    // L'emulatore Android raggiunge il computer host su 10.0.2.2.
    return Platform.isAndroid
        ? 'http://10.0.2.2:8080'
        : 'http://localhost:8080';
  }

  static Future<Session> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final session = Session._(
      prefs,
      ApiClient(
        baseUrl: prefs.getString(_serverKey) ?? defaultServerUrl,
        token: prefs.getString(_tokenKey),
      ),
    );
    await session._restoreCompany();
    return session;
  }

  Future<void> _restoreCompany() async {
    if (api.token == null) return;
    try {
      _company = await api.me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) await _clearToken();
    }
  }

  Future<void> setServerUrl(String url) async {
    api.baseUrl = url;
    await _prefs.setString(_serverKey, api.baseUrl);
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    final result = await api.login(email: email, password: password);
    api.token = result.token;
    await _prefs.setString(_tokenKey, result.token);
    _company = result.company;
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } on ApiException catch (e) {
      debugPrint('Logout sul server non riuscito: ${e.message}');
    }
    await _clearToken();
    _company = null;
    notifyListeners();
  }

  Future<void> _clearToken() async {
    api.token = null;
    await _prefs.remove(_tokenKey);
  }
}
