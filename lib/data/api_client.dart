import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

String suggestedApiBaseUrl() {
  if (kIsWeb) return 'http://127.0.0.1:8000';
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'http://10.0.2.2:8000';
    default:
      return 'http://127.0.0.1:8000';
  }
}

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({this.baseUrl = '', http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  String baseUrl;
  final http.Client _http;
  static const _timeout = Duration(seconds: 2);

  bool get enabled => baseUrl.trim().isNotEmpty;

  Uri _uri(String path) {
    final root = baseUrl.trim().replaceAll(RegExp(r'/$'), '');
    return Uri.parse('$root$path');
  }

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  String _errorMessage(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      final detail = body['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
      }
    } catch (_) {}
    return 'Erreur serveur (${response.statusCode})';
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Object? body,
  }) async {
    if (!enabled) {
      throw ApiException('URL de l’API non configurée');
    }
    final uri = _uri(path);
    final encoded = body == null ? null : jsonEncode(body);
    late http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _http.get(uri, headers: _headers).timeout(_timeout);
        case 'POST':
          response = await _http
              .post(uri, headers: _headers, body: encoded)
              .timeout(_timeout);
        case 'PUT':
          response = await _http
              .put(uri, headers: _headers, body: encoded)
              .timeout(_timeout);
        case 'PATCH':
          response = await _http
              .patch(uri, headers: _headers, body: encoded)
              .timeout(_timeout);
        case 'DELETE':
          response =
              await _http.delete(uri, headers: _headers).timeout(_timeout);
        default:
          throw ApiException('Méthode HTTP inconnue');
      }
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException('Serveur injoignable');
    }
    if (response.statusCode >= 400) {
      throw ApiException(_errorMessage(response), statusCode: response.statusCode);
    }
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<bool> ping() async {
    if (!enabled) return false;
    try {
      final response =
          await _http.get(_uri('/health'), headers: _headers).timeout(_timeout);
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> getContest() => _send('GET', '/api/contest');

  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> body) =>
      _send('PATCH', '/api/contest', body: body);

  Future<Map<String, dynamic>> resetContest() =>
      _send('POST', '/api/contest/reset');

  Future<Map<String, dynamic>> startRound1() =>
      _send('POST', '/api/contest/actions/start-round-1');

  Future<Map<String, dynamic>> closeRound1() =>
      _send('POST', '/api/contest/actions/close-round-1');

  Future<Map<String, dynamic>> startRound2() =>
      _send('POST', '/api/contest/actions/start-round-2');

  Future<Map<String, dynamic>> finishContest() =>
      _send('POST', '/api/contest/actions/finish');

  Future<Map<String, dynamic>> upsertCandidate(Map<String, dynamic> body) =>
      _send('POST', '/api/candidates', body: body);

  Future<Map<String, dynamic>> deleteCandidate(String id) =>
      _send('DELETE', '/api/candidates/$id');

  Future<Map<String, dynamic>> saveScore({
    required String candidateId,
    required int round,
    required Map<String, double> values,
  }) =>
      _send(
        'PUT',
        '/api/scores/$candidateId/$round',
        body: {'values': values},
      );
}
