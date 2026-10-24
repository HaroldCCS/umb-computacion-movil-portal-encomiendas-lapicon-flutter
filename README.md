# Lapticon — app Flutter

Cliente móvil del proyecto Lapticon (Computación Móvil, 2.º corte). Consume el backend
`https://lapticon-backend.onrender.com` con el idToken de Firebase.

**[⬇️ Descargar el APK (última versión)](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon-flutter/releases/latest/download/lapticon.apk)** — se compila solo con cada
push a `main` (`.github/workflows/compilar-apps.yml`).

Documentación (contrato de la API, arquitectura, sistema de diseño, bitácora) en el
[repositorio de documentación](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon); las referencias `docs/0X` del código apuntan allá. La versión web (PWA) está en
[su propio repositorio](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon-pwa).

**Organización local:** este repositorio se clona dentro de la carpeta del repo de documentación, como `lapticon_app/`
(el de documentación lo ignora). Así `setup.sh` encuentra `../referencias/google-services.json`; si lo tienes en otra
parte: `GOOGLE_SERVICES=/ruta/google-services.json bash setup.sh`.

**Estado:** prácticas 1 a 6 implementadas (pendiente probar en dispositivo y confirmar el contrato real de la API).

## Requisitos

- Flutter estable **3.32 o superior** (probado contra el código fuente de Flutter 3.47 / Dart 3.13).
- Android Studio con un emulador Android, o un teléfono Android en modo depuración.
- El `google-services.json` del curso (en `../referencias/` del repo de documentación; no se sube).

## Puesta en marcha (una sola vez)

```bash
cd lapticon_app
bash setup.sh
flutter run
```

`setup.sh` hace lo siguiente:
1. `flutter create` solo para generar `android/` (no toca `lib/` ni `test/`).
2. Ajusta Android: `applicationId = com.lapticon.app` (debe coincidir con el `google-services.json`),
   `minSdk ≥ 23` (lo exige Firebase), permiso de Internet y nombre "Lapticon".
3. Instala las dependencias con `flutter pub add` (quedan en la última versión compatible con tu Flutter).
4. Genera `lib/firebase_options.dart` desde el `google-services.json` con `tool/generate_firebase_options.dart`.
5. Corre `flutter analyze` y `flutter test`.

Para apuntar a otro backend: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000`.

## Qué hace hoy

| Flujo | Detalle |
|---|---|
| Crear cuenta | Correo + contraseña (Firebase Auth), indicador de seguridad, confirmación |
| Iniciar sesión / recuperar contraseña | Errores de Firebase traducidos; la recuperación no revela si el correo existe |
| Completar perfil (paso 1 de 2) | `POST /api/users/register` con nombre, apellido, teléfono y nacionalidad (buscador sobre `/api/ciudades/paises`) |
| Elegir rol (paso 2 de 2) | Remitente o viajero; intenta guardarlo en el backend y siempre lo cachea en el teléfono (reto 1) |
| Inicio por rol | Barra flotante con botón "+" (nueva encomienda / registrar viaje); contadores de lo pendiente; avisos que llevan directo a calificar o entregar |
| Perfil | `GET /api/users/:uid` (primera llamada protegida), calificaciones (`GET /api/ratings/:uid`), editar (`PUT`), cambiar de rol, cerrar sesión |
| Servidor dormido | Aviso "Despertando el servidor…" si una petición tarda más de 5 s |
| Remitente (P3) | Inicio con resumen, mis envíos por estado, nueva encomienda, detalle con línea de tiempo, retirar (escribiendo RETIRAR), buscar viajeros |
| Viajero (P4) | Mi viaje, registrar viaje con verificación de vuelo (o "sin verificar"), explorar encomiendas de la ruta, tomar, marcar entregada (escribiendo ENTREGAR) |
| Chat (P5) | Mensajes en tiempo real en Firestore (`chats/{uid1_uid2}/mensajes`), lista de chats, envío bloqueado si el chat está cerrado |
| Calificaciones (P6) | Calificar con estrellas y comentario, reseñas recibidas desde el perfil |
| Asistente IA | Chat con `POST /api/chatbot`, sugerencias según el rol |

## Arquitectura

```text
lib/
├── main.dart / app.dart          Firebase, Riverpod, MaterialApp.router, tema
├── providers.dart                Inyección de dependencias (Riverpod)
├── core/
│   ├── config/env.dart           URL base y tiempos de espera
│   ├── network/                  ApiClient (Bearer, reintento 401, errores) y excepciones
│   ├── router/app_router.dart    go_router + redirección según la sesión
│   ├── theme/                    tema.dart (tokens Colores, Medidas, Movimiento, construirTema) y vocabulario por rol
│   ├── utils/validators.dart     Validaciones puras de formularios
│   └── widgets/                  Sistema v2: Pantalla, BarraPestanas, TarjetaHero, RouteTicket, Boton, Campo, Grupo, Aviso, hojas, toasts…
├── data/
│   ├── models/                   Usuario, Rol, ResumenCalificaciones (fromJson tolerante)
│   ├── local/prefs.dart          Caché local (rol, países/ciudades)
│   ├── services/auth_service.dart
│   └── repositories/             Usuario, Catálogo (países/ciudades), Calificaciones
└── features/                     session, splash, auth, onboarding, home, perfil
```

Reglas: las pantallas no llaman a `http` ni a Firebase directamente, solo a repositorios y a
`SessionController`. El router decide la pantalla según `SessionStatus`
(sin sesión → login, sin perfil → completar perfil, sin rol → elegir rol, listo → inicio).

## Pruebas

```bash
flutter test
```

- `validators_test.dart`, `models_test.dart`: lógica pura.
- `api_client_test.dart`: Bearer, rutas públicas, reintento ante 401, mensajes de error (con `MockClient`).
- `router_redirect_test.dart`: reglas de navegación.
- `theme/tema_test.dart`: contraste AA de cada par de colores (claro y oscuro) y del texto sobre los degradados.
- `widgets/`: cada componente del sistema v2 (contraste, 48 dp, lector de pantalla, "reducir movimiento").
- `accesibilidad_test.dart`: barrido de las pantallas principales en claro/oscuro y con letra al doble en 360 dp.
- Por funcionalidad (`auth/`, `home/`, `remitente/`, `viajero/`, `perfil/`, `chat/`, …): flujos con repositorios
  falsos, sin Firebase ni red.

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `No Firebase App '[DEFAULT]'` o `DefaultFirebaseOptions` no existe | Vuelve a correr `dart run tool/generate_firebase_options.dart ../referencias/google-services.json` |
| `minSdkVersion 21 cannot be smaller than 23` | En `android/app/build.gradle.kts` pon `minSdk = 23` |
| Gradle pide otra versión de NDK | Copia la versión que indica el error en `ndkVersion = "…"` de `android/app/build.gradle.kts` |
| `CONFIGURATION_NOT_FOUND` / error de API key al iniciar sesión | El `applicationId` no coincide: debe ser `com.lapticon.app` |
| La primera carga tarda mucho | Normal: el backend gratuito de Render "despierta" en 30–60 s |

Diseño: sistema v2 en [docs/07](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon/blob/main/docs/07-diseno-ux-ui.md) (por qué y cómo se rediseñó: [docs/08](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon/blob/main/docs/08-plan-rediseno-ui.md)).
Planeación y contrato de la API: [docs/](https://github.com/HaroldCCS/umb-computacion-movil-portal-encomiendas-lapicon/tree/main/docs).
