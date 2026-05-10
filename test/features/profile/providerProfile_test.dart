// Core entity unit tests for the Profiles bounded context.
// Covers ProviderProfile, ProfileSocials, and PortfolioImage.

import 'package:flutter_test/flutter_test.dart';
import 'package:iosmobileapp/features/profile/domain/providerProfile.dart';

void main() {
  group('ProviderProfile', () {
    test('default portfolioImages should be an empty list', () {
      final profile = ProviderProfile(
        id: 1,
        providerId: 10,
        companyName: 'Pax Salon',
        location: 'Lima, Peru',
      );

      expect(profile.portfolioImages, isEmpty);
      expect(profile.email, isNull);
      expect(profile.socials, isNull);
      expect(profile.profileImageUrl, isNull);
      expect(profile.coverImageUrl, isNull);
      expect(profile.description, isNull);
      expect(profile.openTime, isNull);
      expect(profile.closeTime, isNull);
    });

    test('fromJson should deserialize all required fields', () {
      final json = {
        'id': 1,
        'providerId': 10,
        'companyName': 'Pax Salon',
        'location': 'Lima, Peru',
        'email': 'pax@paxtech.com',
        'profileImageUrl': 'https://cdn/p.png',
        'coverImageUrl': 'https://cdn/c.png',
        'description': 'Best salon in town',
        'openTime': '09:00',
        'closeTime': '20:00',
        'portfolioImages': [
          {'id': 1, 'imageUrl': 'https://cdn/img1.png'},
          {'id': 2, 'imageUrl': 'https://cdn/img2.png'},
        ],
        'socials': {
          'additionalProp1': 'https://ig/pax',
          'additionalProp2': null,
          'additionalProp3': null,
        },
      };

      final profile = ProviderProfile.fromJson(json);

      expect(profile.id, 1);
      expect(profile.providerId, 10);
      expect(profile.companyName, 'Pax Salon');
      expect(profile.location, 'Lima, Peru');
      expect(profile.email, 'pax@paxtech.com');
      expect(profile.profileImageUrl, 'https://cdn/p.png');
      expect(profile.portfolioImages.length, 2);
      expect(profile.portfolioImages.first.imageUrl, 'https://cdn/img1.png');
      expect(profile.socials, isNotNull);
      expect(profile.socials!.additionalProp1, 'https://ig/pax');
    });

    test('fromJson should fall back to empty location and empty portfolio', () {
      final json = {
        'id': 5,
        'providerId': 20,
        'companyName': 'Studio',
      };

      final profile = ProviderProfile.fromJson(json);

      expect(profile.location, '');
      expect(profile.portfolioImages, isEmpty);
      expect(profile.socials, isNull);
    });

    test('toJson should round-trip the entity', () {
      final original = ProviderProfile(
        id: 7,
        providerId: 11,
        companyName: 'Pax',
        location: 'Lima',
        email: 'p@p.com',
        portfolioImages: [
          PortfolioImage(id: 1, imageUrl: 'https://cdn/a.png'),
        ],
      );

      final json = original.toJson();
      final restored = ProviderProfile.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.companyName, original.companyName);
      expect(restored.location, original.location);
      expect(restored.email, original.email);
      expect(restored.portfolioImages.length, 1);
      expect(restored.portfolioImages.first.imageUrl, 'https://cdn/a.png');
    });

    test('toUpdateJson should expose only mutable fields', () {
      final profile = ProviderProfile(
        id: 1,
        providerId: 10,
        companyName: 'Pax Salon',
        location: 'Lima',
        profileImageUrl: 'https://cdn/p.png',
        coverImageUrl: 'https://cdn/c.png',
        description: 'desc',
        openTime: '09:00',
        closeTime: '20:00',
        portfolioImages: [
          PortfolioImage(id: 1, imageUrl: 'https://cdn/img1.png'),
        ],
      );

      final update = profile.toUpdateJson();

      expect(update.containsKey('id'), isFalse);
      expect(update.containsKey('providerId'), isFalse);
      expect(update['companyName'], 'Pax Salon');
      expect(update['location'], 'Lima');
      expect(update['profileImageUrl'], 'https://cdn/p.png');
      expect(update['portfolioImages'], ['https://cdn/img1.png']);
      expect(update['socials'], {});
    });

    test('copyWith should override only specified fields', () {
      final profile = ProviderProfile(
        id: 1,
        providerId: 10,
        companyName: 'Old',
        location: 'Lima',
      );

      final updated = profile.copyWith(companyName: 'New', location: 'Cusco');

      expect(updated.id, 1);
      expect(updated.providerId, 10);
      expect(updated.companyName, 'New');
      expect(updated.location, 'Cusco');
    });
  });

  group('ProfileSocials', () {
    test('toJson should omit null fields', () {
      final socials = ProfileSocials(additionalProp1: 'https://ig/pax');

      final json = socials.toJson();

      expect(json, {'additionalProp1': 'https://ig/pax'});
    });

    test('fromJson should hydrate present fields', () {
      final socials = ProfileSocials.fromJson({
        'additionalProp1': 'a',
        'additionalProp2': 'b',
      });

      expect(socials.additionalProp1, 'a');
      expect(socials.additionalProp2, 'b');
      expect(socials.additionalProp3, isNull);
    });
  });

  group('PortfolioImage', () {
    test('round-trips through toJson and fromJson', () {
      final original = PortfolioImage(id: 5, imageUrl: 'https://cdn/x.png');

      final restored = PortfolioImage.fromJson(original.toJson());

      expect(restored.id, 5);
      expect(restored.imageUrl, 'https://cdn/x.png');
    });
  });
}
