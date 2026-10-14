# Despliegue: Render (gratis) + EMQX Serverless (gratis)

```
Apps ──HTTPS──▶ Render: transmcbo-api (Docker, free) ──▶ Render Postgres + PostGIS (free)
  │                       │                          └─▶ Render Key Value (free, interno)
  └──MQTT/TLS 8883──▶ EMQX Serverless (free) ◀──MQTT/TLS──┘
```

Las apps solo conocen la URL del API. El broker MQTT (host, puerto, usuario y contraseña) se lo entrega el backend en `/auth/*`.

## 0. Antes de empezar

- Cuenta en [GitHub](https://github.com), [Render](https://render.com) y [EMQX Cloud](https://www.emqx.com/en/cloud).
- Genera 3 contraseñas largas (una por rol) y guárdalas en tu gestor de contraseñas:
  ```sh
  openssl rand -base64 24   # repetir 3 veces: backend, chofer, pasajero
  ```

## 1. Subir el código a GitHub

Render despliega desde un repositorio. Puede ser privado.

```sh
# Crea un repositorio vacío "transmcbo" en GitHub (sin README) y luego:
git remote add origin https://github.com/<tu-usuario>/transmcbo.git
git push -u origin master
```

## 2. Broker: EMQX Serverless

1. EMQX Cloud → **New Deployment** → **Serverless**.
   - Región: **AWS us-east-1** (la más cercana a Render Virginia).
   - **Spending limit: 0** (así nunca cobra; si se agota la cuota gratis, se detiene).
2. En el deployment → **Access Control** → **Authentication** → agrega 3 usuarios:

   | Usuario    | Contraseña             |
   |------------|------------------------|
   | `backend`  | (contraseña backend)   |
   | `chofer`   | (contraseña chofer)    |
   | `pasajero` | (contraseña pasajero)  |

3. **Access Control** → **Authorization** → reglas por usuario (en este orden):

   | Usuario    | Acción    | Topic   | Permiso |
   |------------|-----------|---------|---------|
   | `backend`  | Subscribe | `v/#`   | Allow   |
   | `chofer`   | Publish   | `v/#`   | Allow   |
   | `pasajero` | Subscribe | `v/+/+` | Allow   |
   | (todos)    | Pub & Sub | `#`     | Deny    |

   La última regla deniega todo lo demás. `v/+/+` no incluye `v/…/…/b`, así que el pasajero no recibe los lotes del historial.
4. En **Overview**, copia la **dirección** (algo como `xxxxxxxx.ala.us-east-1.emqxsl.com`). Se usa el puerto **8883** (MQTT sobre TLS).

> Límites gratis: 1 millón de minutos de sesión al mes (≈ 23 conexiones abiertas todo el mes) y 1 GB de tráfico.
> Se pausa si nadie se conecta en 5 días. Sin JWT: los permisos son por rol, no por unidad (ver «Limitaciones»).

## 3. Backend: Render Blueprint

1. Render → **New** → **Blueprint** → elige el repositorio. Render lee `render.yaml` y crea:
   - `transmcbo-api`: web service Docker (free, Virginia);
   - `transmcbo-db`: Postgres 16 con PostGIS (free);
   - `transmcbo-kv`: Key Value (free, solo accesible desde Render).
2. Te pedirá las variables marcadas `sync: false`:

   | Variable                  | Valor                                  |
   |---------------------------|----------------------------------------|
   | `MQTT_HOST`               | la dirección de EMQX del paso 2.4      |
   | `MQTT_BACKEND_PASSWORD`   | contraseña de `backend`                |
   | `MQTT_DRIVER_PASSWORD`    | contraseña de `chofer`                 |
   | `MQTT_PASSENGER_PASSWORD` | contraseña de `pasajero`               |

   La base de datos, Redis y `MQTT_JWT_SECRET` se configuran solos.
3. **Apply**. El primer build tarda unos 5–10 min: compila con Maven y precompila el grafo de GraphHopper dentro de la imagen.
4. Cuando termine, abre `https://transmcbo-api.onrender.com/actuator/health`. Debe responder `{"status":"UP"}`.
   - El arranque con 0,1 CPU tarda **unos 5 min** (medido en local con los mismos límites). Mientras tanto Render muestra «Deploying».
   - Si el nombre `transmcbo-api` ya existe en Render, tendrás otra URL: recompila los APK con esa URL (paso 6).

## 4. Mantenerlo despierto

Render apaga el servicio gratuito tras 15 min sin tráfico entrante. La conexión MQTT del backend es saliente y **no** cuenta: dormido, deja de recibir posiciones. Además, cada arranque tarda ~5 min.

- En [UptimeRobot](https://uptimerobot.com) (gratis): **New monitor** → HTTP(s) → `https://transmcbo-api.onrender.com/actuator/health` → cada **5 minutos**.
- Render da 750 h gratis al mes por cuenta. Un solo servicio encendido todo el mes usa ~744 h, así que **no crees otro servicio gratuito** en la misma cuenta.

## 5. Dar de alta unidades (choferes)

```sh
bash tools/new-vehicle.sh 12 4821     # unidad 12, PIN 4821 → imprime un INSERT
```

Render → `transmcbo-db` → **Connect** → copia el comando **PSQL** (External), conéctate y pega el `INSERT`.
Las líneas iniciales vienen de la migración `V3__line.sql`; para agregar más:

```sql
INSERT INTO line (id, name) VALUES ('mi-linea', 'Mi Línea');
```

Los teléfonos ven las líneas nuevas en hasta 5 minutos (caché del backend).

## 6. APK

Ya compilados en `release/` (firmados con el keystore de release):

| Archivo                               | Para                                        |
|---------------------------------------|---------------------------------------------|
| `transmcbo-pasajero-arm64-v8a.apk`    | pasajeros, casi todos los teléfonos de 2017+ |
| `transmcbo-pasajero-armeabi-v7a.apk`  | pasajeros, teléfonos viejos de 32 bits      |
| `transmcbo-chofer-arm64-v8a.apk`      | choferes                                    |
| `transmcbo-chofer-armeabi-v7a.apk`    | choferes, teléfonos viejos de 32 bits       |

Si no sabes qué tiene el teléfono, prueba primero `arm64-v8a`; si no instala, usa `armeabi-v7a`.

Para recompilarlos (por ejemplo, si tu URL de Render es otra):

```sh
cd app
flutter build apk --release --split-per-abi --flavor pasajero -t lib/main_pasajero.dart --dart-define=API_URL=https://<tu-servicio>.onrender.com
flutter build apk --release --split-per-abi --flavor chofer   -t lib/main_chofer.dart   --dart-define=API_URL=https://<tu-servicio>.onrender.com
```

**Respaldar el keystore:** `app/android/upload-keystore.jks` y `app/android/key.properties` (contiene la contraseña). No están en git. Sin ellos no podrás publicar actualizaciones con la misma firma: los usuarios tendrían que desinstalar e instalar de nuevo.

## Limitaciones del plan gratuito

- **Postgres de Render caduca a los 30 días** (y se borra 14 días después). Antes de eso, pásalo a un plan pago desde el panel o recrea la base y vuelve a cargar unidades y líneas. El historial de trazas se pierde si se recrea.
- **Key Value no persiste:** al reiniciarse se vacían las posiciones vivas. Se vuelven a llenar con el siguiente mensaje de cada chofer (≤ 15 s).
- **Sin permisos por unidad en MQTT:** EMQX Serverless no admite JWT, así que todos los choferes comparten el usuario `chofer`. Un chofer con esa contraseña podría publicar como otra unidad. El backend sigue descartando posiciones imposibles. En local (`docker compose`) sí hay JWT con permisos por unidad.
- **Arranque lento** (~5 min) si el servicio se duerme: por eso el monitor del paso 4.
