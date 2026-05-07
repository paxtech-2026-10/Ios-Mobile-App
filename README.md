# uTime — Aplicación Móvil para Proveedores (Flutter)

Aplicación móvil nativa construida con **Flutter** para el segmento de proveedores (salones de belleza) de la plataforma uTime. Permite a los proveedores gestionar servicios, equipo, reservas del calendario y su perfil de negocio.

Backend: `https://paxtech.azurewebsites.net/api/v1`

---

## Estructura de navegación

La app usa un `IndexedStack` con 5 pestañas gestionadas por `CustomBottomNavbar`:

| Índice | Pestaña | Página principal |
|--------|---------|-----------------|
| 0 | Inicio | `HomePage` |
| 1 | Servicios | `ServicePage` |
| 2 | Trabajadores | `TeamPage` |
| 3 | Calendario | `CalendarPage` |
| 4 | Perfil | `ProfileOverviewPage` |

---

## Pruebas de sistema (Core System Tests)

Las pruebas están en `integration_test/provider_core_system_test.dart` y validan los flujos completos de proveedor contra el backend real en Azure.

### Casos de prueba

| Test ID | Descripción |
|---------|-------------|
| SYS-FL-01 | El proveedor se registra y luego inicia sesión |
| SYS-FL-02 | El proveedor crea un servicio |
| SYS-FL-03 | El proveedor crea un trabajador |
| SYS-FL-06 | El proveedor elimina un servicio |
| SYS-FL-08 | El proveedor visualiza una reserva de cliente en el calendario |
| SYS-FL-09 | El proveedor navega al editor de ubicación del salón |

### Cómo ejecutar las pruebas

```bash
flutter test integration_test/provider_core_system_test.dart --device-id windows
```

> Los tests corren sobre el target **Windows Desktop** — no requieren emulador Android/iOS. Las llamadas HTTP al backend de Azure funcionan igual desde el runner de Windows.

Para ver el log detallado de un solo test:

```bash
flutter test integration_test/provider_core_system_test.dart --device-id windows --name "SYS-FL-02"
```

Para ver los dispositivos disponibles:

```bash
flutter devices
```

### Patrón de los tests

Los tests que no necesitan validar el flujo de UI de registro/login **inyectan la sesión directamente en `SharedPreferences`** mediante `createProviderViaApi()` + `injectProviderSession()`, lo que reduce el tiempo de cada prueba de ~20 s a ~5 s:

```
SYS-FL-01/02/03  →  flujo completo de UI (registro → login → acción)
SYS-FL-06/08/09  →  API setup + inyección de sesión → acción directa
```

### Decisiones técnicas

**`IndexedStack` y el problema de Hero duplicado**

`MainPage` usa `IndexedStack`, lo que significa que **todas las pestañas se renderizan simultáneamente** aunque solo una sea visible. Esto causa dos problemas que fueron resueltos:

1. **Colisión de textos de navegación:** el home muestra tarjetas `_StatCard` con labels "Servicios" y "Trabajadores" que coinciden con el texto de los ítems de navegación. La solución es buscar los ítems de navegación dentro de `CustomBottomNavbar` usando `find.descendant`.

2. **Error de Hero duplicado:** los `FloatingActionButton` de las páginas de Servicios, Trabajadores y Descuentos compartían el `heroTag` por defecto (`'Fab Hero'`). Al navegar desde cualquiera de ellos, Flutter detectaba múltiples Heroes con el mismo tag en el árbol y lanzaba una excepción. La solución fue agregar `heroTag: null` a los tres FABs.

**`pumpAndSettle` vs `pump` discretos**

Las páginas de servicios y trabajadores muestran un `CircularProgressIndicator` mientras cargan datos. `pumpAndSettle` espera a que **todas** las animaciones terminen antes de continuar; un indicador de carga continuo haría que colgara indefinidamente. Por eso se usa `pumpUntilVisible` (que llama a `pump(250 ms)` en un loop) en lugar de `pumpAndSettle` en esos contextos.

---

## Prerrequisitos

- Flutter SDK ≥ 3.x
- Dart SDK ≥ 3.x
- Para tests: conexión a internet (los tests llaman al backend real en Azure)
