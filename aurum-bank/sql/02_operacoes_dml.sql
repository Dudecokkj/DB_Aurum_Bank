-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Operações DML do dia a dia (valores ilustrativos)
-- Execute depois do 01_script_ddl.sql e do 01b_carga_dados.sql
-- (os ids usados abaixo precisam existir). Este script ALTERA os
-- dados; para repetir o teste do zero, rode 01 e 01b de novo.
-- ============================================================

-- ------------------------------------------------------------
-- Ordem de carga (com chaves estrangeiras ativas):
--   1) agencia, cliente, categoria_transacao
--   2) conta
--   3) conta_corrente, conta_poupanca, conta_titular
--   4) transacao, cartao, emprestimo
--   5) compra_cartao, parcela_emprestimo
-- O tipo_conta de cada registro em conta deve coincidir com
-- a tabela filha (CORRENTE -> conta_corrente, POUPANCA -> conta_poupanca).
-- ------------------------------------------------------------

-- INSERT: novo cliente e abertura da primeira conta corrente
INSERT INTO cliente (nome, email, senha_hash, cpf, data_nascimento, renda_mensal)
VALUES ('Maria Souza', 'maria@exemplo.com', '<hash>', '000.000.099-99', '1995-04-12', 5000.00);

-- O id da Maria é gerado pelo banco; por isso buscamos pelo e-mail
-- (em vez de escrever um número fixo que poderia ser de outra pessoa).
INSERT INTO conta (id_agencia, numero, tipo_conta)
VALUES ((SELECT id_agencia FROM agencia WHERE codigo = '0001'), '10099-0', 'CORRENTE');

INSERT INTO conta_corrente (id_conta, limite_cheque_especial, tarifa_mensal)
VALUES ((SELECT id_conta FROM conta WHERE numero = '10099-0'), 500.00, 19.90);

INSERT INTO conta_titular (id_conta, id_cliente, tipo_titular)
VALUES ((SELECT id_conta   FROM conta   WHERE numero = '10099-0'),
        (SELECT id_cliente FROM cliente WHERE email  = 'maria@exemplo.com'),
        'PRINCIPAL');

-- INSERT: primeiro depósito (o saldo é atualizado no UPDATE seguinte)
INSERT INTO transacao (id_conta, id_categoria, tipo, valor, descricao)
VALUES ((SELECT id_conta FROM conta WHERE numero = '10099-0'),
        (SELECT id_categoria FROM categoria_transacao WHERE nome_categoria = 'Salário'),
        'DEPOSITO', 1000.00, 'Depósito inicial');

-- UPDATE: refletir o depósito no saldo
UPDATE conta
SET saldo = saldo + 1000.00
WHERE numero = '10099-0';

-- UPDATE: aumentar o limite do cheque especial de quem tem boa renda
UPDATE conta_corrente
SET limite_cheque_especial = 3000.00
WHERE id_conta = (SELECT id_conta FROM conta WHERE numero = '10099-0');

-- UPDATE: bloquear um cartão por suspeita de fraude
UPDATE cartao
SET status = 'BLOQUEADO'
WHERE id_cartao = 1;

-- UPDATE: registrar o pagamento de uma parcela de empréstimo
UPDATE parcela_emprestimo
SET data_pagamento = CURRENT_DATE
WHERE id_emprestimo = 1
  AND numero_parcela = 13
  AND data_pagamento IS NULL;

-- DELETE: remover uma compra lançada em duplicidade (o WHERE é obrigatório)
DELETE FROM compra_cartao
WHERE id_compra = 20;

-- ------------------------------------------------------------
-- Efeito das regras de integridade (testes que devem FALHAR)
-- ------------------------------------------------------------
-- Valor inválido: rejeitado pelo CHECK (valor > 0)
-- INSERT INTO transacao (id_conta, tipo, valor) VALUES (1, 'DEPOSITO', -50);

-- Tipo de conta inválido: rejeitado pelo CHECK (CORRENTE ou POUPANCA)
-- INSERT INTO conta (id_agencia, numero, tipo_conta) VALUES (1, '99999-9', 'SALARIO');

-- Transferência sem destino: rejeitada pelo CHECK da tabela transacao
-- INSERT INTO transacao (id_conta, tipo, valor) VALUES (1, 'TRANSFERENCIA', 100);

-- Conta com movimentação: o histórico financeiro é protegido (RESTRICT)
-- DELETE FROM conta WHERE id_conta = 1;

-- Cliente com empréstimo: a dívida não some com o cadastro (RESTRICT)
-- DELETE FROM cliente WHERE id_cliente = 3;

-- Exclusão de um cliente SEM dívida nem conta: remove em cascata titularidades
-- e cartões (atende pedidos de eliminação de dados da LGPD)
-- DELETE FROM cliente WHERE id_cliente = 12;

-- ------------------------------------------------------------
-- Cenário de concorrência: dois saques ao mesmo tempo na mesma conta
-- A transação trava a linha da conta antes de decidir; a outra espera o
-- COMMIT e já enxerga o saldo atualizado (evita saldo negativo indevido).
-- ------------------------------------------------------------
BEGIN;

SELECT saldo
FROM conta
WHERE id_conta = 7
FOR UPDATE;          -- a outra transação espera aqui

UPDATE conta
SET saldo = saldo - 500.00
WHERE id_conta = 7
  AND saldo >= 500.00;       -- só debita se ainda houver saldo

INSERT INTO transacao (id_conta, id_categoria, tipo, valor, descricao)
VALUES (7, NULL, 'SAQUE', 500.00, 'Saque em caixa eletrônico');

COMMIT;
