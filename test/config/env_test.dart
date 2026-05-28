import 'package:flutter_test/flutter_test.dart';
import 'package:cbt_app/config/env.dart';

void main() {
  test('Env.apiBaseUrl has non-empty default', () {
    expect(Env.apiBaseUrl, isNotEmpty);
    expect(Env.apiBaseUrl, startsWith('http'));
  });
}
