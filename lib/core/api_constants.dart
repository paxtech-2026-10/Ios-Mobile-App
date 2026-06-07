class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
        'https://paxtech-ashgghgnf7fpfxe9.canadacentral-01.azurewebsites.net/api/v1',
  );

  static const String providerProfileEndpoint = '$baseUrl/provider-profiles';
  static const String authenticationEndpoint = '$baseUrl/authentication';
  static const String providersEndpoint = '$baseUrl/providers';
  static const String servicesEndpoint = '$baseUrl/services';
  static const String workersEndpoint = '$baseUrl/workers';
  static const String reservationsDetailsEndpoint =
      '$baseUrl/reservationsDetails';
  static const String discountsEndpoint = '$baseUrl/discounts';
  static const String reviewsEndpoint = '$baseUrl/reviews';
  static const String clientsEndpoint = '$baseUrl/clients';
}
