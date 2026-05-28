import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cbt_app/providers/auth_provider.dart';
import 'package:cbt_app/services/auth_service.dart';
import 'package:cbt_app/services/profile_service.dart';

class _MockAuthService extends Mock implements AuthService {}

class _MockProfileService extends Mock implements ProfileService {}

void main() {
  late _MockAuthService auth;
  late _MockProfileService profile;
  late AuthProvider provider;

  setUp(() {
    auth = _MockAuthService();
    profile = _MockProfileService();
    provider = AuthProvider(authService: auth, profileService: profile);
  });

  test('login rejects empty credentials without calling service', () async {
    expect(
      () => provider.login('', 'x'),
      throwsA(isA<Exception>()),
    );
    verifyNever(() => auth.loginStudent(any(), any()));
  });

  test('initial status is unknown', () {
    expect(provider.status, AuthStatus.unknown);
  });
}
