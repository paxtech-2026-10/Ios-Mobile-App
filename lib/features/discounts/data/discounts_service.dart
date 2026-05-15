import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:iosmobileapp/core/api_constants.dart';
import 'package:iosmobileapp/core/services/onboarding_service.dart';
import 'package:iosmobileapp/features/discounts/domain/discount.dart';
import 'package:iosmobileapp/features/profile/data/providerProfile_service.dart';

class DiscountsService {
  DiscountsService({http.Client? client})
      : _client = client ?? http.Client(),
        _onboardingService = OnboardingService();

  final http.Client _client;
  final OnboardingService _onboardingService;

  static const String _baseUrl = ApiConstants.discountsEndpoint;

  Future<Map<String, String>> get _headers async {
    final token = await _onboardingService.getJwtToken();
    if (token == null || token.isEmpty) {
      print('❌ [DiscountsService] No se encontró token JWT');
      throw HttpException(
        'No se encontró token de autenticación. Por favor inicia sesión nuevamente.',
        uri: Uri.parse(_baseUrl),
      );
    }
    print('✅ [DiscountsService] Token JWT obtenido: ${token.substring(0, 20)}...');
    final headers = {
      HttpHeaders.authorizationHeader: 'Bearer $token',
      HttpHeaders.contentTypeHeader: 'application/json',
    };
    print('🔑 [DiscountsService] Headers: Authorization: Bearer ${token.substring(0, 20)}...');
    return headers;
  }

  /// Obtiene el providerProfileId buscando el ProviderProfile que corresponde al providerId actual
  Future<int> _getProviderProfileId() async {
    try {
      print('🔍 [DiscountsService] Obteniendo providerId...');
      final providerId = await _onboardingService.getProviderId();
      if (providerId == null) {
        throw Exception(
          'Provider ID no encontrado. Por favor inicia sesión nuevamente.',
        );
      }
      print('✅ [DiscountsService] ProviderId obtenido: $providerId');
      
      // Buscar el ProviderProfile que tiene este providerId
      print('🔍 [DiscountsService] Buscando ProviderProfile con providerId: $providerId');
      final profileService = ProviderprofileService();
      final profile = await profileService.getCurrentProfile();
      
      if (profile.id == null) {
        throw Exception(
          'El ProviderProfile no tiene un ID válido. Por favor contacta al soporte.',
        );
      }
      
      print('✅ [DiscountsService] ProviderProfile encontrado: id=${profile.id}, providerId=${profile.providerId}');
      return profile.id!;
    } catch (e) {
      print('❌ [DiscountsService] Error obteniendo providerProfileId: $e');
      rethrow;
    }
  }

  Future<List<Discount>> getDiscounts() async {
    try {
      print('🚀 [DiscountsService] Iniciando getDiscounts()...');
      
      // Obtener token primero para verificar
      final token = await _onboardingService.getJwtToken();
      print('🔑 [DiscountsService] Token obtenido: ${token != null ? "✅ Existe (${token.length} caracteres)" : "❌ No existe"}');
      if (token != null && token.isNotEmpty) {
        print('🔑 [DiscountsService] Token preview: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
      }
      
      final providerProfileId = await _getProviderProfileId();
      print('🆔 [DiscountsService] ProviderProfileId: $providerProfileId');
      
      final headers = await _headers;
      print('📋 [DiscountsService] Headers obtenidos: ${headers.keys.toList()}');
      print('📋 [DiscountsService] Authorization header presente: ${headers.containsKey(HttpHeaders.authorizationHeader)}');
      
      // El endpoint correcto es /api/v1/discounts/provider-profile/{providerProfileId}
      final uri = Uri.parse('$_baseUrl/provider-profile/$providerProfileId');
      print('🌐 [DiscountsService] URL completa: $uri');
      
      print('📤 [DiscountsService] Enviando petición GET...');
      final response = await _client.get(uri, headers: headers);
      
      print('📥 [DiscountsService] Respuesta recibida');
      print('📊 [DiscountsService] Status code: ${response.statusCode}');
      print('📄 [DiscountsService] Response body: ${response.body.isNotEmpty ? response.body : "(vacío)"}');
      
      if (response.statusCode == 401) {
        print('❌ [DiscountsService] Error 401: No autorizado');
        print('❌ [DiscountsService] Verificar:');
        print('   - Token JWT válido y no expirado');
        print('   - Header Authorization presente en la petición');
        print('   - Permisos del usuario para acceder a descuentos');
      }

      if (response.statusCode == HttpStatus.ok) {
        if (response.body.isEmpty) {
          return <Discount>[];
        }
        final decoded = jsonDecode(response.body);
        if (decoded == null) {
          return <Discount>[];
        }

        if (decoded is List) {
          return decoded
              .map((json) => Discount.fromJson(json as Map<String, dynamic>))
              .toList();
        }
        return <Discount>[];
      }
      if (response.statusCode == HttpStatus.notFound) {
        return <Discount>[];
      }

      throw HttpException(
        'Error al cargar cupones. Status code: ${response.statusCode}',
        uri: uri,
      );
    } catch (e) {
      print('❌ [DiscountsService] Error: $e');
      rethrow;
    }
  }

  Future<Discount> createDiscount(Discount discount) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse(_baseUrl);
      final body = jsonEncode(discount.toJson());

      final response = await _client.post(uri, headers: headers, body: body);

      if (response.statusCode == HttpStatus.ok ||
          response.statusCode == HttpStatus.created) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Discount.fromJson(decoded);
      }

      throw HttpException(
        'Error al crear cupón. Status code: ${response.statusCode}',
        uri: uri,
      );
    } catch (e) {
      print('❌ [DiscountsService] Error creando cupón: $e');
      rethrow;
    }
  }

  Future<Discount> updateDiscount(Discount discount) async {
    try {
      if (discount.id == null) {
        throw Exception('El cupón debe tener un ID para actualizarlo');
      }

      final headers = await _headers;
      final uri = Uri.parse('$_baseUrl/${discount.id}');
      final body = jsonEncode(discount.toJson());

      final response = await _client.put(uri, headers: headers, body: body);

      if (response.statusCode == HttpStatus.ok) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return Discount.fromJson(decoded);
      }

      throw HttpException(
        'Error al actualizar cupón. Status code: ${response.statusCode}',
        uri: uri,
      );
    } catch (e) {
      print('❌ [DiscountsService] Error actualizando cupón: $e');
      rethrow;
    }
  }

  Future<void> deleteDiscount(int discountId) async {
    try {
      final headers = await _headers;
      final uri = Uri.parse('$_baseUrl/$discountId');

      final response = await _client.delete(uri, headers: headers);

      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.noContent) {
        throw HttpException(
          'Error al eliminar cupón. Status code: ${response.statusCode}',
          uri: uri,
        );
      }
    } catch (e) {
      print('❌ [DiscountsService] Error eliminando cupón: $e');
      rethrow;
    }
  }
}

