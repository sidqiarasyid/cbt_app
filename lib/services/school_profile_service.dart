import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cbt_app/models/school_profile_model.dart';
import 'package:cbt_app/utils/url.dart';
import 'package:http/http.dart' as http;

/// Service to fetch the school profile from the backend.
/// Uses a simple in-memory cache so repeated calls don't hit the network.
class SchoolProfileService {
  static SchoolProfileModel? _cache;
  static DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 30);

  /// Fetch the school profile. Returns cached data if available and fresh.
  /// Falls back to a default profile if the network request fails.
  static Future<SchoolProfileModel> fetchProfile({bool forceRefresh = false}) async {
    // Return cache if still valid
    if (!forceRefresh &&
        _cache != null &&
        _lastFetch != null &&
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cache!;
    }

    try {
      final uri = Uri.parse('${Url.baseUrl}/school-profile');
      final response = await http
          .get(uri, headers: {'Content-Type': 'application/json'})
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final data = body['data'] ?? body;
        _cache = SchoolProfileModel.fromJson(data);
        _lastFetch = DateTime.now();
        return _cache!;
      }
    } on SocketException {
      // No internet — use cache or fallback
    } on TimeoutException {
      // Timeout — use cache or fallback
    } catch (_) {
      // Any other error — use cache or fallback
    }

    return _cache ?? SchoolProfileModel.fallback();
  }

  /// Clear the cache (useful after admin updates or on logout)
  static void clearCache() {
    _cache = null;
    _lastFetch = null;
  }
}
