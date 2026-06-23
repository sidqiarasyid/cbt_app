import 'package:flutter_test/flutter_test.dart';
import 'package:cbt_app/utils/session_guard.dart';

void main() {
  test('SessionExpiredException is an Exception and carries its message', () {
    final e = SessionExpiredException('Akun login di perangkat lain');
    expect(e, isA<Exception>());
    expect(e.toString(), 'Akun login di perangkat lain');
  });

  test('SessionExpiredException has a default message', () {
    expect(SessionExpiredException().toString(), isNotEmpty);
  });
}
