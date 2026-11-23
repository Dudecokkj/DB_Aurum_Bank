#!/usr/bin/env bash
# Teste REAL do plano de backup: backup -> desastre simulado -> restauração -> conferência.
# Uso: DB=aurum bash testes/backup_teste.sh
set -euo pipefail
DB="${DB:-aurum}"
RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
TABELAS="agencia cliente conta conta_corrente conta_poupanca conta_titular categoria_transacao transacao cartao compra_cartao emprestimo parcela_emprestimo"
resumo() { # linha por tabela: nome|contagem|md5 do conteúdo ordenado
  for t in $TABELAS; do
    psql -d "$1" -Atc "SELECT '$t', COUNT(*), md5(string_agg(x::text, ',' ORDER BY x::text)) FROM $t x"
  done
}
echo "1) Estado ORIGINAL de $DB"; resumo "$DB" > "$TMP/antes.txt"; cut -d'|' -f1,2 "$TMP/antes.txt" | awk -F'|' '{printf "  %-22s %s linhas\n",$1,$2}'

echo; echo "2) Fazendo o backup"; T0=$(date +%s%N)
DB="$DB" BACKUP_DIR="$TMP/bk" bash "$RAIZ/backup/backup.sh"
T1=$(date +%s%N); awk -v a=$T0 -v b=$T1 'BEGIN{printf "Tempo do backup: %.2f s\n",(b-a)/1e9}'
ARQ="$(ls "$TMP"/bk/${DB}_*.dump)"

echo; echo "3) Restaurando em banco NOVO (${DB}_restore)"; T0=$(date +%s%N)
bash "$RAIZ/backup/restore.sh" "$ARQ" "${DB}_restore"
T1=$(date +%s%N); awk -v a=$T0 -v b=$T1 'BEGIN{printf "Tempo da restauração: %.2f s\n",(b-a)/1e9}'

echo; echo "4) Conferindo restauração (contagem + md5 do conteúdo de cada tabela)"
resumo "${DB}_restore" > "$TMP/depois.txt"
if diff -q "$TMP/antes.txt" "$TMP/depois.txt" >/dev/null; then echo "RESULTADO: IDÊNTICO em todas as 12 tabelas"; else echo "RESULTADO: DIFERENTE"; diff "$TMP/antes.txt" "$TMP/depois.txt"; exit 1; fi
echo "Verificando constraints/índices no banco restaurado:"
psql -d "${DB}_restore" -Atc "SELECT 'constraints: '||COUNT(*) FROM pg_constraint WHERE connamespace='public'::regnamespace"
psql -d "$DB"           -Atc "SELECT 'constraints (original): '||COUNT(*) FROM pg_constraint WHERE connamespace='public'::regnamespace"

echo; echo "5) Simulando desastre: DROP TABLE transacao CASCADE no banco restaurado e recuperando"
psql -d "${DB}_restore" -qc "DROP TABLE transacao CASCADE"
bash "$RAIZ/backup/restore.sh" "$ARQ" "${DB}_restore" >/dev/null
resumo "${DB}_restore" > "$TMP/depois2.txt"
diff -q "$TMP/antes.txt" "$TMP/depois2.txt" >/dev/null && echo "RESULTADO: dados recuperados por completo após o desastre" || { echo "FALHA"; exit 1; }
dropdb "${DB}_restore"; rm -rf "$TMP"
