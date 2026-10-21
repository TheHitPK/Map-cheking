# Asistencia GPS

Control de llegada y salida de trabajadores en obra. El trabajador marca desde su teléfono; el servidor verifica
por GPS que esté dentro del radio de la obra y clasifica la marca según su horario.

```
backend/   Spring Boot 4 (Java 21), arquitectura hexagonal, PostgreSQL
app/       Flutter: flavors trabajador / supervisor (el supervisor también en web)
docker-compose.yml   postgres + backend
```

## Arranque local

```sh
cp .env.example .env            # defina BOOTSTRAP_ADMIN_PASSWORD (primer supervisor)
docker compose up -d --build    # API en http://localhost:8080
```

Sin Docker para el backend: `docker compose up -d postgres` y `cd backend && ./mvnw spring-boot:run`
(con `BOOTSTRAP_ADMIN_PASSWORD` en el entorno).

Apps:

```sh
cd app
flutter run --flavor trabajador -t lib/main_trabajador.dart          # Android
flutter run --flavor supervisor -t lib/main_supervisor.dart          # Android
flutter run -d chrome -t lib/main_supervisor.dart                    # Web
# Otro servidor: --dart-define=API_URL=https://api.example.com
```

## Flujo

1. El supervisor entra con `admin` / `BOOTSTRAP_ADMIN_PASSWORD`, crea la obra (centro en el mapa + radio) y los
   trabajadores, y asigna a cada uno obra, horario, días y tolerancia.
2. El trabajador abre la app, ve si está dentro de la obra y toca **Marcar llegada** / **Marcar salida**.
3. El servidor acepta la marca o la rechaza (fuera de la obra, GPS impreciso o simulado, secuencia inválida…).
   Los rechazos también se guardan para auditoría.
4. El supervisor ve en **Hoy** quién llegó, tarde, ausente o en obra, y en **Reportes** exporta CSV.

## Reglas

| Regla | Valor por defecto (`application.yml`) |
|---|---|
| Dentro de la obra | distancia al centro ≤ radio (20–2000 m) |
| Precisión GPS máxima | 50 m |
| Ubicación simulada | rechazada (`isMocked` de Android) |
| Hora oficial | la del servidor; si la marca llega > 2 min después de tomarse (sin señal), se usa la del teléfono y se marca como «sin conexión» |
| Reloj del teléfono adelantado | > 2 min → rechazada |
| Marca offline más vieja de | 24 h → rechazada |
| Tarde | llegada > entrada + tolerancia |
| Salida anticipada | salida < salida − tolerancia |

## Tests

```sh
cd backend && ./mvnw verify      # JUnit 5 + Testcontainers (requiere Docker)
cd app && flutter test
```

## Producción

- `JWT_SECRET` aleatorio (≥ 32 bytes), HTTPS delante del backend, `CORS_ORIGINS` con el dominio del panel web.
- Mapa del supervisor: usa los tiles públicos de OpenStreetMap, que no permiten uso intensivo. Para producción,
  configure un proveedor propio (MapTiler, Stadia, servidor propio) en `worksite_editor_page.dart`.
