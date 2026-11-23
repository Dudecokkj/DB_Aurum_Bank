#!/usr/bin/env bash
# Backup lógico do Aurum Bank com pg_dump (formato custom, comprimido).
# Uso:  DB=aurum BACKUP_DIR=/var/backups/aurum bash backup/backup.sh
# Agende (cron) diariamente, ex.: 0 2 * * *  /caminho/backup/backup.sh
# Retenção: mantém 7 backups diários e remove os mais antigos.
set -euo pipefail
DB="${DB:-aurum}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENCAO_DIAS="${RETENCAO_DIAS:-7}"
mkdir -p "$BACKUP_DIR"
STAMP="$(date +%Y%m%d_%H%M%S)"
ARQ="$BACKUP_DIR/${DB}_${STAMP}.dump"

pg_dump -Fc --no-owner -d "$DB" -f "$ARQ"            # dados + esquema, comprimido
pg_dump --schema-only --no-owner -d "$DB" -f "$BACKUP_DIR/${DB}_${STAMP}_schema.sql"
sha256sum "$ARQ" > "$ARQ.sha256"                      # integridade do arquivo
pg_restore --list "$ARQ" > /dev/null                  # valida que o dump é legível

find "$BACKUP_DIR" -name "${DB}_*" -mtime +"$RETENCAO_DIAS" -delete
echo "Backup OK: $ARQ ($(du -h "$ARQ" | cut -f1))"
