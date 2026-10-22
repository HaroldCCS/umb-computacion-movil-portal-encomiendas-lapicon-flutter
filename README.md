# Lapticon — app Flutter

Cliente móvil del proyecto Lapticon (Computación Móvil, 2.º corte). Consume el backend
`https://lapticon-backend.onrender.com` con el idToken de Firebase.

**Estado:** prácticas 1 a 6 implementadas (pendiente probar en dispositivo y confirmar el contrato real de la API).

## Requisitos

- Flutter estable **3.32 o superior** (probado contra el código fuente de Flutter 3.47 / Dart 3.13).
- Android Studio con un emulador Android, o un teléfono Android en modo depuración.
- La carpeta `../referencias/` con el `google-services.json` del curso.

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

## Qué hace hoy (Práctica 1)

| Flujo | Detalle |
|---|---|
| Crear cuenta | Correo + contraseña (Firebase Auth), indicador de seguridad, confirmación |
| Iniciar sesión / recuperar contraseña | Errores de Firebase traducidos; la recuperación no revela si el correo existe |
| Completar perfil (paso 1 de 2) | `POST /api/users/register` con nombre, apellido, teléfono y nacionalidad (buscador sobre `/api/ciudades/paises`) |
| Elegir rol (paso 2 de 2) | Remitente o viajero; intenta guardarlo en el backend y siempre lo cachea en el teléfono (reto 1) |
| Inicio por rol | Barra inferior propia de cada rol; las pestañas de las prácticas 3–5 muestran su estado vacío |
| Perfil | `GET /api/users/:uid` (primera llamada protegida), calificaciones (`GET /api/ratings/:uid`), editar (`PUT`), cambiar de rol, cerrar sesión |
| Servidor dormido | Aviso "Despertando el servidor…" si una petición tarda más de 5 s |
| Remitente (P3) | Mis envíos por estado, nueva encomienda, detalle con línea de tiempo, cancelar, buscar viajeros |
| Viajero (P4) | Mi viaje, registrar viaje con verificación de vuelo, explorar encomiendas de la ruta, tomar, marcar entregada |
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
│   ├── theme/                    Tokens del sistema de diseño y tema Material 3
│   ├── utils/validators.dart     Validaciones puras de formularios
│   └── widgets/                  AppTextField, PrimaryButton, RouteTicket, estados vacío/error…
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
- `widget_test.dart`: validación al salir del campo, botón con carga, accesibilidad (contraste y área táctil en tema claro y oscuro).

## Problemas comunes

| Síntoma | Solución |
|---|---|
| `No Firebase App '[DEFAULT]'` o `DefaultFirebaseOptions` no existe | Vuelve a correr `dart run tool/generate_firebase_options.dart ../referencias/google-services.json` |
| `minSdkVersion 21 cannot be smaller than 23` | En `android/app/build.gradle.kts` pon `minSdk = 23` |
| Gradle pide otra versión de NDK | Copia la versión que indica el error en `ndkVersion = "…"` de `android/app/build.gradle.kts` |
| `CONFIGURATION_NOT_FOUND` / error de API key al iniciar sesión | El `applicationId` no coincide: debe ser `com.lapticon.app` |
| La primera carga tarda mucho | Normal: el backend gratuito de Render "despierta" en 30–60 s |

Diseño: ver `../docs/07-diseno-ux-ui.md`. Planeación y contrato de la API: `../docs/`.
