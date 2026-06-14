import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cbt_app/config/env.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Source of truth for "trusted now" - guards against students cheating by
/// changing the device clock to enter an exam outside its scheduled window.
///
/// Strategy:
///   1. When online (e.g. on exam download or exam start), fetch the server
///      time and cache `offset = serverTime − deviceTime`.
///   2. `trustedNow()` returns `deviceTime + offset`. This still trusts that
///      the device clock has not been changed *between* the fetch and the use
///      - a reasonable assumption for the short download → start window.
///   3. Callers decide policy: require a fresh online fetch on start (strict),
///      or fall back to the cached offset when offline (lenient).
class TimeService {
  static const String _offsetKey = 'server_time_offset_ms';
  static const String _offsetCapturedAtKey = 'server_time_offset_captured_at';

  /// Hit the server and return its current time. Updates the cached offset.
  /// Throws on network failure - callers should handle and decide whether to
  /// fall back to the cached offset.
  static Future<DateTime> fetchServerTime() async {
    final uri = Uri.parse('${Env.apiBaseUrl}/time');
    final localBefore = DateTime.now();
    final response = await http
        .get(uri, headers: {'Content-Type': 'application/json'})
        .timeout(const Duration(seconds: 8));

    if (response.statusCode != 200) {
      throw HttpException('Server time request failed (${response.statusCode})');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final serverTime = DateTime.parse(body['now'] as String).toUtc();

    // Use the midpoint of the request to estimate the device time at which
    // the server captured 'now' - reduces the impact of network latency.
    final localAfter = DateTime.now();
    final midLocal = DateTime.fromMillisecondsSinceEpoch(
      (localBefore.millisecondsSinceEpoch + localAfter.millisecondsSinceEpoch) ~/ 2,
    );
    final offsetMs = serverTime.millisecondsSinceEpoch - midLocal.millisecondsSinceEpoch;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_offsetKey, offsetMs);
    await prefs.setString(_offsetCapturedAtKey, localAfter.toIso8601String());

    return serverTime;
  }

  /// Return the cached offset (server − device, in ms), or null if never set.
  static Future<int?> getCachedOffsetMs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_offsetKey);
  }

  /// When the cached offset was captured. Null if never set.
  static Future<DateTime?> getOffsetCapturedAt() async {
    final prefs = await SharedPreferences.getInstance();
    final iso = prefs.getString(_offsetCapturedAtKey);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  /// Compute trusted time from the cached offset. Returns null if no offset
  /// has ever been captured - caller must require an online fetch.
  static Future<DateTime?> trustedNowFromCache() async {
    final offsetMs = await getCachedOffsetMs();
    if (offsetMs == null) return null;
    return DateTime.now().add(Duration(milliseconds: offsetMs));
  }

  /// Best-effort trusted time: try the server first; on failure fall back to
  /// the cached offset. Returns null when there is no offset and no network.
  static Future<DateTime?> trustedNow() async {
    try {
      return await fetchServerTime();
    } catch (_) {
      return await trustedNowFromCache();
    }
  }
}
