import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:iosmobileapp/core/api_constants.dart';
import 'package:iosmobileapp/core/services/onboarding_service.dart';
import 'package:iosmobileapp/features/reviews/domain/review.dart';

class ReviewsService {
  ReviewsService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  final _onboardingService = OnboardingService();

  static const String _baseUrl = ApiConstants.reviewsEndpoint;

  Future<Map<String, String>> get _headers async {
    final token = await _onboardingService.getJwtToken();
    if (token == null || token.isEmpty) {
      throw HttpException(
        'No se encontró token de autenticación. Por favor inicia sesión nuevamente.',
        uri: Uri.parse(_baseUrl),
      );
    }
    return {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
  }

  Future<List<Review>> getReviews() async {
    final headers = await _headers;
    final uri = Uri.parse(_baseUrl);
    
    final response = await _client.get(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok) {
      if (response.body.isEmpty) {
        return <Review>[];
      }
      final decoded = jsonDecode(response.body);
      if (decoded == null) {
        return <Review>[];
      }

      if (decoded is List) {
        return decoded
            .map((json) => Review.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return <Review>[];
    }
    if (response.statusCode == HttpStatus.notFound) {
      return <Review>[];
    }

    throw HttpException(
      'Failed to load reviews. Status code: ${response.statusCode}',
      uri: uri,
    );
  }

  Future<Review> createReview({
    required int clientId,
    required int providerId,
    required int rating,
    required String review,
  }) async {
    final headers = await _headers;
    // El backend espera CreateReviewResource(clientId, providerId, rating, review).
    // Antes se enviaban clientName/clientEmail/comment, que el backend ignoraba:
    // la reseña se guardaba sin texto (review=null) y sin cliente (clientId=null).
    final body = jsonEncode({
      'clientId': clientId,
      'providerId': providerId,
      'rating': rating,
      'review': review,
    });

    final response = await _client.post(
      Uri.parse(_baseUrl),
      headers: headers,
      body: body,
    );

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.created) {
      return Review.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw HttpException(
      'Failed to create review. Status code: ${response.statusCode}',
      uri: Uri.parse(_baseUrl),
    );
  }

  Future<void> deleteReview(int reviewId) async {
    final headers = await _headers;
    final uri = Uri.parse('$_baseUrl/$reviewId');
    final response = await _client.delete(uri, headers: headers);

    if (response.statusCode == HttpStatus.ok ||
        response.statusCode == HttpStatus.noContent) {
      return;
    }

    throw HttpException(
      'Failed to delete review $reviewId. Status code: ${response.statusCode}',
      uri: uri,
    );
  }
}

