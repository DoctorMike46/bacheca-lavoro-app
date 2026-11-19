import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../models/models.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({required String baseUrl, this.token})
    : _baseUrl = _normalize(baseUrl);

  static const _timeout = Duration(seconds: 15);

  final http.Client _http = http.Client();
  String _baseUrl;
  String? token;

  String get baseUrl => _baseUrl;
  set baseUrl(String value) => _baseUrl = _normalize(value);

  static String _normalize(String url) {
    var value = url.trim();
    if (!value.startsWith('http://') && !value.startsWith('https://')) {
      value = 'http://$value';
    }
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl/api$path');

  Map<String, String> get _headers => {
    'content-type': 'application/json',
    if (token != null) 'authorization': 'Bearer $token',
  };

  Future<http.Response> _guard(Future<http.Response> Function() call) async {
    final http.Response response;
    try {
      response = await call().timeout(_timeout);
    } on TimeoutException {
      throw ApiException(
        'Il server non risponde. Controlla l\'indirizzo nelle impostazioni.',
      );
    } on SocketException {
      throw ApiException(
        'Server non raggiungibile. Controlla l\'indirizzo nelle impostazioni.',
      );
    } on http.ClientException {
      throw ApiException(
        'Server non raggiungibile. Controlla l\'indirizzo nelle impostazioni.',
      );
    }

    if (response.statusCode >= 400) {
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  String _errorMessage(http.Response response) {
    final fallback = 'Errore del server (${response.statusCode})';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['error'] is String) {
        return body['error'] as String;
      }
      return fallback;
    } on FormatException {
      return fallback;
    }
  }

  dynamic _json(http.Response response) =>
      jsonDecode(utf8.decode(response.bodyBytes));

  Future<dynamic> _get(String path) async =>
      _json(await _guard(() => _http.get(_uri(path), headers: _headers)));

  Future<dynamic> _post(String path, Map<String, Object?> body) async => _json(
    await _guard(
      () => _http.post(_uri(path), headers: _headers, body: jsonEncode(body)),
    ),
  );

  Future<void> ping() => _get('/health');

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) => _post('/auth/register', {
    'name': name,
    'email': email,
    'password': password,
  });

  Future<({String token, Company company})> login({
    required String email,
    required String password,
  }) async {
    final body = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return (
      token: body['token'] as String,
      company: Company.fromJson(body['company'] as Map<String, dynamic>),
    );
  }

  Future<void> logout() async {
    await _guard(() => _http.post(_uri('/auth/logout'), headers: _headers));
  }

  Future<Company> me() async =>
      Company.fromJson(await _get('/auth/me') as Map<String, dynamic>);

  Future<List<Job>> listJobs() async => [
    for (final item in await _get('/jobs') as List)
      Job.fromJson(item as Map<String, dynamic>),
  ];

  Future<Job> getJob(int id) async =>
      Job.fromJson(await _get('/jobs/$id') as Map<String, dynamic>);

  Future<List<Job>> myJobs() async => [
    for (final item in await _get('/my/jobs') as List)
      Job.fromJson(item as Map<String, dynamic>),
  ];

  Future<Job> createJob({
    required String title,
    required String description,
    String? location,
    String? contractType,
  }) async => Job.fromJson(
    await _post('/jobs', {
          'title': title,
          'description': description,
          'location': location,
          'contractType': contractType,
        })
        as Map<String, dynamic>,
  );

  Future<void> apply(int jobId, ApplicationDraft draft) async {
    final request =
        http.MultipartRequest('POST', _uri('/jobs/$jobId/applications'))
          ..fields.addAll({
            'firstName': draft.firstName,
            'lastName': draft.lastName,
            'email': draft.email,
            if (draft.phone != null) 'phone': draft.phone!,
            if (draft.message != null) 'message': draft.message!,
          })
          ..files.add(
            http.MultipartFile.fromBytes(
              'cv',
              draft.cvBytes,
              filename: draft.cvFilename,
            ),
          );

    await _guard(
      () async => http.Response.fromStream(await _http.send(request)),
    );
  }

  Future<List<JobApplication>> listApplications(int jobId) async => [
    for (final item in await _get('/jobs/$jobId/applications') as List)
      JobApplication.fromJson(item as Map<String, dynamic>),
  ];

  Future<JobApplication> getApplication(int id) async =>
      JobApplication.fromJson(
        await _get('/applications/$id') as Map<String, dynamic>,
      );

  Future<File> downloadCv(JobApplication application) async {
    final response = await _guard(
      () => _http.get(
        _uri('/applications/${application.id}/cv'),
        headers: _headers,
      ),
    );
    final dir = await getTemporaryDirectory();
    final safeName = application.cvFilename.replaceAll(
      RegExp(r'[^\w.\- ]'),
      '_',
    );
    final file = File('${dir.path}/cv_${application.id}_$safeName');
    return file.writeAsBytes(response.bodyBytes, flush: true);
  }
}
