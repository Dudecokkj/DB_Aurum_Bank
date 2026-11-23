-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Plano de concorrência (leitura guiada + roteiro para DUAS sessões)
-- Teste automatizado: testes/concorrencia.sh (resultados no relatório)
-- ============================================================

-- ------------------------------------------------------------
-- 1) Onde há risco de concorrência no Aurum Bank
-- ------------------------------------------------------------
--  R1. Dois saques/pagamentos ao mesmo tempo na MESMA conta
--      -> "atualização perdida" (lost update): um saque some.
--  R2. Duas transferências cruzadas (1->3 e 3->1) ao mesmo tempo
--      -> deadlock: cada uma segura a conta que a outra quer.
--  R3. Débito de empréstimo/tarifa rodando junto com o uso do cliente
--      -> mesma conta alterada por quem chega primeiro.
--
-- ------------------------------------------------------------
-- 2) Estratégia adotada (regras para toda operação que muda saldo)
-- ------------------------------------------------------------
--  E1. Toda alteração de saldo ocorre dentro de BEGIN ... COMMIT.
--  E2. Trava pessimista: SELECT ... FROM conta WHERE ... FOR UPDATE antes
--      de decidir. A outra sessão espera o COMMIT e lê o saldo já atualizado.
--  E3. O UPDATE leva a condição "AND saldo >= valor" (cinto e suspensório):
--      se não houver saldo, afeta 0 linhas e a aplicação cancela a operação.
--  E4. Operações com DUAS contas travam sempre na mesma ordem
--      (menor id_conta primeiro) -> elimina deadlock por ordem cruzada.
--  E5. Nível de isolamento READ COMMITTED (padrão do PostgreSQL) basta
--      porque as travas explícitas (E2) cobrem o risco; para relatórios que
--      precisam de uma "foto" consistente use REPEATABLE READ (somente leitura).
--  E6. Deadlock que ainda escapar é detectado pelo PostgreSQL (deadlock_timeout,
--      1 s por padrão): uma transação é abortada e a aplicação refaz a operação.
--
-- ------------------------------------------------------------
-- 3) Padrão correto de SAQUE (use este modelo)
-- ------------------------------------------------------------
BEGIN;
SELECT saldo FROM conta WHERE id_conta = 7 FOR UPDATE;

UPDATE conta
SET saldo = saldo - 500.00
WHERE id_conta = 7
  AND saldo >= 500.00;          -- 0 linhas afetadas = saldo insuficiente (aplicação faz ROLLBACK)

INSERT INTO transacao (id_conta, tipo, valor, descricao)
VALUES (7, 'SAQUE', 500.00, 'Saque em caixa eletrônico');
COMMIT;

-- ------------------------------------------------------------
-- 4) Padrão correto de TRANSFERÊNCIA (trava em ordem crescente de id)
-- ------------------------------------------------------------
BEGIN;
SELECT id_conta FROM conta
WHERE id_conta IN (1, 3)
ORDER BY id_conta
FOR UPDATE;                     -- trava as duas, sempre da menor para a maior

UPDATE conta SET saldo = saldo - 100.00 WHERE id_conta = 1 AND saldo >= 100.00;
UPDATE conta SET saldo = saldo + 100.00 WHERE id_conta = 3;
INSERT INTO transacao (id_conta, id_conta_destino, tipo, valor, descricao)
VALUES (1, 3, 'TRANSFERENCIA', 100.00, 'Transferência com trava ordenada');
COMMIT;

-- ------------------------------------------------------------
-- 5) Roteiro manual com DUAS sessões (abra dois terminais psql)
--    Cenário: conta 7 com saldo de R$ 600; duas sessões sacam R$ 500.
--    Prepare:  UPDATE conta SET saldo = 600 WHERE id_conta = 7;
-- ------------------------------------------------------------
--  Sessão A                                   Sessão B
--  BEGIN;                                     BEGIN;
--  SELECT saldo FROM conta                    
--    WHERE id_conta = 7 FOR UPDATE;           
--  (devolve 600)                              SELECT saldo FROM conta
--                                               WHERE id_conta = 7 FOR UPDATE;
--                                             (FICA ESPERANDO...)
--  UPDATE conta SET saldo = saldo - 500
--    WHERE id_conta = 7 AND saldo >= 500;
--  (1 linha)
--  COMMIT;
--                                             (liberou) devolve 100
--                                             UPDATE ... AND saldo >= 500;
--                                             (0 linhas: saldo insuficiente)
--                                             ROLLBACK;
--  Resultado final: saldo = 100. Só um saque foi aceito.

-- ------------------------------------------------------------
-- 6) Como observar travas enquanto o teste roda (terceira sessão)
-- ------------------------------------------------------------
-- Quem está esperando e por quem:
SELECT bloqueado.pid  AS pid_esperando,
       bloqueador.pid AS pid_bloqueando,
       bloqueado.query AS consulta_esperando
FROM pg_stat_activity bloqueado
JOIN pg_stat_activity bloqueador
  ON bloqueador.pid = ANY (pg_blocking_pids(bloqueado.pid))
WHERE cardinality(pg_blocking_pids(bloqueado.pid)) > 0;
