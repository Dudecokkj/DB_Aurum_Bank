-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Carga de dados de exemplo (fictícios) para o banco inteiro
-- Execute DEPOIS do 01_script_ddl.sql e ANTES de todos os outros.
-- Pode ser reexecutado: limpa as tabelas e recarrega tudo.
-- Os saldos das contas foram calculados a partir do extrato
-- (soma dos lançamentos), então saldo e transações batem.
-- Data de referência dos dados: 16/11/2026.
-- Os dados pensados para que TODAS as consultas dos arquivos
-- 03, 04 e 05 devolvam linhas (inclusive NULLs, cliente sem conta,
-- empréstimo atrasado, conta conjunta etc.).
-- ============================================================

BEGIN;

TRUNCATE TABLE parcela_emprestimo, emprestimo, compra_cartao, cartao, transacao,
               categoria_transacao, conta_titular, conta_poupanca, conta_corrente,
               conta, cliente, agencia
RESTART IDENTITY CASCADE;

-- 1) agencia, cliente, categoria_transacao

INSERT INTO agencia (id_agencia, codigo, nome, cidade, uf) VALUES
    (1, '0001', 'Agência Centro', 'São Paulo', 'SP'),
    (2, '0002', 'Agência Paulista', 'São Paulo', 'SP'),
    (3, '0003', 'Agência São Bernardo', 'São Bernardo do Campo', 'SP'),
    (4, '0004', 'Agência Campinas', 'Campinas', 'SP');

INSERT INTO cliente (id_cliente, nome, email, senha_hash, cpf, data_nascimento, renda_mensal, data_cadastro) VALUES
    (1, 'Ana Beatriz Lima', 'ana.lima@exemplo.com', '$2b$12$hashficticio000000000000000001', '000.000.001-01', '1992-03-14', 8500.00, '2024-02-10 09:15:00'),
    (2, 'Bruno Carvalho', 'bruno.carvalho@exemplo.com', '$2b$12$hashficticio000000000000000002', '000.000.002-02', '1988-07-21', 12000.00, '2024-02-28 18:40:00'),
    (3, 'Carla Mendes', 'carla.mendes@exemplo.com', '$2b$12$hashficticio000000000000000003', '000.000.003-03', '1995-11-05', 6200.00, '2024-06-10 21:05:00'),
    (4, 'Diego Ferreira', 'diego.ferreira@exemplo.com', '$2b$12$hashficticio000000000000000004', '000.000.004-04', '1985-01-30', 15000.00, '2024-09-15 14:22:00'),
    (5, 'Eduarda Rocha', 'eduarda.rocha@exemplo.com', '$2b$12$hashficticio000000000000000005', '000.000.005-05', '1999-04-17', 4300.00, '2025-01-10 10:00:00'),
    (6, 'Felipe Santos', 'felipe.santos@exemplo.com', '$2b$12$hashficticio000000000000000006', '000.000.006-06', '1997-08-09', 5800.00, '2025-02-01 19:30:00'),
    (7, 'Gabriela Alves', 'gabriela.alves@exemplo.com', '$2b$12$hashficticio000000000000000007', '000.000.007-07', '1990-12-25', 9800.00, '2025-03-15 08:45:00'),
    (8, 'Henrique Costa', 'henrique.costa@exemplo.com', '$2b$12$hashficticio000000000000000008', '000.000.008-08', '1983-05-02', 7200.00, '2024-03-28 16:10:00'),
    (9, 'Isabela Martins', 'isabela.martins@exemplo.com', '$2b$12$hashficticio000000000000000009', '000.000.009-09', '1994-10-11', NULL, '2025-07-05 11:25:00'),
    (10, 'João Pedro Nunes', 'joao.nunes@exemplo.com', '$2b$12$hashficticio000000000000000010', '000.000.010-10', '2001-09-30', 3100.00, '2026-05-20 20:00:00'),
    (11, 'Karina Duarte', 'karina.duarte@exemplo.com', '$2b$12$hashficticio000000000000000011', '000.000.011-11', '2003-06-19', 2500.00, '2026-08-14 13:50:00'),
    (12, 'Lucas Ribeiro', 'lucas.ribeiro@exemplo.com', '$2b$12$hashficticio000000000000000012', '000.000.012-12', '2004-11-02', NULL, '2026-10-30 22:15:00');

INSERT INTO categoria_transacao (id_categoria, nome_categoria, descricao) VALUES
    (1, 'Salário', 'Entradas de salário e proventos'),
    (2, 'Alimentação', 'Mercado, restaurantes e delivery'),
    (3, 'Moradia', 'Aluguel, condomínio e contas da casa'),
    (4, 'Transporte', 'Combustível, aplicativos e transporte público'),
    (5, 'Lazer', 'Cinema, viagens e assinaturas'),
    (6, 'Saúde', 'Farmácia, consultas e planos'),
    (7, 'Educação', 'Mensalidades e cursos'),
    (8, 'Investimento', 'Aplicações e resgates'),
    (9, 'Tarifas', 'Tarifas bancárias');


-- ------------------------------------------------------------
-- 2) conta, conta_corrente, conta_poupanca, conta_titular
-- ------------------------------------------------------------

INSERT INTO conta (id_conta, id_agencia, numero, saldo, data_abertura, status, tipo_conta) VALUES
    (1, 1, '10001-5', 16519.60, '2024-02-10', 'ATIVA', 'CORRENTE'),
    (2, 1, '10002-3', 8000.00, '2024-03-01', 'ATIVA', 'POUPANCA'),
    (3, 1, '10003-1', 23500.10, '2024-02-28', 'ATIVA', 'CORRENTE'),
    (4, 2, '20001-7', 10559.80, '2024-06-10', 'ATIVA', 'CORRENTE'),
    (5, 2, '20002-5', 26000.00, '2024-09-15', 'ATIVA', 'POUPANCA'),
    (6, 2, '20003-2', 23760.10, '2024-09-15', 'ATIVA', 'CORRENTE'),
    (7, 3, '30001-9', 6479.40, '2025-01-10', 'ATIVA', 'CORRENTE'),
    (8, 3, '30002-6', 2800.00, '2025-02-01', 'ATIVA', 'POUPANCA'),
    (9, 3, '30003-4', 8980.10, '2025-02-01', 'ATIVA', 'CORRENTE'),
    (10, 1, '10004-9', 18120.10, '2025-03-15', 'ATIVA', 'CORRENTE'),
    (11, 2, '20004-0', 5000.00, '2024-03-28', 'BLOQUEADA', 'CORRENTE'),
    (12, 1, '10005-7', 3850.00, '2025-07-05', 'ATIVA', 'POUPANCA'),
    (13, 3, '30004-2', 5785.10, '2026-05-20', 'ATIVA', 'CORRENTE'),
    (14, 2, '20005-8', 0.00, '2026-08-14', 'ENCERRADA', 'CORRENTE'),
    (15, 3, '30005-0', 0.00, '2026-11-10', 'ATIVA', 'CORRENTE');

INSERT INTO conta_corrente (id_conta, limite_cheque_especial, tarifa_mensal) VALUES
    (1, 2000.00, 29.90),
    (3, 5000.00, 29.90),
    (4, 1500.00, 19.90),
    (6, 8000.00, 39.90),
    (7, 1000.00, 19.90),
    (9, 1500.00, 19.90),
    (10, 3000.00, 29.90),
    (11, 2000.00, 29.90),
    (13, 500.00, 19.90),
    (14, 0.00, 0.00),
    (15, 300.00, 19.90);

INSERT INTO conta_poupanca (id_conta, taxa_rendimento_mensal, dia_aniversario) VALUES
    (2, 0.0050, 5),
    (5, 0.0050, 15),
    (8, 0.0045, 15),
    (12, 0.0050, 20);

INSERT INTO conta_titular (id_conta, id_cliente, tipo_titular, data_vinculo) VALUES
    (1, 1, 'PRINCIPAL', '2024-02-10'),
    (2, 1, 'PRINCIPAL', '2024-03-01'),
    (3, 2, 'PRINCIPAL', '2024-02-28'),
    (4, 3, 'PRINCIPAL', '2024-06-10'),
    (5, 4, 'PRINCIPAL', '2024-09-15'),
    (6, 4, 'PRINCIPAL', '2024-09-15'),
    (7, 5, 'PRINCIPAL', '2025-01-10'),
    (8, 6, 'PRINCIPAL', '2025-02-01'),
    (9, 6, 'PRINCIPAL', '2025-02-01'),
    (10, 7, 'PRINCIPAL', '2025-03-15'),
    (11, 8, 'PRINCIPAL', '2024-03-28'),
    (12, 9, 'PRINCIPAL', '2025-07-05'),
    (13, 10, 'PRINCIPAL', '2026-05-20'),
    (14, 11, 'PRINCIPAL', '2026-08-14'),
    (15, 10, 'PRINCIPAL', '2026-11-10'),
    (3, 3, 'CONJUNTO', '2025-05-20'),
    (1, 2, 'CONJUNTO', '2025-05-20');


-- ------------------------------------------------------------
-- 3) transacao (extrato)
-- ------------------------------------------------------------

INSERT INTO transacao (id_conta, id_conta_destino, id_categoria, tipo, valor, data_hora, descricao) VALUES
    (5, NULL, 8, 'DEPOSITO', 20000.00, '2026-08-10 09:00:00', 'Aporte poupança'),
    (14, NULL, 1, 'DEPOSITO', 500.00, '2026-08-20 09:00:00', 'Depósito inicial'),
    (2, NULL, 8, 'DEPOSITO', 5000.00, '2026-09-01 10:00:00', 'Aporte inicial poupança'),
    (1, NULL, 1, 'DEPOSITO', 8500.00, '2026-09-05 08:00:00', 'Salário setembro'),
    (3, NULL, 1, 'DEPOSITO', 12000.00, '2026-09-05 08:00:00', 'Salário setembro'),
    (11, NULL, 1, 'DEPOSITO', 7200.00, '2026-09-05 08:00:00', 'Salário setembro'),
    (11, NULL, 3, 'PAGAMENTO', 2200.00, '2026-09-10 10:00:00', 'Aluguel setembro'),
    (8, NULL, 8, 'DEPOSITO', 2000.00, '2026-09-15 09:00:00', 'Aporte poupança'),
    (12, NULL, 8, 'DEPOSITO', 3500.00, '2026-09-20 09:00:00', 'Aporte poupança'),
    (14, NULL, 1, 'SAQUE', 500.00, '2026-09-20 09:00:00', 'Saque total para encerramento'),
    (1, NULL, 1, 'DEPOSITO', 8500.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (3, NULL, 1, 'DEPOSITO', 12000.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (4, NULL, 1, 'DEPOSITO', 6200.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (6, NULL, 1, 'DEPOSITO', 15000.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (7, NULL, 1, 'DEPOSITO', 4300.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (9, NULL, 1, 'DEPOSITO', 5800.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (10, NULL, 1, 'DEPOSITO', 9800.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (13, NULL, 1, 'DEPOSITO', 3100.00, '2026-10-05 08:00:00', 'Salário outubro'),
    (1, 2, 8, 'TRANSFERENCIA', 1500.00, '2026-10-06 09:00:00', 'Reserva mensal para poupança'),
    (3, NULL, 3, 'PAGAMENTO', 3800.00, '2026-10-08 11:00:00', 'Financiamento imobiliário'),
    (1, NULL, 3, 'PAGAMENTO', 2400.00, '2026-10-10 10:30:00', 'Aluguel outubro'),
    (3, NULL, 7, 'PAGAMENTO', 1450.00, '2026-10-12 15:00:00', 'Mensalidade escolar'),
    (5, NULL, 8, 'DEPOSITO', 3000.00, '2026-10-15 09:00:00', 'Aporte poupança'),
    (6, 5, 8, 'TRANSFERENCIA', 3000.00, '2026-10-15 09:00:00', 'Aporte poupança'),
    (1, NULL, 2, 'PAGAMENTO', 640.50, '2026-10-18 19:20:00', 'Supermercado'),
    (3, NULL, 5, 'PAGAMENTO', 890.00, '2026-10-25 21:15:00', 'Viagem de fim de semana'),
    (1, NULL, 9, 'TARIFA', 29.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (3, NULL, 9, 'TARIFA', 29.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (4, NULL, 9, 'TARIFA', 19.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (6, NULL, 9, 'TARIFA', 39.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (7, NULL, 9, 'TARIFA', 19.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (9, NULL, 9, 'TARIFA', 19.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (10, NULL, 9, 'TARIFA', 29.90, '2026-11-01 00:05:00', 'Tarifa mensal de conta'),
    (1, NULL, 4, 'PAGAMENTO', 210.00, '2026-11-02 07:45:00', 'Combustível'),
    (3, 4, NULL, 'TRANSFERENCIA', 600.00, '2026-11-03 14:30:00', 'Divisão de despesas'),
    (1, NULL, 1, 'DEPOSITO', 8500.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (3, NULL, 1, 'DEPOSITO', 12000.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (4, NULL, 1, 'DEPOSITO', 6200.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (6, NULL, 1, 'DEPOSITO', 15000.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (7, NULL, 1, 'DEPOSITO', 4300.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (9, NULL, 1, 'DEPOSITO', 5800.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (10, NULL, 1, 'DEPOSITO', 9800.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (13, NULL, 1, 'DEPOSITO', 3100.00, '2026-11-05 08:00:00', 'Salário novembro'),
    (1, 2, 8, 'TRANSFERENCIA', 1500.00, '2026-11-06 09:00:00', 'Reserva mensal para poupança'),
    (9, 8, 8, 'TRANSFERENCIA', 800.00, '2026-11-06 09:00:00', 'Reserva mensal para poupança'),
    (4, NULL, 3, 'PAGAMENTO', 1900.00, '2026-11-07 10:00:00', 'Aluguel novembro'),
    (7, NULL, 3, 'PAGAMENTO', 1500.00, '2026-11-08 10:00:00', 'Aluguel novembro'),
    (9, NULL, 3, 'PAGAMENTO', 1800.00, '2026-11-08 10:00:00', 'Aluguel novembro'),
    (3, NULL, 3, 'PAGAMENTO', 3800.00, '2026-11-08 11:00:00', 'Financiamento imobiliário'),
    (3, NULL, 6, 'PAGAMENTO', 480.00, '2026-11-09 09:40:00', 'Plano de saúde'),
    (10, NULL, 2, 'PAGAMENTO', 1100.00, '2026-11-09 19:00:00', 'Compras do mês'),
    (13, NULL, 4, 'PAGAMENTO', 280.00, '2026-11-10 07:30:00', 'Transporte'),
    (1, NULL, 3, 'PAGAMENTO', 2400.00, '2026-11-10 10:30:00', 'Aluguel novembro'),
    (7, NULL, 2, 'PAGAMENTO', 410.80, '2026-11-10 13:20:00', 'Restaurante e delivery'),
    (10, 12, NULL, 'TRANSFERENCIA', 350.00, '2026-11-11 16:00:00', 'Presente de aniversário'),
    (4, NULL, 2, 'PAGAMENTO', 520.30, '2026-11-11 20:10:00', 'Supermercado'),
    (1, NULL, 2, 'SAQUE', 300.00, '2026-11-12 12:10:00', 'Saque em caixa eletrônico'),
    (3, NULL, 7, 'PAGAMENTO', 1450.00, '2026-11-12 15:00:00', 'Mensalidade escolar'),
    (7, NULL, 4, 'PAGAMENTO', 189.90, '2026-11-13 08:00:00', 'Transporte por aplicativo'),
    (6, NULL, 5, 'PAGAMENTO', 3200.00, '2026-11-14 18:00:00', 'Passagens aéreas'),
    (13, NULL, 5, 'PAGAMENTO', 134.90, '2026-11-14 22:00:00', 'Assinaturas de streaming e jogos');


-- ------------------------------------------------------------
-- 4) cartao, compra_cartao
-- ------------------------------------------------------------

INSERT INTO cartao (id_cartao, id_conta, id_cliente, numero_final, bandeira, limite_credito, validade, status) VALUES
    (1, 1, 1, '4821', 'VISA', 6000.00, '2029-08-31', 'ATIVO'),
    (2, 3, 2, '1190', 'MASTERCARD', 15000.00, '2030-02-28', 'ATIVO'),
    (3, 4, 3, '7755', 'VISA', 4500.00, '2029-05-31', 'ATIVO'),
    (4, 6, 4, '3021', 'MASTERCARD', 25000.00, '2030-09-30', 'ATIVO'),
    (5, 7, 5, '9916', 'ELO', 3000.00, '2029-12-31', 'ATIVO'),
    (6, 10, 7, '6402', 'VISA', 9000.00, '2030-03-31', 'BLOQUEADO'),
    (7, 9, 6, '5538', 'MASTERCARD', 4000.00, '2029-10-31', 'ATIVO'),
    (8, 13, 10, '2284', 'VISA', 1500.00, '2031-05-31', 'ATIVO'),
    (9, 11, 8, '8847', 'ELO', 5000.00, '2028-03-31', 'CANCELADO');

INSERT INTO compra_cartao (id_cartao, estabelecimento, valor, parcelas, data_compra) VALUES
    (1, 'Livraria Horizonte', 189.90, 1, '2026-10-14 15:20:00'),
    (1, 'Eletrônicos Prisma', 2400.00, 10, '2026-10-28 11:05:00'),
    (1, 'Restaurante Sabor da Terra', 142.80, 1, '2026-11-08 21:40:00'),
    (2, 'Colégio Aurora', 1450.00, 1, '2026-11-12 09:00:00'),
    (2, 'Mobiliária Lar Feliz', 5400.00, 12, '2026-09-20 16:30:00'),
    (2, 'Supermercado Bom Preço', 830.40, 1, '2026-11-10 18:10:00'),
    (3, 'Farmácia Vida', 215.60, 2, '2026-11-03 10:15:00'),
    (3, 'Posto Estrada Real', 250.00, 1, '2026-11-09 07:55:00'),
    (4, 'Agência Voo Livre', 3200.00, 6, '2026-11-14 18:00:00'),
    (4, 'Hotel Praia Azul', 4800.00, 8, '2026-11-14 18:30:00'),
    (4, 'Restaurante Mar & Brasa', 620.00, 1, '2026-11-06 20:45:00'),
    (4, 'Eletrônicos Prisma', 7900.00, 12, '2026-08-30 13:00:00'),
    (5, 'Cinema Central', 96.00, 1, '2026-11-01 19:30:00'),
    (5, 'Loja de Roupas Estilo', 480.00, 3, '2026-10-22 17:10:00'),
    (6, 'Academia Corpo Ativo', 2400.00, 12, '2026-08-05 08:00:00'),
    (7, 'Pet Shop Amigo Fiel', 310.00, 1, '2026-11-11 15:05:00'),
    (7, 'Supermercado Bom Preço', 590.70, 1, '2026-11-05 19:00:00'),
    (8, 'Loja de Games Pixel', 899.00, 3, '2026-11-15 20:20:00'),
    (9, 'Livraria Horizonte', 120.00, 1, '2026-02-10 14:00:00'),
    (2, 'Clínica Bem-Estar', 680.00, 2, '2026-10-02 10:00:00');


-- ------------------------------------------------------------
-- 5) emprestimo, parcela_emprestimo
-- (parcelas pela Tabela Price; ATRASADO = parcela vencida e não paga)
-- ------------------------------------------------------------

INSERT INTO emprestimo (id_emprestimo, id_cliente, id_conta, valor_contratado, taxa_juros_mensal, qtd_parcelas, data_contratacao, status) VALUES
    (1, 3, 3, 30000.00, 0.0189, 24, '2025-11-10', 'EM_DIA'),
    (2, 4, 6, 12000.00, 0.0210, 12, '2026-03-05', 'EM_DIA'),
    (3, 6, 9, 5000.00, 0.0175, 6, '2026-01-15', 'QUITADO'),
    (4, 7, 10, 20000.00, 0.0199, 36, '2026-06-20', 'EM_DIA'),
    (5, 8, 11, 8000.00, 0.0230, 12, '2025-10-01', 'ATRASADO'),
    (6, 1, 1, 15000.00, 0.0185, 18, '2026-04-10', 'EM_DIA');

INSERT INTO parcela_emprestimo (id_emprestimo, numero_parcela, valor_parcela, data_vencimento, data_pagamento) VALUES
    (1, 1, 1566.44, '2025-12-10', '2025-12-09'),
    (1, 2, 1566.44, '2026-01-10', '2026-01-08'),
    (1, 3, 1566.44, '2026-02-10', '2026-02-10'),
    (1, 4, 1566.44, '2026-03-10', '2026-03-09'),
    (1, 5, 1566.44, '2026-04-10', '2026-04-08'),
    (1, 6, 1566.44, '2026-05-10', '2026-05-10'),
    (1, 7, 1566.44, '2026-06-10', '2026-06-09'),
    (1, 8, 1566.44, '2026-07-10', '2026-07-08'),
    (1, 9, 1566.44, '2026-08-10', '2026-08-10'),
    (1, 10, 1566.44, '2026-09-10', '2026-09-09'),
    (1, 11, 1566.44, '2026-10-10', '2026-10-08'),
    (1, 12, 1566.44, '2026-11-10', '2026-11-10'),
    (1, 13, 1566.44, '2026-12-10', NULL),
    (1, 14, 1566.44, '2027-01-10', NULL),
    (1, 15, 1566.44, '2027-02-10', NULL),
    (1, 16, 1566.44, '2027-03-10', NULL),
    (1, 17, 1566.44, '2027-04-10', NULL),
    (1, 18, 1566.44, '2027-05-10', NULL),
    (1, 19, 1566.44, '2027-06-10', NULL),
    (1, 20, 1566.44, '2027-07-10', NULL),
    (1, 21, 1566.44, '2027-08-10', NULL),
    (1, 22, 1566.44, '2027-09-10', NULL),
    (1, 23, 1566.44, '2027-10-10', NULL),
    (1, 24, 1566.44, '2027-11-10', NULL),
    (2, 1, 1141.70, '2026-04-05', '2026-04-04'),
    (2, 2, 1141.70, '2026-05-05', '2026-05-03'),
    (2, 3, 1141.70, '2026-06-05', '2026-06-05'),
    (2, 4, 1141.70, '2026-07-05', '2026-07-04'),
    (2, 5, 1141.70, '2026-08-05', '2026-08-03'),
    (2, 6, 1141.70, '2026-09-05', '2026-09-05'),
    (2, 7, 1141.70, '2026-10-05', '2026-10-04'),
    (2, 8, 1141.70, '2026-11-05', '2026-11-03'),
    (2, 9, 1141.70, '2026-12-05', NULL),
    (2, 10, 1141.70, '2027-01-05', NULL),
    (2, 11, 1141.70, '2027-02-05', NULL),
    (2, 12, 1141.70, '2027-03-05', NULL),
    (3, 1, 885.11, '2026-02-15', '2026-02-14'),
    (3, 2, 885.11, '2026-03-15', '2026-03-13'),
    (3, 3, 885.11, '2026-04-15', '2026-04-15'),
    (3, 4, 885.11, '2026-05-15', '2026-05-14'),
    (3, 5, 885.11, '2026-06-15', '2026-06-13'),
    (3, 6, 885.11, '2026-07-15', '2026-07-15'),
    (4, 1, 783.40, '2026-07-20', '2026-07-19'),
    (4, 2, 783.40, '2026-08-20', '2026-08-18'),
    (4, 3, 783.40, '2026-09-20', '2026-09-20'),
    (4, 4, 783.40, '2026-10-20', '2026-10-19'),
    (4, 5, 783.40, '2026-11-20', NULL),
    (4, 6, 783.40, '2026-12-20', NULL),
    (4, 7, 783.40, '2027-01-20', NULL),
    (4, 8, 783.40, '2027-02-20', NULL),
    (4, 9, 783.40, '2027-03-20', NULL),
    (4, 10, 783.40, '2027-04-20', NULL),
    (4, 11, 783.40, '2027-05-20', NULL),
    (4, 12, 783.40, '2027-06-20', NULL),
    (4, 13, 783.40, '2027-07-20', NULL),
    (4, 14, 783.40, '2027-08-20', NULL),
    (4, 15, 783.40, '2027-09-20', NULL),
    (4, 16, 783.40, '2027-10-20', NULL),
    (4, 17, 783.40, '2027-11-20', NULL),
    (4, 18, 783.40, '2027-12-20', NULL),
    (4, 19, 783.40, '2028-01-20', NULL),
    (4, 20, 783.40, '2028-02-20', NULL),
    (4, 21, 783.40, '2028-03-20', NULL),
    (4, 22, 783.40, '2028-04-20', NULL),
    (4, 23, 783.40, '2028-05-20', NULL),
    (4, 24, 783.40, '2028-06-20', NULL),
    (4, 25, 783.40, '2028-07-20', NULL),
    (4, 26, 783.40, '2028-08-20', NULL),
    (4, 27, 783.40, '2028-09-20', NULL),
    (4, 28, 783.40, '2028-10-20', NULL),
    (4, 29, 783.40, '2028-11-20', NULL),
    (4, 30, 783.40, '2028-12-20', NULL),
    (4, 31, 783.40, '2029-01-20', NULL),
    (4, 32, 783.40, '2029-02-20', NULL),
    (4, 33, 783.40, '2029-03-20', NULL),
    (4, 34, 783.40, '2029-04-20', NULL),
    (4, 35, 783.40, '2029-05-20', NULL),
    (4, 36, 783.40, '2029-06-20', NULL),
    (5, 1, 770.48, '2025-11-01', '2025-10-31'),
    (5, 2, 770.48, '2025-12-01', '2025-11-29'),
    (5, 3, 770.48, '2026-01-01', '2026-01-01'),
    (5, 4, 770.48, '2026-02-01', '2026-01-31'),
    (5, 5, 770.48, '2026-03-01', NULL),
    (5, 6, 770.48, '2026-04-01', NULL),
    (5, 7, 770.48, '2026-05-01', NULL),
    (5, 8, 770.48, '2026-06-01', NULL),
    (5, 9, 770.48, '2026-07-01', NULL),
    (5, 10, 770.48, '2026-08-01', NULL),
    (5, 11, 770.48, '2026-09-01', NULL),
    (5, 12, 770.48, '2026-10-01', NULL),
    (6, 1, 987.38, '2026-05-10', '2026-05-09'),
    (6, 2, 987.38, '2026-06-10', '2026-06-08'),
    (6, 3, 987.38, '2026-07-10', '2026-07-10'),
    (6, 4, 987.38, '2026-08-10', '2026-08-09'),
    (6, 5, 987.38, '2026-09-10', '2026-09-08'),
    (6, 6, 987.38, '2026-10-10', '2026-10-10'),
    (6, 7, 987.38, '2026-11-10', '2026-11-09'),
    (6, 8, 987.38, '2026-12-10', NULL),
    (6, 9, 987.38, '2027-01-10', NULL),
    (6, 10, 987.38, '2027-02-10', NULL),
    (6, 11, 987.38, '2027-03-10', NULL),
    (6, 12, 987.38, '2027-04-10', NULL),
    (6, 13, 987.38, '2027-05-10', NULL),
    (6, 14, 987.38, '2027-06-10', NULL),
    (6, 15, 987.38, '2027-07-10', NULL),
    (6, 16, 987.38, '2027-08-10', NULL),
    (6, 17, 987.38, '2027-09-10', NULL),
    (6, 18, 987.38, '2027-10-10', NULL);


-- ------------------------------------------------------------
-- 6) Acerta os contadores (SERIAL) depois de inserir ids fixos
-- ------------------------------------------------------------
SELECT setval(pg_get_serial_sequence('agencia',             'id_agencia'),   (SELECT MAX(id_agencia)   FROM agencia));
SELECT setval(pg_get_serial_sequence('cliente',             'id_cliente'),   (SELECT MAX(id_cliente)   FROM cliente));
SELECT setval(pg_get_serial_sequence('conta',               'id_conta'),     (SELECT MAX(id_conta)     FROM conta));
SELECT setval(pg_get_serial_sequence('categoria_transacao', 'id_categoria'), (SELECT MAX(id_categoria) FROM categoria_transacao));
SELECT setval(pg_get_serial_sequence('transacao',           'id_transacao'), (SELECT MAX(id_transacao) FROM transacao));
SELECT setval(pg_get_serial_sequence('cartao',              'id_cartao'),    (SELECT MAX(id_cartao)    FROM cartao));
SELECT setval(pg_get_serial_sequence('compra_cartao',       'id_compra'),    (SELECT MAX(id_compra)    FROM compra_cartao));
SELECT setval(pg_get_serial_sequence('emprestimo',          'id_emprestimo'),(SELECT MAX(id_emprestimo)FROM emprestimo));
SELECT setval(pg_get_serial_sequence('parcela_emprestimo',  'id_parcela'),   (SELECT MAX(id_parcela)   FROM parcela_emprestimo));

COMMIT;
