-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Consultas DQL (14 consultas, cada uma sobre uma única tabela)
-- Método: FROM -> WHERE -> SELECT -> ORDER BY / LIMIT
-- ============================================================

-- Q1. Contas do banco, da mais antiga para a mais nova.
SELECT numero, tipo_conta, data_abertura
FROM conta
ORDER BY data_abertura ASC;

-- Q2. Contas com saldo acima de R$ 10.000, da maior para a menor.
SELECT numero, tipo_conta, saldo
FROM conta
WHERE saldo > 10000
ORDER BY saldo DESC;

-- Q3. Contas que NÃO estão ativas (bloqueadas ou encerradas).
SELECT numero, status
FROM conta
WHERE status IN ('BLOQUEADA', 'ENCERRADA')
ORDER BY numero;

-- Q4. Cartões que não estão ativos, com a bandeira.
SELECT id_cartao, numero_final, bandeira, status
FROM cartao
WHERE status <> 'ATIVO';

-- Q5. Clientes sem renda informada (campo NULL).
SELECT nome, email
FROM cliente
WHERE renda_mensal IS NULL;

-- Q6. Clientes cadastrados em 2026 (data_cadastro é TIMESTAMP).
SELECT nome, email, data_cadastro
FROM cliente
WHERE data_cadastro >= '2026-01-01'
  AND data_cadastro <  '2027-01-01'
ORDER BY data_cadastro;

-- Q7. Empréstimos em atraso.
SELECT id_emprestimo, id_cliente, valor_contratado, data_contratacao
FROM emprestimo
WHERE status = 'ATRASADO';

-- Q8. Parcelas ainda não pagas (sem data de pagamento), pelo vencimento.
SELECT id_emprestimo, numero_parcela, valor_parcela, data_vencimento
FROM parcela_emprestimo
WHERE data_pagamento IS NULL
ORDER BY data_vencimento
LIMIT 20;

-- Q9. Estabelecimentos com "Eletr" no nome, sem diferenciar maiúsculas.
SELECT id_compra, estabelecimento, valor
FROM compra_cartao
WHERE estabelecimento ILIKE '%eletr%';

-- Q10. As 5 maiores compras no cartão.
SELECT estabelecimento, valor, parcelas
FROM compra_cartao
ORDER BY valor DESC
LIMIT 5;

-- Q11. Transferências de valor entre R$ 500 e R$ 2.000.
SELECT id_transacao, id_conta, id_conta_destino, valor, data_hora
FROM transacao
WHERE tipo = 'TRANSFERENCIA'
  AND valor BETWEEN 500 AND 2000
ORDER BY valor DESC;

-- Q12. Movimentações feitas em novembro de 2026, da mais recente à mais antiga.
SELECT id_transacao, tipo, valor, data_hora, descricao
FROM transacao
WHERE data_hora >= '2026-11-01'
  AND data_hora <  '2026-12-01'
ORDER BY data_hora DESC;

-- Q13. Compras parceladas em 10 vezes ou mais.
SELECT estabelecimento, valor, parcelas
FROM compra_cartao
WHERE parcelas >= 10
ORDER BY parcelas DESC, valor DESC;

-- Q14. Contas correntes com cheque especial de R$ 3.000 ou mais.
SELECT id_conta, limite_cheque_especial, tarifa_mensal
FROM conta_corrente
WHERE limite_cheque_especial >= 3000
ORDER BY limite_cheque_especial DESC;
