#!/usr/bin/env bash
# Prepara el proyecto Flutter de Lapticon (macOS / Linux).
# Uso:  cd lapticon_app && bash setup.sh
set -euo pipefail
cd "$(dirname "$0")"

# Por defecto, el del repo de documentación (este repo se clona dentro de esa carpeta).
GOOGLE_SERVICES="${GOOGLE_SERVICES:-../referencias/google-services.json}"
APP_ID="com.lapticon.app"   # debe coincidir con un cliente del google-services.json

echo "==> Verificando Flutter"
command -v flutter >/dev/null || { echo "ERROR: instala Flutter y agrégalo al PATH (https://docs.flutter.dev/get-started/install)"; exit 1; }
flutter --version

echo "==> Generando carpetas de plataforma (android/) sin tocar lib/ ni test/"
if [ ! -d android ]; then
  flutter create . --org com.lapticon --project-name lapticon_app --platforms android
fi

echo "==> Ajustando Android (applicationId, minSdk, permiso de Internet)"
for f in android/app/build.gradle.kts android/app/build.gradle; do
  [ -f "$f" ] || continue
  perl -pi -e "s/applicationId\s*=\s*\"[^\"]*\"/applicationId = \"$APP_ID\"/; s/applicationId\s+\"[^\"]*\"/applicationId \"$APP_ID\"/" "$f"
  if [[ "$f" == *.kts ]]; then
    perl -pi -e 's/minSdk\s*=\s*flutter\.minSdkVersion/minSdk = maxOf(flutter.minSdkVersion, 23)/' "$f"
  else
    perl -pi -e 's/minSdkVersion\s+flutter\.minSdkVersion/minSdkVersion Math.max(flutter.minSdkVersion, 23)/' "$f"
  fi
done
MANIFEST="android/app/src/main/AndroidManifest.xml"
if ! grep -q "android.permission.INTERNET" "$MANIFEST"; then
  perl -0pi -e 's/(<manifest[^>]*>)/$1\n    <uses-permission android:name="android.permission.INTERNET"\/>/' "$MANIFEST"
fi
perl -pi -e 's/android:label="[^"]*"/android:label="Lapticon"/' "$MANIFEST"

echo "==> Instalando dependencias"
flutter pub add firebase_core firebase_auth cloud_firestore http flutter_riverpod go_router shared_preferences google_fonts intl cupertino_icons
flutter pub get

echo "==> Configurando Firebase (lib/firebase_options.dart)"
[ -f "$GOOGLE_SERVICES" ] || { echo "ERROR: falta $GOOGLE_SERVICES"; exit 1; }
cp "$GOOGLE_SERVICES" android/app/google-services.json
dart run tool/generate_firebase_options.dart "$GOOGLE_SERVICES" "$APP_ID"

echo "==> Analizando y probando"
flutter analyze || true
flutter test || true

echo ""
echo "Listo. Abre un emulador Android (o conecta tu teléfono) y ejecuta:  flutter run"
