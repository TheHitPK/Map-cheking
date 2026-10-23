# PinPunch

GPS time clock for construction crews (US). El trabajador marca desde su teléfono; el servidor verifica
por GPS que esté dentro del radio de la obra y clasifica la marca según su horario.

```
backend/   Spring Boot 4 (Java 21), arquitectura hexagonal, PostgreSQL
app/       Flutter: una app; el rol al iniciar sesión decide (empleado: marcar + mi pago; supervisor: panel, también web)
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
flutter run                 # Android (empleado o supervisor según quién inicia sesión)
flutter run -d chrome       # Web (solo supervisores)
# Otro servidor: --dart-define=API_URL=https://api.example.com
```

## Flujo

1. El supervisor entra con `admin` / `BOOTSTRAP_ADMIN_PASSWORD`, crea la obra (centro en el mapa + radio) y los
   trabajadores, y asigna a cada uno obra, horario, días y tolerancia.
2. El trabajador abre la app, ve si está dentro de la obra y toca **Marcar llegada** / **Marcar salida**.
3. El servidor acepta la marca o la rechaza (fuera de la obra, GPS impreciso o simulado, secuencia inválida…).
   Los rechazos también se guardan para auditoría.
. **Nómina** semanal (lunes a domingo): horas de cada empleado por pares entrada/salida aceptados, extras a 1.5× sobre
   40 h, por su tarifa por hora. El supervisor revisa la semana en **Payroll** y la marca como pagada (los montos quedan
   congelados); el empleado ve en **My pay** su próximo cheque, cuándo llega (viernes siguiente) y su historial.
   Montos brutos, sin impuestos.

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
