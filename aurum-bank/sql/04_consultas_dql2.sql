-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Consultas DQL II (22 consultas: JOIN, GROUP BY, HAVING, ORDER BY
-- e funções de agregação COUNT, SUM, AVG, MIN e MAX)
-- Método: FROM/JOIN -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY / LIMIT
-- ============================================================

-- ------------------------------------------------------------
-- Aquecimento: as cinco funções de agregação
-- ------------------------------------------------------------

-- Q1. As cinco funções de agregação sobre as contas: quantidade, soma, média, menor e maior saldo.
SELECT COUNT(*)   AS qtd_contas,
       SUM(saldo) AS saldo_total,
       AVG(saldo) AS saldo_medio,
       MIN(saldo) AS menor_saldo,
       MAX(saldo) AS maior_saldo
FROM conta;

-- ------------------------------------------------------------
-- Parte 1: JOIN
-- ------------------------------------------------------------

-- Q2. Quem é o dono de cada conta? Titular, agência, número e saldo das contas ATIVAS.
SELECT cl.nome, ag.nome AS agencia, c.numero, c.tipo_conta, c.saldo
FROM conta_titular ct
JOIN cliente cl ON cl.id_cliente = ct.id_cliente
JOIN conta c    ON c.id_conta    = ct.id_conta
JOIN agencia ag ON ag.id_agencia = c.id_agencia
WHERE c.status = 'ATIVA'
  AND ct.tipo_titular = 'PRINCIPAL'
ORDER BY cl.nome, c.numero;

-- Q3. Contas conjuntas: conta com todos os seus titulares.
SELECT c.numero, cl.nome, ct.tipo_titular
FROM conta_titular ct
JOIN conta c    ON c.id_conta    = ct.id_conta
JOIN cliente cl ON cl.id_cliente = ct.id_cliente
WHERE ct.id_conta IN (SELECT id_conta FROM conta_titular GROUP BY id_conta HAVING COUNT(*) > 1)
ORDER BY c.numero, ct.tipo_titular;

-- Q4. Extrato legível: conta, categoria, tipo e valor de cada lançamento.
SELECT c.numero, t.data_hora, t.tipo, cat.nome_categoria, t.valor, t.descricao
FROM transacao t
JOIN conta c                   ON c.id_conta      = t.id_conta
LEFT JOIN categoria_transacao cat ON cat.id_categoria = t.id_categoria
ORDER BY c.numero, t.data_hora;

-- Q5. Transferências com conta de origem e de destino (duas junções na mesma tabela).
SELECT o.numero AS origem, d.numero AS destino, t.valor, t.data_hora
FROM transacao t
JOIN conta o ON o.id_conta = t.id_conta
JOIN conta d ON d.id_conta = t.id_conta_destino
WHERE t.tipo = 'TRANSFERENCIA'
ORDER BY t.data_hora DESC;

-- Q6. Cartões com o nome do titular e o número da conta de débito.
SELECT cl.nome, ca.bandeira, ca.numero_final, ca.limite_credito, c.numero AS conta
FROM cartao ca
JOIN cliente cl ON cl.id_cliente = ca.id_cliente
JOIN conta c    ON c.id_conta    = ca.id_conta
ORDER BY cl.nome;

-- Q7. Compras no cartão com o nome do cliente (apenas compras acima de R$ 1.000).
SELECT cl.nome, co.estabelecimento, co.valor, co.parcelas, co.data_compra
FROM compra_cartao co
JOIN cartao ca  ON ca.id_cartao  = co.id_cartao
JOIN cliente cl ON cl.id_cliente = ca.id_cliente
WHERE co.valor > 1000
ORDER BY co.data_compra DESC;

-- ------------------------------------------------------------
-- Parte 2: Funções de agregação com GROUP BY
-- ------------------------------------------------------------

-- Q8. Quantas contas há em cada agência, incluindo agências sem conta? (COUNT)
SELECT ag.nome, COUNT(c.id_conta) AS total_contas
FROM agencia ag
LEFT JOIN conta c ON c.id_agencia = ag.id_agencia
GROUP BY ag.id_agencia, ag.nome
ORDER BY total_contas DESC, ag.nome;

-- Q9. Qual o saldo total guardado em cada agência, só de contas ATIVAS? (SUM)
SELECT ag.nome, SUM(c.saldo) AS saldo_total
FROM conta c
JOIN agencia ag ON ag.id_agencia = c.id_agencia
WHERE c.status = 'ATIVA'
GROUP BY ag.id_agencia, ag.nome
ORDER BY saldo_total DESC;

-- Q10. Qual o saldo médio por tipo de conta? (AVG)
SELECT tipo_conta, COUNT(*) AS qtd, ROUND(AVG(saldo), 2) AS saldo_medio
FROM conta
GROUP BY tipo_conta
ORDER BY saldo_medio DESC;

-- Q11. Menor e maior valor movimentado por tipo de transação. (MIN/MAX)
SELECT tipo,
       MIN(valor) AS menor_valor,
       MAX(valor) AS maior_valor
FROM transacao
GROUP BY tipo
ORDER BY tipo;

-- Q12. Quanto cada categoria movimentou (apenas saídas: pagamentos, saques e tarifas)?
SELECT cat.nome_categoria, COUNT(*) AS qtd, SUM(t.valor) AS total_gasto
FROM transacao t
JOIN categoria_transacao cat ON cat.id_categoria = t.id_categoria
WHERE t.tipo IN ('PAGAMENTO', 'SAQUE', 'TARIFA')
GROUP BY cat.id_categoria, cat.nome_categoria
ORDER BY total_gasto DESC;

-- Q13. Quantas contas cada cliente possui, incluindo quem tem zero? (COUNT(coluna) ignora NULL)
SELECT cl.nome, COUNT(ct.id_conta) AS qtd_contas
FROM cliente cl
LEFT JOIN conta_titular ct ON ct.id_cliente = cl.id_cliente
GROUP BY cl.id_cliente, cl.nome
ORDER BY qtd_contas DESC, cl.nome;

-- Q14. Total gasto no cartão por cliente, do maior para o menor. (SUM)
SELECT cl.nome, SUM(co.valor) AS total_compras
FROM compra_cartao co
JOIN cartao ca  ON ca.id_cartao  = co.id_cartao
JOIN cliente cl ON cl.id_cliente = ca.id_cliente
GROUP BY cl.id_cliente, cl.nome
ORDER BY total_compras DESC, cl.nome
LIMIT 10;

-- Q15. Resumo dos empréstimos por status: quantidade, valor total, taxa média, menor e maior contrato.
SELECT status,
       COUNT(*)                          AS qtd,
       SUM(valor_contratado)             AS valor_total,
       ROUND(AVG(taxa_juros_mensal), 4)  AS taxa_media,
       MIN(valor_contratado)             AS menor,
       MAX(valor_contratado)             AS maior
FROM emprestimo
GROUP BY status
ORDER BY status;

-- Q16. Quantidade de parcelas e valor total a pagar de cada empréstimo.
SELECT e.id_emprestimo, cl.nome, COUNT(*) AS qtd_parcelas, SUM(p.valor_parcela) AS total_a_pagar
FROM parcela_emprestimo p
JOIN emprestimo e ON e.id_emprestimo = p.id_emprestimo
JOIN cliente cl   ON cl.id_cliente   = e.id_cliente
GROUP BY e.id_emprestimo, cl.nome
ORDER BY total_a_pagar DESC;

-- ------------------------------------------------------------
-- Parte 3: HAVING (filtro sobre o resultado do grupo)
-- ------------------------------------------------------------

-- Q17. Agências com saldo total superior a R$ 30.000.
SELECT ag.nome, SUM(c.saldo) AS saldo_total
FROM conta c
JOIN agencia ag ON ag.id_agencia = c.id_agencia
GROUP BY ag.id_agencia, ag.nome
HAVING SUM(c.saldo) > 30000
ORDER BY saldo_total DESC;

-- Q18. Clientes com mais de uma conta.
SELECT cl.nome, COUNT(*) AS qtd_contas
FROM conta_titular ct
JOIN cliente cl ON cl.id_cliente = ct.id_cliente
GROUP BY cl.id_cliente, cl.nome
HAVING COUNT(*) > 1
ORDER BY qtd_contas DESC, cl.nome;

-- Q19. Contas com mais de 5 movimentações no extrato.
SELECT c.numero, COUNT(*) AS qtd_movimentacoes
FROM transacao t
JOIN conta c ON c.id_conta = t.id_conta
GROUP BY c.id_conta, c.numero
HAVING COUNT(*) > 5
ORDER BY qtd_movimentacoes DESC;

-- Q20. Estabelecimentos onde mais de um cliente comprou no cartão.
SELECT co.estabelecimento, COUNT(*) AS qtd_compras, SUM(co.valor) AS total
FROM compra_cartao co
GROUP BY co.estabelecimento
HAVING COUNT(*) > 1
ORDER BY qtd_compras DESC, total DESC;

-- Q21. Clientes com mais de R$ 5.000 em compras no cartão.
SELECT cl.nome, SUM(co.valor) AS total_compras
FROM compra_cartao co
JOIN cartao ca  ON ca.id_cartao  = co.id_cartao
JOIN cliente cl ON cl.id_cliente = ca.id_cliente
GROUP BY cl.id_cliente, cl.nome
HAVING SUM(co.valor) > 5000
ORDER BY total_compras DESC;

-- Q22. Empréstimos com parcelas vencidas e não pagas: quantas e quanto falta receber (data de referência: hoje).
SELECT e.id_emprestimo, cl.nome, COUNT(*) AS parcelas_vencidas, SUM(p.valor_parcela) AS valor_em_atraso
FROM parcela_emprestimo p
JOIN emprestimo e ON e.id_emprestimo = p.id_emprestimo
JOIN cliente cl   ON cl.id_cliente   = e.id_cliente
WHERE p.data_pagamento IS NULL
  AND p.data_vencimento < CURRENT_DATE
GROUP BY e.id_emprestimo, cl.nome
HAVING COUNT(*) >= 1
ORDER BY valor_em_atraso DESC;
