#!/usr/bin/env bash
set -euo pipefail

DOMAINS="svmefr.com www.svmefr.com"
URL="https://hayahora.futbol/estado/blocked-any.txt"

curl -fsS --max-time 30 "$URL" -o blocked.txt

# Si no es una lista de IPv4 (p. ej. una página de error), abortar
if grep -Evq '^([0-9]{1,3}\.){3}[0-9]{1,3}$|^$' blocked.txt; then
  echo "Respuesta no válida" >&2; exit 1
fi

# IPs actuales de tu web
for d in $DOMAINS; do dig +short A "$d" @1.1.1.1 || true; done \
  | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' | sort -u > own.txt || true

# Si no se resolvió ninguna IP, abortar (evita falsos registros)
if [ ! -s own.txt ]; then
  echo "No se pudieron resolver las IPs" >&2; exit 1
fi

# Cuáles están bloqueadas ahora
grep -Fxf own.txt blocked.txt | sort -u > now.txt || true

touch state.txt blocks.log
TS=$(date -u +%FT%TZ)
comm -13 state.txt now.txt | sed "s/^/$TS INCLUIDA /" >> blocks.log
comm -23 state.txt now.txt | sed "s/^/$TS DEJA_DE_ESTAR /" >> blocks.log
cp now.txt state.txt
