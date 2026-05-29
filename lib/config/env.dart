/// Application environment configuration.
///
/// Override at build/run time:
/// flutter run --dart-define=API_BASE_URL=https://your-host/api
class Env {
  const Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://crouton-boxlike-dove.ngrok-free.dev/api',
  );

  /// API host without the trailing "/api" — used to build absolute URLs for
  /// static assets the backend serves at "/uploads/...".
  static String get apiOrigin {
    final uri = Uri.parse(apiBaseUrl);
    return '${uri.scheme}://${uri.authority}';
  }

  /// Resolve a stored URL (logo, question image, etc.) into something
  /// `Image.network` can fetch:
  ///   - null/empty -> null
  ///   - absolute (http/https) -> unchanged
  ///   - "/uploads/..." path -> prefixed with [apiOrigin]
  static String? resolveAssetUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    if (value.startsWith('/')) return '$apiOrigin$value';
    return value;
  }
}
