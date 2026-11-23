-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Carga de VOLUME para testar índices (base populada)
-- Rode SOMENTE em um banco de teste de desempenho (aurum_perf):
--   createdb aurum_perf
--   psql -d aurum_perf -f 01_script_ddl.sql
--   psql -d aurum_perf -f 01b_carga_dados.sql
--   psql -d aurum_perf -f 06a_carga_volume.sql
-- Os saldos das contas geradas aqui NÃO são conciliados com o extrato:
-- o objetivo é só ter volume realista para medir consultas.
-- Volume final aproximado: 5.000 clientes, 6.000 contas,
-- 400.000 transações, 3.000 cartões, 30.000 compras e
-- 4.000 empréstimos com ~48.000 parcelas.
-- ============================================================
BEGIN;
SELECT setseed(0.42);   -- dados reproduzíveis

-- 5.000 clientes fictícios (ids a partir de 101)
INSERT INTO cliente (nome, email, senha_hash, cpf, data_nascimento, renda_mensal, data_cadastro)
SELECT 'Cliente Teste ' || g,
       'teste' || g || '@exemplo.com',
       '$2b$12$hashficticio' || lpad(g::text, 10, '0'),
       lpad((1000000 + g)::text, 9, '0') || '-' || lpad((g % 100)::text, 2, '0'),
       DATE '1960-01-01' + (random() * 15000)::int,
       (2000 + random() * 18000)::numeric(12,2),
       TIMESTAMP '2024-01-01' + random() * INTERVAL '900 days'
FROM generate_series(1, 5000) g;

-- 6.000 contas correntes distribuídas nas agências 1 a 3
INSERT INTO conta (id_agencia, numero, saldo, data_abertura, status, tipo_conta)
SELECT 1 + (g % 3),
       'P' || lpad(g::text, 8, '0'),
       (random() * 30000)::numeric(14,2),
       DATE '2024-01-01' + (random() * 900)::int,
       CASE WHEN random() < 0.95 THEN 'ATIVA' ELSE 'BLOQUEADA' END,
       'CORRENTE'
FROM generate_series(1, 6000) g;

INSERT INTO conta_corrente (id_conta, limite_cheque_especial, tarifa_mensal)
SELECT id_conta, 1000, 19.90 FROM conta WHERE numero LIKE 'P%';

-- cada conta de volume tem um titular principal (cliente de volume, em rodízio)
INSERT INTO conta_titular (id_conta, id_cliente, tipo_titular)
SELECT c.id_conta,
       (SELECT MIN(id_cliente) FROM cliente WHERE email LIKE 'teste%') + ((row_number() OVER (ORDER BY c.id_conta) - 1) % 5000),
       'PRINCIPAL'
FROM conta c WHERE c.numero LIKE 'P%'
ON CONFLICT DO NOTHING;

-- 400.000 transações nos últimos ~2 anos (apenas DEPOSITO, PAGAMENTO e SAQUE)
INSERT INTO transacao (id_conta, id_categoria, tipo, valor, data_hora, descricao)
SELECT (SELECT MIN(id_conta) FROM conta WHERE numero LIKE 'P%') + (random() * 5999)::int,
       1 + (random() * 8)::int,
       (ARRAY['DEPOSITO','PAGAMENTO','SAQUE'])[1 + (random() * 2)::int],
       (1 + random() * 2000)::numeric(14,2),
       TIMESTAMP '2025-01-01' + random() * INTERVAL '700 days',
       'Movimentação de teste'
FROM generate_series(1, 400000);

-- 3.000 cartões e 30.000 compras
INSERT INTO cartao (id_conta, id_cliente, numero_final, bandeira, limite_credito, validade, status)
SELECT ct.id_conta, ct.id_cliente, lpad((g % 10000)::text, 4, '0'),
       (ARRAY['VISA','MASTERCARD','ELO'])[1 + g % 3],
       (1000 + random() * 20000)::numeric(12,2), DATE '2030-12-31', 'ATIVO'
FROM (SELECT id_conta, id_cliente, row_number() OVER () g
      FROM conta_titular ct2 WHERE tipo_titular = 'PRINCIPAL' AND id_cliente > 12 LIMIT 3000) ct;

INSERT INTO compra_cartao (id_cartao, estabelecimento, valor, parcelas, data_compra)
SELECT (SELECT MIN(id_cartao) FROM cartao WHERE id_cartao > 9) + (random() * 2999)::int,
       'Loja ' || (1 + (random() * 200)::int),
       (10 + random() * 1500)::numeric(12,2),
       1 + (random() * 11)::int,
       TIMESTAMP '2025-06-01' + random() * INTERVAL '500 days'
FROM generate_series(1, 30000);

-- 4.000 empréstimos com 12 parcelas cada (parcelas passadas pagas, futuras e algumas vencidas em aberto)
INSERT INTO emprestimo (id_cliente, id_conta, valor_contratado, taxa_juros_mensal, qtd_parcelas, data_contratacao, status)
SELECT ct.id_cliente, ct.id_conta, (1000 + random() * 30000)::numeric(12,2), 0.0199, 12,
       DATE '2025-06-01' + (random() * 400)::int, 'EM_DIA'
FROM (SELECT id_conta, id_cliente FROM conta_titular
      WHERE tipo_titular = 'PRINCIPAL' AND id_cliente > 12 LIMIT 4000) ct;

INSERT INTO parcela_emprestimo (id_emprestimo, numero_parcela, valor_parcela, data_vencimento, data_pagamento)
SELECT e.id_emprestimo, n, round((e.valor_contratado * 1.15 / 12)::numeric, 2),
       (e.data_contratacao + (n * INTERVAL '1 month'))::date,
       CASE WHEN e.data_contratacao + (n * INTERVAL '1 month') < DATE '2026-11-01'
                 AND random() < 0.97
            THEN (e.data_contratacao + (n * INTERVAL '1 month'))::date END
FROM emprestimo e CROSS JOIN generate_series(1, 12) n
WHERE e.id_emprestimo > 6;

SELECT setval(pg_get_serial_sequence('cliente','id_cliente'),(SELECT MAX(id_cliente) FROM cliente));
SELECT setval(pg_get_serial_sequence('conta','id_conta'),(SELECT MAX(id_conta) FROM conta));
COMMIT;
ANALYZE;

SELECT 'cliente' t, COUNT(*) FROM cliente UNION ALL SELECT 'conta', COUNT(*) FROM conta
UNION ALL SELECT 'transacao', COUNT(*) FROM transacao UNION ALL SELECT 'cartao', COUNT(*) FROM cartao
UNION ALL SELECT 'compra_cartao', COUNT(*) FROM compra_cartao UNION ALL SELECT 'emprestimo', COUNT(*) FROM emprestimo
UNION ALL SELECT 'parcela_emprestimo', COUNT(*) FROM parcela_emprestimo;
