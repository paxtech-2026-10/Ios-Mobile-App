// Core entity unit tests for the IAM bounded context.
// Covers SignUpResponse, SignInResponse, and ProviderResponse JSON parsing.

import 'package:flutter_test/flutter_test.dart';
import 'package:iosmobileapp/features/auth/data/auth_service.dart';

void main() {
  group('SignUpResponse', () {
    test('parses id and email from JSON', () {
      final json = {'id': 7, 'email': 'gael@paxtech.com'};

      final response = SignUpResponse.fromJson(json);

      expect(response.id, 7);
      expect(response.email, 'gael@paxtech.com');
    });

    test('throws when required field is missing', () {
      expect(
        () => SignUpResponse.fromJson({'id': 1}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('SignInResponse', () {
    test('parses id, email and token from JSON', () {
      final json = {
        'id': 12,
        'email': 'gael@paxtech.com',
        'token': 'jwt.token.here',
      };

      final response = SignInResponse.fromJson(json);

      expect(response.id, 12);
      expect(response.email, 'gael@paxtech.com');
      expect(response.token, 'jwt.token.here');
    });

    test('requires non-null token', () {
      expect(
        () => SignInResponse.fromJson({
          'id': 1,
          'email': 'a@a.com',
          'token': null,
        }),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('ProviderResponse', () {
    test('parses id, companyName, and userId from JSON', () {
      final json = {
        'id': 3,
        'companyName': 'Pax Salon',
        'userId': 99,
      };

      final response = ProviderResponse.fromJson(json);

      expect(response.id, 3);
      expect(response.companyName, 'Pax Salon');
      expect(response.userId, 99);
    });
  });
}
