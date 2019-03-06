import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edenvidi_payment/edenvidi_payment.dart';

void main() {
  const MethodChannel channel = MethodChannel('edenvidi_payment');

  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await EdenvidiPayment.platformVersion, '42');
  });
}
