# Despliegue: Render (gratis)

```
App PinPunch (empleado o supervisor) ──HTTPS──▶ Render: asistencia-api (Docker, free) ──▶ Render Postgres 16 (free)
```

## 1. Crear los servicios

1. Render → **New** → **Blueprint** → elige el repositorio `Map-cheking` (rama `develop`).
   Render lee `render.yaml` y crea `asistencia-api` (backend) y `asistencia-db` (PostgreSQL).
2. Te pedirá `BOOTSTRAP_ADMIN_PASSWORD`: la clave del primer supervisor (usuario `admin`). Guárdala.
   `JWT_SECRET` y la base de datos se configuran solos.
3. **Apply**. El primer build tarda 5–10 min.
4. Abre `https://asistencia-api.onrender.com/actuator/health` → `{"status":"UP"}`.
   Si Render te asignó otra URL (nombre ocupado), úsala en el paso 3.

## 2. Despertar

El servicio gratis se duerme tras 15 min sin tráfico; la primera petición tarda 30–60 s.
La app espera hasta 60 s, y si aun así no responde, la marca queda guardada en el teléfono y se envía sola.
Para evitar la espera: [UptimeRobot](https://uptimerobot.com) → monitor HTTP a `/actuator/health` cada 5 min.
(Render da 750 h gratis al mes: un solo servicio despierto todo el mes cabe; no crees otro gratuito en la misma cuenta.)

## 3. APK

```sh
cd app
flutter build apk --release --split-per-abi --dart-define=API_URL=https://asistencia-api.onrender.com
```

Salida en `app/build/app/outputs/flutter-apk/`: `app-arm64-v8a-release.apk` (casi todos los teléfonos)
y `app-armeabi-v7a-…` (teléfonos viejos de 32 bits).

Un solo APK para todos: el rol con que se inicia sesión decide la pantalla (empleado o supervisor).

Panel web del supervisor apuntando a Render: `flutter run -d chrome --dart-define=API_URL=https://asistencia-api.onrender.com`.
Para publicarlo en un dominio, agrega ese origen a `CORS_ORIGINS` en Render (p. ej. `https://panel.midominio.com`).

## Limitaciones del plan gratuito

- **Postgres gratis caduca a los 30 días** y luego se borra. Para uso real: plan pago desde el panel de Render,
  o una base externa (Neon, Supabase) poniendo sus datos en `POSTGRES_*`.
- **APK firmados con la clave de depuración**: sirven para instalar y probar, no para Play Store.
  Para publicar, crea un keystore de release y configúralo en `app/android/app/build.gradle.kts`.
