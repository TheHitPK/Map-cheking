# Asistencia GPS — Control de llegada y salida en obra

## Objetivo MVP
El trabajador marca llegada y salida desde su teléfono; el backend verifica por GPS que esté dentro del radio de la obra
y clasifica la marca según su horario (a tiempo, tarde, salida anticipada). El supervisor ve la asistencia del día,
gestiona obras, personal y horarios (app Android y web).

## Restricciones
- Android gama baja, señal intermitente: la marca se guarda offline y se envía después.
- Obra = centro + radio (m). Sin polígonos. Sin Google Maps (mapa del supervisor: OSM vía `flutter_map`).
- La hora oficial la pone el servidor; la hora del dispositivo solo se usa para marcas diferidas (y se señala).
- Anti-fraude: rechazar ubicación simulada, precisión > 50 m (configurable) y fuera de radio. Se guardan también
  los intentos rechazados (auditoría).

## Stack
- Backend: Spring Boot 4, Java 21, virtual threads. Spring Security (resource server, JWT HS256 con Nimbus).
  JDBC (`JdbcClient`) + Flyway + PostgreSQL 16. Distancia con Haversine en el dominio.
- Apps: Flutter, un proyecto en `app/` con flavors Android `trabajador` / `supervisor`; el supervisor también compila
  para web (`-t lib/main_supervisor.dart`). Dependencias: `flutter_riverpod`, `http`, `geolocator`, `flutter_map` +
  `latlong2` (tiles OSM, solo supervisor), `shared_preferences` (cola offline y caché), `flutter_secure_storage` (token),
  `flutter_localizations` (SDK).
- Infra local: docker-compose (postgres, backend).

## Arquitectura
- Backend hexagonal por módulo (`employee`, `worksite`, `schedule`, `attendance`, `auth`):
  `domain` (Java puro, sin Spring) → `application` (casos de uso + puertos `out`) → `adapter/in/web`, `adapter/out/persistence`.
  Spring conecta los casos de uso en `config/ModulesConfig` (los adaptadores son `@Repository`/`@Component`). Reglas de marca = `MarkRule` (estrategia; una regla nueva no toca las otras).
- Flutter feature-first + MVVM: `features/<x>/{data,application,presentation}`; ViewModel = `Notifier` de riverpod.

## API (JSON)
- `POST /auth/login` → JWT (rol `WORKER` | `SUPERVISOR`).
- Trabajador: `GET /me/today`, `POST /me/marks` (idempotente por `clientId`).
- Supervisor: CRUD `/worksites`, `/employees`, `/schedules`; `GET /attendance/daily?date&worksiteId`;
  `GET /attendance/marks?from&to` (`.csv` con `Accept: text/csv`).

## Convenciones para Claude
- Respuestas breves; no expliques lo obvio.
- Ediciones puntuales; no reescribas archivos completos.
- No agregues dependencias fuera de este archivo sin preguntar.
- Antes de cada tarea: plan en ≤ 15 líneas y espera mi OK.
- Tests: JUnit 5 + Testcontainers (backend); tests unitarios en Dart para la cola offline y la geocerca.
- Código e identificadores en inglés; textos de la UI en español.
