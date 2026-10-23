# PinPunch — Reloj de asistencia GPS para obras (mercado EE. UU.)

Marca: **PinPunch** · "Punch in where the work is." Una sola app *PinPunch* (Android + web): el rol del login decide la pantalla.
Paleta en `app/lib/core/brand/brand.dart` (Survey Navy `#0B2545`, Hi-Vis Orange `#FF6B1A`, Route Blue `#8DA9C4`,
Concrete `#F5F3EE`). Logos SVG en `brand/`. Íconos y splash se generan con `flutter test tool/generate_icons_test.dart`.
El paquete Java / Dart sigue llamándose `asistencia` (interno).

## Objetivo MVP
El trabajador marca llegada y salida desde su teléfono; el backend verifica por GPS que esté dentro del radio de la obra
y clasifica la marca según su horario (a tiempo, tarde, salida anticipada). El supervisor ve la asistencia del día,
gestiona obras, personal, horarios y nómina (app Android y web).
Nómina: semana lunes–domingo, pago por defecto el viernes siguiente; horas = pares IN/OUT aceptados (minutos de reloj),
extras 1.5× sobre 40 h/semana; tarifa por hora en centavos (`employee.hourly_rate_cents`). Al marcar pagada se congela
(`pay_period`, `payroll_line`). Montos brutos, sin impuestos. Sesión sin salida = no se paga hasta corregirla.

## Restricciones
- Android gama baja, señal intermitente: la marca se guarda offline y se envía después.
- Obra = centro + radio (m). Sin polígonos. Sin Google Maps (mapa del supervisor: OSM vía `flutter_map`).
- Zona horaria: una global (`APP_TIMEZONE`, por defecto America/New_York). Pendiente: zona por obra.
- La hora oficial la pone el servidor; la hora del dispositivo solo se usa para marcas diferidas (y se señala).
- Aviso de ubicación (Google Play + leyes estatales) antes de pedir permiso: `LocationDisclosureGate`.
- Anti-fraude: rechazar ubicación simulada, precisión > 50 m (configurable) y fuera de radio. Se guardan también
  los intentos rechazados (auditoría).

## Stack
- Backend: Spring Boot 4, Java 21, virtual threads. Spring Security (resource server, JWT HS256 con Nimbus).
  JDBC (`JdbcClient`) + Flyway + PostgreSQL 16. Distancia con Haversine en el dominio.
- App: Flutter, un proyecto en `app/` y un solo APK (`lib/main.dart`); `WORKER` → marcar + My pay, `SUPERVISOR` →
  panel. Web solo para supervisores. Dependencias: `flutter_riverpod`, `http`, `geolocator`, `flutter_map` +
  `latlong2` (tiles OSM, solo supervisor), `shared_preferences` (cola offline y caché), `flutter_secure_storage` (token),
  `flutter_localizations` (SDK, locale en-US).
- Infra local: docker-compose (postgres, backend).

## Arquitectura
- Backend hexagonal por módulo (`employee`, `worksite`, `schedule`, `attendance`, `payroll`, `auth`):
  `domain` (Java puro, sin Spring) → `application` (casos de uso + puertos `out`) → `adapter/in/web`, `adapter/out/persistence`.
  Spring conecta los casos de uso en `config/ModulesConfig` (los adaptadores son `@Repository`/`@Component`). Reglas de marca = `MarkRule` (estrategia; una regla nueva no toca las otras).
- Flutter feature-first + MVVM: `features/<x>/{data,application,presentation}`; ViewModel = `Notifier` de riverpod.

## API (JSON)
- `POST /auth/login` → JWT (rol `WORKER` | `SUPERVISOR`).
- Trabajador: `GET /me/today`, `POST /me/marks` (idempotente por `clientId`).
- Supervisor: CRUD `/worksites`, `/employees`, `/schedules`; `GET /attendance/daily?date&worksiteId`;
  `GET /attendance/marks?from&to` (`.csv` con `Accept: text/csv`).
- Nómina: `GET /payroll?date` (semana que contiene la fecha), `POST /payroll/{lunes}/pay` `{paidOn}`; empleado: `GET /me/pay`.

## Convenciones para Claude
- Respuestas breves; no expliques lo obvio.
- Ediciones puntuales; no reescribas archivos completos.
- No agregues dependencias fuera de este archivo sin preguntar.
- Antes de cada tarea: plan en ≤ 15 líneas y espera mi OK.
- Tests: JUnit 5 + Testcontainers (backend); tests unitarios en Dart para la cola offline y la geocerca.
- Código e identificadores en inglés. UI y mensajes de la API en inglés de EE. UU.; todos los textos de la app en
  `app/lib/core/strings.dart`. Formato US (12 h, "Mon, Oct 19"); distancias en pies/millas en pantalla, metros en
  datos y API (`Fmt`).
- Movimiento: respetar `MediaQuery.disableAnimations`; nunca comunicar estado solo con color (icono + texto).
