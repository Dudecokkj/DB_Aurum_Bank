#!/usr/bin/env bash
# Restaura um backup do Aurum Bank em um banco NOVO (nunca por cima do original).
# Uso:  bash backup/restore.sh arquivo.dump aurum_restore
set -euo pipefail
ARQ="${1:?informe o arquivo .dump}"
DESTINO="${2:-aurum_restore}"
if [ -f "$ARQ.sha256" ]; then sha256sum -c "$ARQ.sha256"; fi   # confere integridade
dropdb --if-exists "$DESTINO"
createdb "$DESTINO"
pg_restore --no-owner -d "$DESTINO" --exit-on-error "$ARQ"
psql -d "$DESTINO" -Atc "ANALYZE"
echo "Restauração concluída em: $DESTINO"
