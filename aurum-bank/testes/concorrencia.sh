#!/usr/bin/env bash
# Teste REAL de concorrência: duas sessões psql ao mesmo tempo no banco aurum.
# Uso: PGHOST=... PGPORT=... PGUSER=... bash testes/concorrencia.sh
# Recarrega a carga (01b) antes de cada cenário para partir de um estado conhecido.
set -u
DB=${DB:-aurum}
SQL_DIR="$(cd "$(dirname "$0")/../sql" && pwd)"
reset() { psql -q -d "$DB" -f "$SQL_DIR/01b_carga_dados.sql" >/dev/null 2>&1; }
run() { psql -q -d "$DB" -X "$@"; }
saldo() { run -At -c "SELECT 'saldo conta '||id_conta||' = '||saldo FROM conta WHERE id_conta IN ($1) ORDER BY id_conta"; }

echo "=== Cenário 1: SEM trava (lê o saldo, espera, grava o valor calculado) ==="
reset; run -At -c "UPDATE conta SET saldo = 1000 WHERE id_conta = 7"; saldo 7
for s in A B; do
 ( run -At <<'SQL'
SELECT saldo AS lido FROM conta WHERE id_conta = 7 \gset
SELECT pg_sleep(2);
UPDATE conta SET saldo = :lido - 500 WHERE id_conta = 7;
SQL
 ) & done; wait
echo "Esperado se fosse correto: 0 (dois saques de 500). Resultado:"; saldo 7

echo; echo "=== Cenário 2: COM SELECT ... FOR UPDATE ==="
reset; run -At -c "UPDATE conta SET saldo = 1000 WHERE id_conta = 7"; saldo 7
for s in A B; do
 ( run -At <<'SQL'
BEGIN;
SELECT saldo AS lido FROM conta WHERE id_conta = 7 FOR UPDATE \gset
SELECT pg_sleep(2);
UPDATE conta SET saldo = :lido - 500 WHERE id_conta = 7;
COMMIT;
SQL
 ) & done; wait
echo "Resultado (esperado 0):"; saldo 7

echo; echo "=== Cenário 3: saldo 600, dois saques de 500 com FOR UPDATE + condição saldo >= 500 ==="
reset; run -At -c "UPDATE conta SET saldo = 600 WHERE id_conta = 7"; saldo 7
for s in A B; do
 ( run -At <<SQL
BEGIN;
SELECT saldo FROM conta WHERE id_conta = 7 FOR UPDATE \g /dev/null
SELECT pg_sleep(2);
UPDATE conta SET saldo = saldo - 500 WHERE id_conta = 7 AND saldo >= 500;
COMMIT;
SQL
 ) 2>&1 | sed "s/^/[sessão $s] /" & done; wait
echo "Resultado (esperado 100: só UM saque foi aceito):"; saldo 7

echo; echo "=== Cenário 4: DEADLOCK (transferências cruzadas 1->3 e 3->1, ordem diferente) ==="
reset; saldo "1,3"
( run -At <<'SQL' 2>&1 | sed 's/^/[A: 1->3] /'
BEGIN;
UPDATE conta SET saldo = saldo - 100 WHERE id_conta = 1;
SELECT pg_sleep(2);
UPDATE conta SET saldo = saldo + 100 WHERE id_conta = 3;
COMMIT;
SQL
) &
( run -At <<'SQL' 2>&1 | sed 's/^/[B: 3->1] /'
BEGIN;
UPDATE conta SET saldo = saldo - 100 WHERE id_conta = 3;
SELECT pg_sleep(2);
UPDATE conta SET saldo = saldo + 100 WHERE id_conta = 1;
COMMIT;
SQL
) &
wait; echo "Saldos após o deadlock (uma transação foi desfeita):"; saldo "1,3"

echo; echo "=== Cenário 5: PREVENÇÃO — travar sempre na mesma ordem (menor id primeiro) ==="
reset; saldo "1,3"
( run -At <<'SQL' 2>&1 | sed 's/^/[A: 1->3] /'
BEGIN;
SELECT id_conta FROM conta WHERE id_conta IN (1,3) ORDER BY id_conta FOR UPDATE \g /dev/null
SELECT pg_sleep(2);
UPDATE conta SET saldo = saldo - 100 WHERE id_conta = 1;
UPDATE conta SET saldo = saldo + 100 WHERE id_conta = 3;
COMMIT;
SQL
) &
( run -At <<'SQL' 2>&1 | sed 's/^/[B: 3->1] /'
BEGIN;
SELECT id_conta FROM conta WHERE id_conta IN (1,3) ORDER BY id_conta FOR UPDATE \g /dev/null
SELECT pg_sleep(2);
UPDATE conta SET saldo = saldo - 100 WHERE id_conta = 3;
UPDATE conta SET saldo = saldo + 100 WHERE id_conta = 1;
COMMIT;
SQL
) &
wait; echo "Saldos finais (iguais aos iniciais: as duas transferências se cancelam):"; saldo "1,3"
reset
