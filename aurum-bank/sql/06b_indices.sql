-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Índices e prova de uso (EXPLAIN ANALYZE antes e depois)
-- Rode no banco aurum_perf (com a carga 06a). Reexecutável.
-- Leitura do plano: "Seq Scan" = lê a tabela inteira;
-- "Index Scan"/"Bitmap Index Scan" = usa o índice.
-- O PostgreSQL já cria índice para PRIMARY KEY e UNIQUE, mas NÃO cria
-- para chave estrangeira: por isso indexamos as FKs mais consultadas.
-- ============================================================

-- ------------------------------------------------------------
-- 0) Estado inicial: remove os índices do projeto (para repetir o teste)
-- ------------------------------------------------------------
DROP INDEX IF EXISTS idx_transacao_conta_data;
DROP INDEX IF EXISTS idx_transacao_destino;
DROP INDEX IF EXISTS idx_conta_titular_cliente;
DROP INDEX IF EXISTS idx_compra_cartao_cartao;
DROP INDEX IF EXISTS idx_emprestimo_cliente;
DROP INDEX IF EXISTS idx_parcela_abertas;
DROP INDEX IF EXISTS idx_conta_agencia;
ANALYZE;

-- ------------------------------------------------------------
-- 1) ANTES: as seis consultas que mais importam no dia a dia
-- ------------------------------------------------------------

-- A. Extrato de uma conta nos últimos 30 dias (tela principal do app)
EXPLAIN (ANALYZE, BUFFERS)
SELECT data_hora, tipo, valor, descricao
FROM transacao
WHERE id_conta = 4000
  AND data_hora >= '2026-10-17'
ORDER BY data_hora DESC;

-- B. Contas de um cliente (login: "quais são as minhas contas?")
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_conta, tipo_titular
FROM conta_titular
WHERE id_cliente = 2500;

-- C. Transferências recebidas por uma conta
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_conta, valor, data_hora
FROM transacao
WHERE id_conta_destino = 4000;

-- D. Compras de um cartão (fatura)
EXPLAIN (ANALYZE, BUFFERS)
SELECT estabelecimento, valor, parcelas, data_compra
FROM compra_cartao
WHERE id_cartao = 1500
ORDER BY data_compra DESC;

-- E. Empréstimos de um cliente
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_emprestimo, valor_contratado, status
FROM emprestimo
WHERE id_cliente = 2500;

-- F. Cobrança: parcelas vencidas e não pagas (cerca de 6% das parcelas)
EXPLAIN (ANALYZE, BUFFERS)
SELECT id_emprestimo, numero_parcela, valor_parcela, data_vencimento
FROM parcela_emprestimo
WHERE data_pagamento IS NULL
  AND data_vencimento < CURRENT_DATE;

-- ------------------------------------------------------------
-- 2) CRIAÇÃO DOS ÍNDICES (um para cada consulta acima)
-- ------------------------------------------------------------

-- A: composto (conta, data DESC): filtra a conta e já entrega ordenado, sem SORT.
CREATE INDEX idx_transacao_conta_data ON transacao (id_conta, data_hora DESC);

-- B: a PK de conta_titular é (id_conta, id_cliente); buscar só por cliente não a aproveita.
CREATE INDEX idx_conta_titular_cliente ON conta_titular (id_cliente);

-- C: parcial: só indexa transferências (a maioria dos lançamentos tem destino NULL).
CREATE INDEX idx_transacao_destino ON transacao (id_conta_destino)
    WHERE id_conta_destino IS NOT NULL;

-- D e E: índices em chaves estrangeiras.
CREATE INDEX idx_compra_cartao_cartao ON compra_cartao (id_cartao, data_compra DESC);
CREATE INDEX idx_emprestimo_cliente   ON emprestimo (id_cliente);

-- F: parcial: indexa só as parcelas em aberto (uma fração das ~48 mil), então o índice é minúsculo.
CREATE INDEX idx_parcela_abertas ON parcela_emprestimo (data_vencimento)
    WHERE data_pagamento IS NULL;

-- Também ajuda JOIN/agrupamento por agência.
CREATE INDEX idx_conta_agencia ON conta (id_agencia);

ANALYZE;

-- ------------------------------------------------------------
-- 3) DEPOIS: as mesmas seis consultas
-- ------------------------------------------------------------

EXPLAIN (ANALYZE, BUFFERS)
SELECT data_hora, tipo, valor, descricao
FROM transacao
WHERE id_conta = 4000
  AND data_hora >= '2026-10-17'
ORDER BY data_hora DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_conta, tipo_titular
FROM conta_titular
WHERE id_cliente = 2500;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_conta, valor, data_hora
FROM transacao
WHERE id_conta_destino = 4000;

EXPLAIN (ANALYZE, BUFFERS)
SELECT estabelecimento, valor, parcelas, data_compra
FROM compra_cartao
WHERE id_cartao = 1500
ORDER BY data_compra DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_emprestimo, valor_contratado, status
FROM emprestimo
WHERE id_cliente = 2500;

EXPLAIN (ANALYZE, BUFFERS)
SELECT id_emprestimo, numero_parcela, valor_parcela, data_vencimento
FROM parcela_emprestimo
WHERE data_pagamento IS NULL
  AND data_vencimento < CURRENT_DATE;

-- ------------------------------------------------------------
-- 4) Tamanho dos índices (custo: espaço e escrita mais lenta)
-- ------------------------------------------------------------
SELECT indexrelname AS indice,
       pg_size_pretty(pg_relation_size(indexrelid)) AS tamanho
FROM pg_stat_user_indexes
WHERE indexrelname LIKE 'idx_%'
ORDER BY pg_relation_size(indexrelid) DESC;

-- Índices que nunca foram usados (candidatos a remoção):
-- SELECT indexrelname, idx_scan FROM pg_stat_user_indexes WHERE idx_scan = 0;
