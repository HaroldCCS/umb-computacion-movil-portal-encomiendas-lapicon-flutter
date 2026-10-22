#!/usr/bin/env bash
# Obtiene un idToken de Firebase para probar la API con curl (fuera de la app).
# Pide correo y contraseña por teclado (la contraseña no se muestra) y guarda
# { idToken, localId, email } en un archivo FUERA del repo con permisos 600.
#
# Uso:  cd lapticon_app && bash tool/obtener_token.sh [archivo_salida]
#       (por defecto ~/.lapticon/token.json)
# Luego: TOKEN=$(python3 -c 'import json,os;print(json.load(open(os.path.expanduser("~/.lapticon/token.json")))["idToken"])')
#        curl -H "Authorization: Bearer $TOKEN" https://lapticon-backend.onrender.com/api/users/<uid>
# El idToken vence en 1 hora: vuelve a ejecutar el script cuando expire.
set -euo pipefail
cd "$(dirname "$0")/.."

SALIDA="${1:-$HOME/.lapticon/token.json}"
API_KEY=$(grep -m1 "apiKey:" lib/firebase_options.dart | sed -E "s/.*'([^']+)'.*/\1/")
[ -n "$API_KEY" ] || { echo "ERROR: no encontré apiKey en lib/firebase_options.dart (corre setup.sh)"; exit 1; }

read -r -p "Correo: " CORREO
read -r -s -p "Contraseña: " CLAVE; echo

mkdir -p "$(dirname "$SALIDA")"
umask 077
CUERPO=$(CORREO="$CORREO" CLAVE="$CLAVE" python3 -c \
  'import json,os;print(json.dumps({"email":os.environ["CORREO"],"password":os.environ["CLAVE"],"returnSecureToken":True}))')
RESPUESTA=$(curl -sS -X POST -H "Content-Type: application/json" -d "$CUERPO" \
  "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$API_KEY")

echo "$RESPUESTA" | python3 -c '
import json, sys
r = json.load(sys.stdin)
if "idToken" not in r:
    sys.exit("ERROR de Firebase: " + r.get("error", {}).get("message", "respuesta inesperada"))
json.dump({k: r[k] for k in ("idToken", "localId", "email")}, open(sys.argv[1], "w"))
print("OK: token guardado en", sys.argv[1], "| uid:", r["localId"])
' "$SALIDA"
