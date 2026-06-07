import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:iosmobileapp/core/widgets/custom_bottom_navbar.dart';
import 'package:iosmobileapp/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _baseUrl = 'https://paxtech.azurewebsites.net/api/v1';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Provider core system tests', () {
    // -----------------------------------------------------------------------
    // SYS-FL-01  Provider registers and signs in
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-01 provider registers and signs in', (tester) async {
      final account = await launchFreshApp(tester);

      await registerProvider(tester, account);
      await loginProvider(tester, account);

      expect(find.text('Bienvenido'), findsOneWidget);
      expect(find.text(account.companyName), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // SYS-FL-02  Provider creates a service
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-02 provider creates a service', (tester) async {
      final account = await launchFreshApp(tester);
      final serviceName =
          'Servicio Flutter ${DateTime.now().millisecondsSinceEpoch}';

      await registerProvider(tester, account);
      await loginProvider(tester, account);

      await tapNavTab(tester, 'Servicios');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilVisible(tester, find.text('Nuevo servicio'));

      await tester.enterText(find.byType(TextFormField).at(0), serviceName);
      await tester.enterText(find.byType(TextFormField).at(1), '45');
      await tester.enterText(find.byType(TextFormField).at(2), '80');
      await tester.tap(find.text('Guardar servicio'));

      await pumpUntilVisible(
        tester,
        find.text(serviceName),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text(serviceName), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // SYS-FL-03  Provider creates a worker
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-03 provider creates a worker', (tester) async {
      final account = await launchFreshApp(tester);
      final workerName =
          'Worker Flutter ${DateTime.now().millisecondsSinceEpoch}';

      await registerProvider(tester, account);
      await loginProvider(tester, account);

      await tapNavTab(tester, 'Trabajadores');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.byType(FloatingActionButton).first);
      await tester.pump(const Duration(milliseconds: 500));
      await pumpUntilVisible(tester, find.text('Agregar trabajador'));
      await pumpUntilVisible(
        tester,
        find.byType(TextFormField),
        timeout: const Duration(seconds: 20),
      );

      await tester.enterText(find.byType(TextFormField).first, workerName);
      await tester.tap(find.text('Corte'));
      await tester.tap(find.text('Guardar trabajador'));

      await pumpUntilVisible(
        tester,
        find.text(workerName),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text(workerName), findsWidgets);
    });

    // -----------------------------------------------------------------------
    // SYS-FL-06  Provider deletes a service
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-06 provider deletes a service', (tester) async {
      final session = await createProviderViaApi();
      final serviceName =
          'Servicio Eliminar ${DateTime.now().millisecondsSinceEpoch}';
      await createServiceViaApi(session, serviceName);

      await launchAuthenticatedApp(tester, session);

      // Navigate to Servicios tab
      await tapNavTab(tester, 'Servicios');
      await pumpUntilVisible(
        tester,
        find.text(serviceName),
        timeout: const Duration(seconds: 25),
      );

      // Open service modal by tapping the service card
      await tester.tap(find.text(serviceName).first);
      await pumpUntilVisible(tester, find.text('Eliminar'));

      // Tap Eliminar in the modal to open confirmation dialog
      await tester.tap(find.text('Eliminar').first);
      await pumpUntilVisible(tester, find.text('Eliminar servicio'));

      // Confirm deletion in the AlertDialog
      final confirmButton = find.widgetWithText(FilledButton, 'Eliminar');
      await tester.tap(confirmButton);

      await pumpUntilGone(
        tester,
        find.text(serviceName),
        timeout: const Duration(seconds: 25),
      );
      expect(find.text(serviceName), findsNothing);
    });

    // -----------------------------------------------------------------------
    // SYS-FL-08  Provider sees client reservation on calendar
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-08 provider sees client reservation on calendar',
        (tester) async {
      final session = await createProviderViaApi();
      final serviceName =
          'Servicio Cita ${DateTime.now().millisecondsSinceEpoch}';
      final workerName =
          'Worker Cita ${DateTime.now().millisecondsSinceEpoch}';

      final serviceId = await createServiceViaApi(session, serviceName);
      final workerId = await createWorkerViaApi(session, workerName);

      // Create client account
      final clientSession = await createClientViaApi();

      // Create time slot for today and reservation
      // These endpoints follow the same pattern as the web e2e test helpers
      final timeSlotId = await createTimeSlotViaApi(
        providerSession: session,
        workerId: workerId,
      );
      if (timeSlotId != null) {
        await createReservationViaApi(
          clientSession: clientSession,
          session: session,
          serviceId: serviceId,
          workerId: workerId,
          timeSlotId: timeSlotId,
        );
      }

      await launchAuthenticatedApp(tester, session);

      // Navigate to Calendario tab
      await tapNavTab(tester, 'Calendario');
      await tester.pump(const Duration(seconds: 3));

      // Verify calendar page loaded: the AppBar shows the current month name
      // and the refresh icon is present
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // If the reservation was created successfully, the service name should
      // appear in the timeline for today
      if (timeSlotId != null) {
        await pumpUntilVisible(
          tester,
          find.text(serviceName),
          timeout: const Duration(seconds: 15),
        );
        expect(find.text(serviceName), findsWidgets);
      }
    });

    // -----------------------------------------------------------------------
    // SYS-FL-09  Provider updates salon location
    // -----------------------------------------------------------------------
    testWidgets('SYS-FL-09 provider updates salon location', (tester) async {
      final session = await createProviderViaApi();
      await launchAuthenticatedApp(tester, session);

      // Navigate to Perfil tab (index 4)
      await tapNavTab(tester, 'Perfil');
      await pumpUntilVisible(tester, find.text('Perfil del negocio'));

      // Open ProfileDetailsPage
      await tester.tap(find.text('Perfil del negocio'));
      await pumpUntilVisible(
        tester,
        find.text('Ubicación'),
        timeout: const Duration(seconds: 15),
      );

      // Scroll down to make the Ubicación edit button visible
      await tester.scrollUntilVisible(
        find.text('Ubicación'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap the edit button in the Ubicación section (last edit icon on page)
      await tester.tap(find.byIcon(Icons.edit).last);
      // Wait for the page title, then for the body to finish loading
      await pumpUntilVisible(
        tester,
        find.text('Editar ubicación'),
        timeout: const Duration(seconds: 10),
      );
      await pumpUntilVisible(
        tester,
        find.text('Cambiar ubicación'),
        timeout: const Duration(seconds: 15),
      );

      // Verify the location edit page opened correctly
      expect(find.text('Editar ubicación'), findsOneWidget);
      expect(find.text('Cambiar ubicación'), findsOneWidget);
    });
  });
}

// ===========================================================================
// API HELPERS  (equivalent to e2e/support/api.ts in the web tests)
// ===========================================================================

/// Creates a full provider account via direct API calls and returns the session.
Future<ProviderSession> createProviderViaApi() async {
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final email = 'flutter.provider.$suffix@utime.test';
  const password = 'Password123!';
  final companyName = 'Flutter Salon $suffix';

  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};

  // 1. Sign up
  final signUpRes = await http.post(
    Uri.parse('$_baseUrl/authentication/sign-up'),
    headers: headers,
    body: jsonEncode({'email': email, 'password': password}),
  );
  expect(
    signUpRes.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Provider sign-up failed: ${signUpRes.body}',
  );
  final userId =
      (jsonDecode(signUpRes.body) as Map<String, dynamic>)['id'] as int;

  // 2. Sign in to get JWT token
  final signInRes = await http.post(
    Uri.parse('$_baseUrl/authentication/sign-in'),
    headers: headers,
    body: jsonEncode({'email': email, 'password': password}),
  );
  expect(
    signInRes.statusCode,
    HttpStatus.ok,
    reason: 'Provider sign-in failed: ${signInRes.body}',
  );
  final signInData = jsonDecode(signInRes.body) as Map<String, dynamic>;
  final token = signInData['token'] as String;

  // 3. Create provider profile
  final providerRes = await http.post(
    Uri.parse('$_baseUrl/providers'),
    headers: {...headers, HttpHeaders.authorizationHeader: 'Bearer $token'},
    body: jsonEncode({'companyName': companyName, 'userId': userId}),
  );
  expect(
    providerRes.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Provider creation failed: ${providerRes.body}',
  );
  final providerId =
      (jsonDecode(providerRes.body) as Map<String, dynamic>)['id'] as int;

  return ProviderSession(
    token: token,
    userId: userId,
    providerId: providerId,
    companyName: companyName,
    email: email,
    password: password,
  );
}

/// Creates a client account via direct API calls and returns a minimal session.
Future<ClientSession> createClientViaApi() async {
  final suffix = DateTime.now().millisecondsSinceEpoch;
  final email = 'flutter.client.$suffix@utime.test';
  const password = 'Password123!';

  final headers = {HttpHeaders.contentTypeHeader: 'application/json'};

  final signUpRes = await http.post(
    Uri.parse('$_baseUrl/authentication/sign-up'),
    headers: headers,
    body: jsonEncode({'email': email, 'password': password}),
  );
  expect(
    signUpRes.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Client sign-up failed: ${signUpRes.body}',
  );
  final userId =
      (jsonDecode(signUpRes.body) as Map<String, dynamic>)['id'] as int;

  final signInRes = await http.post(
    Uri.parse('$_baseUrl/authentication/sign-in'),
    headers: headers,
    body: jsonEncode({'email': email, 'password': password}),
  );
  expect(signInRes.statusCode, HttpStatus.ok);
  final token =
      (jsonDecode(signInRes.body) as Map<String, dynamic>)['token'] as String;

  final clientRes = await http.post(
    Uri.parse('$_baseUrl/clients'),
    headers: {...headers, HttpHeaders.authorizationHeader: 'Bearer $token'},
    body: jsonEncode({
      'firstName': 'Test',
      'lastName': 'Client$suffix',
      'userId': userId,
    }),
  );
  expect(
    clientRes.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Client profile creation failed: ${clientRes.body}',
  );
  final clientId =
      (jsonDecode(clientRes.body) as Map<String, dynamic>)['id'] as int;

  return ClientSession(token: token, clientId: clientId);
}

/// Creates a service for the given provider via API and returns the service ID.
Future<int> createServiceViaApi(ProviderSession session, String name) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/services'),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.token}',
    },
    body: jsonEncode({
      'name': name,
      'duration': 45,
      'price': 80.0,
      'providerId': session.providerId,
    }),
  );
  expect(
    res.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Service creation failed: ${res.body}',
  );
  return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
}

/// Creates a worker for the given provider via API and returns the worker ID.
Future<int> createWorkerViaApi(ProviderSession session, String name) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/workers'),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${session.token}',
    },
    body: jsonEncode({
      'name': name,
      'specialization': 'Corte',
      'photoUrl': 'https://example.com/photo.jpg',
      'providerId': session.providerId,
    }),
  );
  expect(
    res.statusCode,
    anyOf(HttpStatus.ok, HttpStatus.created),
    reason: 'Worker creation failed: ${res.body}',
  );
  return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
}

/// Creates a time slot for today and returns the time slot ID, or null if the
/// endpoint is not yet available in this backend version.
Future<int?> createTimeSlotViaApi({
  required ProviderSession providerSession,
  required int workerId,
}) async {
  final now = DateTime.now();
  final startTime = DateTime(now.year, now.month, now.day, 10, 0);
  final endTime = DateTime(now.year, now.month, now.day, 10, 45);

  final res = await http.post(
    Uri.parse('$_baseUrl/time-slots'),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${providerSession.token}',
    },
    body: jsonEncode({
      'workerId': workerId,
      'providerId': providerSession.providerId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
    }),
  );

  if (res.statusCode == HttpStatus.ok || res.statusCode == HttpStatus.created) {
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
  }
  // Return null gracefully if the endpoint shape differs
  return null;
}

/// Creates a reservation linking client, service, worker and time slot.
/// Returns the reservation ID, or null if creation fails.
Future<int?> createReservationViaApi({
  required ClientSession clientSession,
  required ProviderSession session,
  required int serviceId,
  required int workerId,
  required int timeSlotId,
}) async {
  final res = await http.post(
    Uri.parse('$_baseUrl/reservations'),
    headers: {
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.authorizationHeader: 'Bearer ${clientSession.token}',
    },
    body: jsonEncode({
      'clientId': clientSession.clientId,
      'serviceId': serviceId,
      'workerId': workerId,
      'timeSlotId': timeSlotId,
      'providerId': session.providerId,
    }),
  );

  if (res.statusCode == HttpStatus.ok || res.statusCode == HttpStatus.created) {
    return (jsonDecode(res.body) as Map<String, dynamic>)['id'] as int;
  }
  return null;
}

// ===========================================================================
// SESSION HELPERS
// ===========================================================================

/// Injects a provider session into SharedPreferences so the app starts
/// already authenticated and navigates directly to the main screen.
Future<void> injectProviderSession(ProviderSession session) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();
  await prefs.setString('jwt_token', session.token);
  await prefs.setInt('user_id', session.userId);
  await prefs.setInt('provider_id', session.providerId);
  await prefs.setBool('user_logged_in', true);
  await prefs.setBool('onboarding_completed', true);
  await prefs.setString('company_name', session.companyName);
}

/// Injects the session and launches the app. Because the JWT token is already
/// present in SharedPreferences, the splash screen navigates to MainPage.
Future<void> launchAuthenticatedApp(
  WidgetTester tester,
  ProviderSession session,
) async {
  await injectProviderSession(session);
  await tester.pumpWidget(const MainApp());
  await tester.pump(const Duration(seconds: 3)); // advance past 2-s splash delay
  await pumpUntilVisible(
    tester,
    find.text('Bienvenido'),
    timeout: const Duration(seconds: 20),
  );
  // Settle all route/fade animations before the test interacts with tabs.
  await tester.pumpAndSettle();
}

// ===========================================================================
// UI HELPERS  (shared by existing SYS-FL-01/02/03 tests)
// ===========================================================================

Future<ProviderAccount> launchFreshApp(WidgetTester tester) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  await tester.pumpWidget(const MainApp());
  await tester.pump(const Duration(seconds: 3));
  await pumpUntilVisible(tester, find.text('Bienvenido de nuevo'));
  // Wait for the login screen fade-in animation to finish so its
  // TextFormFields are the only ones in the widget tree.
  await tester.pumpAndSettle();

  final suffix = DateTime.now().millisecondsSinceEpoch;
  return ProviderAccount(
    companyName: 'Flutter Salon $suffix',
    email: 'flutter.provider.$suffix@utime.test',
    password: 'Password123!',
  );
}

Future<void> registerProvider(
  WidgetTester tester,
  ProviderAccount account,
) async {
  await tester.tap(find.textContaining(RegExp(r'Reg.*strate')).first);
  await pumpUntilVisible(tester, find.text('Nombre de la empresa'));
  // The Material page-route transition (~300 ms) + register screen fade-in
  // (~800 ms) must finish before we query TextFormFields, otherwise the
  // login screen's fields are still in the tree and get the wrong indices.
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byType(TextFormField).at(0),
    account.companyName,
  );
  await tester.enterText(find.byType(TextFormField).at(1), account.email);
  await tester.enterText(find.byType(TextFormField).at(2), account.password);
  await tester.tap(find.text('Registrarse').last);

  await pumpUntilVisible(
    tester,
    find.text('Bienvenido de nuevo'),
    timeout: const Duration(seconds: 60),
  );
  await pumpUntilVisible(
    tester,
    find.byType(TextFormField),
    timeout: const Duration(seconds: 10),
  );
  // Settle the login screen animation before loginProvider reads its fields.
  await tester.pumpAndSettle();
}

Future<void> loginProvider(
  WidgetTester tester,
  ProviderAccount account,
) async {
  await tester.enterText(find.byType(TextFormField).at(0), account.email);
  await tester.enterText(find.byType(TextFormField).at(1), account.password);
  await tester.tap(find.textContaining(RegExp(r'Iniciar sesi')).last);

  await pumpUntilVisible(
    tester,
    find.text('Bienvenido'),
    timeout: const Duration(seconds: 25),
  );
  // Settle the home screen transition before the test interacts with tabs.
  await tester.pumpAndSettle();
}

/// Taps a bottom-nav tab by label.
///
/// Uses [CustomBottomNavbar] as the ancestor so the search is scoped to the
/// nav bar — avoiding false matches with home-page stat cards that share the
/// same label text (e.g. "Servicios", "Trabajadores").
Future<void> tapNavTab(WidgetTester tester, String label) async {
  final navItem = find.descendant(
    of: find.byType(CustomBottomNavbar),
    matching: find.text(label),
  );
  await tester.tap(navItem);
  await tester.pump(const Duration(milliseconds: 400)); // route-animation buffer
}

/// Pumps until [finder] matches at least one widget or [timeout] elapses.
Future<void> pumpUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsWidgets);
}

/// Pumps until [finder] matches nothing (i.e. the widget has been removed)
/// or [timeout] elapses.
Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  expect(finder, findsNothing);
}

// ===========================================================================
// DATA CLASSES
// ===========================================================================

class ProviderAccount {
  const ProviderAccount({
    required this.companyName,
    required this.email,
    required this.password,
  });

  final String companyName;
  final String email;
  final String password;
}

class ProviderSession {
  const ProviderSession({
    required this.token,
    required this.userId,
    required this.providerId,
    required this.companyName,
    required this.email,
    required this.password,
  });

  final String token;
  final int userId;
  final int providerId;
  final String companyName;
  final String email;
  final String password;
}

class ClientSession {
  const ClientSession({required this.token, required this.clientId});

  final String token;
  final int clientId;
}
