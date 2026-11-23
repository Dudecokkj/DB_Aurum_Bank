-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Subconsultas, Views, DCL e TCL (10 subconsultas, 2 views, 1 papel
-- com GRANT/REVOKE e 7 passos de transação)
-- Método: rode a subconsulta SOZINHA primeiro (valor, lista ou tabela?)
--         e só então encaixe na consulta de fora (=, IN, EXISTS, FROM)
-- Linhas começadas por "-- " dentro dos blocos são testes que DÃO ERRO de
-- propósito: descomente e rode à parte para ver a mensagem.
-- ============================================================

-- ------------------------------------------------------------
-- Parte 1: Subconsultas
-- ------------------------------------------------------------

-- Q1. Contas com saldo acima da média do banco, sem escrever a média na mão.
SELECT numero, tipo_conta, saldo
FROM conta
WHERE saldo > (SELECT AVG(saldo) FROM conta)
ORDER BY saldo DESC;

-- Q2. Quanto cada agência representa do saldo total do banco, em %, com 1 casa.
SELECT ag.nome,
       SUM(c.saldo) AS saldo_agencia,
       ROUND(100.0 * SUM(c.saldo) / (SELECT SUM(saldo) FROM conta), 1) AS percentual
FROM conta c
JOIN agencia ag ON ag.id_agencia = c.id_agencia
GROUP BY ag.id_agencia, ag.nome
ORDER BY percentual DESC;

-- Q3. Clientes que têm algum empréstimo ATRASADO (lista de ids com IN).
SELECT nome, email
FROM cliente
WHERE id_cliente IN (SELECT id_cliente
                     FROM emprestimo
                     WHERE status = 'ATRASADO');

-- Q4. Clientes que NÃO têm nenhum cartão (NOT EXISTS).
SELECT cl.nome
FROM cliente cl
WHERE NOT EXISTS (SELECT 1
                  FROM cartao ca
                  WHERE ca.id_cliente = cl.id_cliente)
ORDER BY cl.nome;

-- Q5. Contas que nunca tiveram nenhuma movimentação (NOT EXISTS evita a armadilha do NOT IN com NULL).
SELECT c.numero, c.tipo_conta, c.status
FROM conta c
WHERE NOT EXISTS (SELECT 1
                  FROM transacao t
                  WHERE t.id_conta = c.id_conta
                     OR t.id_conta_destino = c.id_conta)
ORDER BY c.numero;

-- Q6. Compras no cartão acima da média do PRÓPRIO cartão (subconsulta correlacionada).
SELECT co.id_cartao, co.estabelecimento, co.valor
FROM compra_cartao co
WHERE co.valor > (SELECT AVG(co2.valor)
                  FROM compra_cartao co2
                  WHERE co2.id_cartao = co.id_cartao)
ORDER BY co.id_cartao, co.valor DESC;

-- Q7. Qual foi a ÚLTIMA movimentação de cada conta? Número, tipo, valor e data.
SELECT c.numero, t.tipo, t.valor, t.data_hora
FROM transacao t
JOIN conta c ON c.id_conta = t.id_conta
WHERE t.data_hora = (SELECT MAX(t2.data_hora)
                     FROM transacao t2
                     WHERE t2.id_conta = t.id_conta)
ORDER BY t.data_hora DESC;

-- Q8. Clientes cuja renda é maior que a renda média (subconsulta que devolve um valor).
SELECT nome, renda_mensal
FROM cliente
WHERE renda_mensal > (SELECT AVG(renda_mensal) FROM cliente)
ORDER BY renda_mensal DESC;

-- Q9. Gasto total no cartão por cliente, só de quem gastou 3.000 ou mais (subconsulta no FROM).
SELECT cl.nome, ROUND(g.total, 2) AS total_gasto
FROM (SELECT ca.id_cliente, SUM(co.valor) AS total
      FROM compra_cartao co
      JOIN cartao ca ON ca.id_cartao = co.id_cartao
      GROUP BY ca.id_cliente) g
JOIN cliente cl ON cl.id_cliente = g.id_cliente
WHERE g.total >= 3000
ORDER BY g.total DESC;

-- Q10. Empréstimos com mais parcelas que a média de parcelas por empréstimo.
SELECT e.id_emprestimo, e.valor_contratado, COUNT(*) AS qtd_parcelas
FROM parcela_emprestimo p
JOIN emprestimo e ON e.id_emprestimo = p.id_emprestimo
GROUP BY e.id_emprestimo, e.valor_contratado
HAVING COUNT(*) > (SELECT AVG(qtd)
                   FROM (SELECT COUNT(*) AS qtd
                         FROM parcela_emprestimo
                         GROUP BY id_emprestimo) t)
ORDER BY qtd_parcelas DESC;

-- ------------------------------------------------------------
-- Parte 2: Views (atendimento ao cliente) e DCL
-- ------------------------------------------------------------

-- Q11. Crie a view vw_contas_atendimento para o atendimento: titular, agência, conta, tipo, saldo e status.
-- NÃO pode expor senha_hash, cpf, data_nascimento nem renda.
CREATE OR REPLACE VIEW vw_contas_atendimento AS
SELECT c.id_conta, cl.nome, cl.email, ag.nome AS agencia,
       c.numero, c.tipo_conta, c.saldo, c.status
FROM conta c
JOIN conta_titular ct ON ct.id_conta   = c.id_conta AND ct.tipo_titular = 'PRINCIPAL'
JOIN cliente cl       ON cl.id_cliente = ct.id_cliente
JOIN agencia ag       ON ag.id_agencia = c.id_agencia;

-- Conferência: deve ser igual a SELECT COUNT(*) FROM conta;
SELECT COUNT(*) FROM vw_contas_atendimento;

-- Q12. Usando SÓ a view: contas BLOQUEADAS ou ENCERRADAS, por nome do titular.
SELECT nome, email, numero, status
FROM vw_contas_atendimento
WHERE status IN ('BLOQUEADA', 'ENCERRADA')
ORDER BY nome;

-- Q13. View de extrato resumido do mês (sem dados do cliente), para a auditoria.
CREATE OR REPLACE VIEW vw_extrato_resumo AS
SELECT c.numero, t.data_hora, t.tipo, t.valor, t.descricao
FROM transacao t
JOIN conta c ON c.id_conta = t.id_conta;

-- Q14. Crie o papel atendimento e dê a ele acesso SÓ às views. Depois teste como atendimento.
-- Para refazer o teste do zero: DROP OWNED BY atendimento; DROP ROLE atendimento;
-- CREATE ROLE dá erro se o papel já existir; este bloco só cria quando ainda não existe,
-- então o script pode ser rodado várias vezes.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'atendimento') THEN
        CREATE ROLE atendimento NOLOGIN;
    END IF;
END
$$;

GRANT atendimento TO CURRENT_USER;
GRANT USAGE  ON SCHEMA public            TO atendimento;
GRANT SELECT ON vw_contas_atendimento    TO atendimento;
GRANT SELECT ON vw_extrato_resumo        TO atendimento;

-- Teste 1 (deve FUNCIONAR): o atendimento consulta a view.
BEGIN;
SET LOCAL ROLE atendimento;
SELECT nome, numero, saldo FROM vw_contas_atendimento ORDER BY nome LIMIT 3;
ROLLBACK;

-- Teste 2 (deve DAR ERRO): o atendimento não pode ler a tabela cliente (CPF, senha_hash e renda).
-- BEGIN;
-- SET LOCAL ROLE atendimento;
-- SELECT cpf FROM cliente;
-- ROLLBACK;
-- Esperado: ERROR: permission denied for table cliente

-- Teste 3 (deve DAR ERRO): o atendimento não pode alterar saldos.
-- BEGIN;
-- SET LOCAL ROLE atendimento;
-- UPDATE conta SET saldo = 0;
-- ROLLBACK;
-- Esperado: ERROR: permission denied for table conta

-- REVOKE: retira o acesso ao extrato e confirma que deixou de funcionar.
REVOKE SELECT ON vw_extrato_resumo FROM atendimento;
-- BEGIN;
-- SET LOCAL ROLE atendimento;
-- SELECT * FROM vw_extrato_resumo;
-- ROLLBACK;
-- Esperado: ERROR: permission denied for view vw_extrato_resumo

-- ------------------------------------------------------------
-- Parte 3: TCL - Transações
-- Cenário: transferência entre contas. O débito e o crédito PRECISAM
-- acontecer juntos; se um falhar, o outro é desfeito (atomicidade).
-- Todos os blocos usam contas de teste e devolvem a base ao estado
-- original no Passo 7. As contas usadas: 1 (origem) e 3 (destino).
-- ------------------------------------------------------------

-- Conferência inicial dos saldos (anote os valores).
SELECT numero, saldo FROM conta WHERE id_conta IN (1, 3) ORDER BY id_conta;

-- Passo 1. SEM transação: dois Runs separados, como uma aplicação sem controle.
-- O Run 1 debita 1.000 da conta 1 e dá certo.
UPDATE conta SET saldo = saldo - 1000.00 WHERE id_conta = 1;

-- Run 2: falha antes de creditar o destino (aqui, simulado por um erro de CHECK).
-- UPDATE conta SET status = 'INEXISTENTE' WHERE id_conta = 3;
-- Esperado: violates check constraint "conta_status_check".
-- Resultado: o dinheiro SAIU da conta 1 e NÃO ENTROU na conta 3.

-- Passo 2. Auditoria: soma dos saldos das duas contas. Antes eram X; agora faltam R$ 1.000.
SELECT SUM(saldo) AS soma_atual FROM conta WHERE id_conta IN (1, 3);

-- Devolve o dinheiro para refazer o teste direito.
UPDATE conta SET saldo = saldo + 1000.00 WHERE id_conta = 1;

-- Passo 3. A MESMA falha, agora dentro de uma transação, num Run só.
-- A transação aborta inteira e o COMMIT vira ROLLBACK: a soma não muda.
-- BEGIN;
-- UPDATE conta SET saldo = saldo - 1000.00 WHERE id_conta = 1;
-- UPDATE conta SET status = 'INEXISTENTE' WHERE id_conta = 3;   -- erro
-- COMMIT;
-- Rode a auditoria do Passo 2 de novo: soma igual à inicial.

-- Passo 4. Transferência CORRETA: débito, crédito e lançamentos no extrato, tudo ou nada.
BEGIN;
UPDATE conta SET saldo = saldo - 1000.00 WHERE id_conta = 1 AND saldo >= 1000.00;
UPDATE conta SET saldo = saldo + 1000.00 WHERE id_conta = 3;
INSERT INTO transacao (id_conta, id_conta_destino, tipo, valor, descricao)
VALUES (1, 3, 'TRANSFERENCIA', 1000.00, 'Transferência de teste TCL');
COMMIT;

SELECT numero, saldo FROM conta WHERE id_conta IN (1, 3) ORDER BY id_conta;

-- Passo 5. ROLLBACK explícito: desfaz tudo o que foi feito desde o BEGIN.
BEGIN;
UPDATE conta SET saldo = saldo - 5000.00 WHERE id_conta = 1;
ROLLBACK;

SELECT numero, saldo FROM conta WHERE id_conta = 1;   -- o saldo não mudou

-- Passo 6. SAVEPOINT: desfaz só uma parte da transação.
-- O lançamento da tarifa entra, o PIX por engano volta ao ponto salvo e entra o valor certo.
BEGIN;
INSERT INTO transacao (id_conta, tipo, valor, descricao)
VALUES (1, 'TARIFA', 10.00, 'Tarifa de teste TCL');
SAVEPOINT apos_tarifa;
INSERT INTO transacao (id_conta, id_conta_destino, tipo, valor, descricao)
VALUES (1, 3, 'TRANSFERENCIA', 99999.00, 'Valor digitado errado TCL');
ROLLBACK TO SAVEPOINT apos_tarifa;
INSERT INTO transacao (id_conta, id_conta_destino, tipo, valor, descricao)
VALUES (1, 3, 'TRANSFERENCIA', 99.90, 'Valor corrigido TCL');
COMMIT;

-- Passo 7. Devolva a base ao estado anterior. A conferência deve dar 0.
-- (a transferência do Passo 4 moveu R$ 1.000 de 1 para 3: desfazemos aqui)
UPDATE conta SET saldo = saldo + 1000.00 WHERE id_conta = 1;
UPDATE conta SET saldo = saldo - 1000.00 WHERE id_conta = 3;
DELETE FROM transacao WHERE descricao LIKE '%TCL';

SELECT COUNT(*) FROM transacao WHERE descricao LIKE '%TCL';

-- ------------------------------------------------------------
-- Cuidados com subconsultas, views e transações (testes de "aposta")
-- ------------------------------------------------------------
-- A1. SELECT COUNT(*) FROM conta WHERE id_conta NOT IN
--       (SELECT id_conta_destino FROM transacao);
--     id_conta_destino é NULL nos lançamentos que não são transferência: NOT IN
--     com NULL na lista nunca é verdadeiro e devolve 0 linhas. Use NOT EXISTS (Q5).
-- A2. SELECT nome FROM cliente WHERE id_cliente =
--       (SELECT id_cliente FROM emprestimo WHERE status = 'EM_DIA');
--     Com = a subconsulta precisa devolver UMA linha; com várias dá erro
--     "more than one row returned by a subquery". Use IN (Q3).
-- A3. Antes: N lançamentos. Depois do Passo 3 (BEGIN, um UPDATE que dá certo,
--     um que dá erro, COMMIT), a soma dos saldos mudou? Não: o COMMIT vira ROLLBACK.
-- A view esconde colunas, mas só protege se o papel NÃO tiver GRANT na tabela.
-- Cada Run é um pedido novo: SET LOCAL ROLE só vale dentro do BEGIN ... ROLLBACK.
