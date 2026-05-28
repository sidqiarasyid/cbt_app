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
}
