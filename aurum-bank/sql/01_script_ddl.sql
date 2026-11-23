-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Projeto A3 - Banco de Dados | SGBD: PostgreSQL
-- Script DDL: remove e recria todas as tabelas (reexecutável)
-- ============================================================

-- ------------------------------------------------------------
-- 1) REMOÇÃO (ordem inversa de dependência)
-- ------------------------------------------------------------
DROP TABLE IF EXISTS parcela_emprestimo CASCADE;
DROP TABLE IF EXISTS emprestimo         CASCADE;
DROP TABLE IF EXISTS compra_cartao      CASCADE;
DROP TABLE IF EXISTS cartao             CASCADE;
DROP TABLE IF EXISTS transacao          CASCADE;
DROP TABLE IF EXISTS categoria_transacao CASCADE;
DROP TABLE IF EXISTS conta_titular      CASCADE;
DROP TABLE IF EXISTS conta_poupanca     CASCADE;
DROP TABLE IF EXISTS conta_corrente     CASCADE;
DROP TABLE IF EXISTS conta              CASCADE;
DROP TABLE IF EXISTS cliente            CASCADE;
DROP TABLE IF EXISTS agencia            CASCADE;

-- ------------------------------------------------------------
-- 2) CRIAÇÃO (ordem de dependência)
-- ------------------------------------------------------------

-- Unidades físicas do banco
CREATE TABLE agencia (
    id_agencia  SERIAL PRIMARY KEY,
    codigo      VARCHAR(4)   NOT NULL UNIQUE,        -- número da agência (ex.: 0001)
    nome        VARCHAR(100) NOT NULL,
    cidade      VARCHAR(80)  NOT NULL,
    uf          CHAR(2)      NOT NULL
);

-- Cadastro do cliente do banco
CREATE TABLE cliente (
    id_cliente      SERIAL PRIMARY KEY,
    nome            VARCHAR(150) NOT NULL,
    email           VARCHAR(150) NOT NULL UNIQUE,
    senha_hash      VARCHAR(255) NOT NULL,           -- somente hash, nunca a senha
    cpf             VARCHAR(14)  NOT NULL UNIQUE,
    data_nascimento DATE         NOT NULL,
    renda_mensal    DECIMAL(12,2) CHECK (renda_mensal >= 0),  -- NULL = não informada
    data_cadastro   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Supertipo das contas (corrente e poupança)
CREATE TABLE conta (
    id_conta      SERIAL PRIMARY KEY,
    id_agencia    INT           NOT NULL,
    numero        VARCHAR(10)   NOT NULL UNIQUE,     -- número da conta com dígito (ex.: 10001-5)
    saldo         DECIMAL(14,2) NOT NULL DEFAULT 0,
    data_abertura DATE          NOT NULL DEFAULT CURRENT_DATE,
    status        VARCHAR(20)   NOT NULL DEFAULT 'ATIVA'
        CHECK (status IN ('ATIVA', 'BLOQUEADA', 'ENCERRADA')),
    tipo_conta    VARCHAR(20)   NOT NULL
        CHECK (tipo_conta IN ('CORRENTE', 'POUPANCA')),
    FOREIGN KEY (id_agencia) REFERENCES agencia(id_agencia)
        ON DELETE RESTRICT                           -- agência com contas não pode sumir
);

-- Subtipo: dados exclusivos de conta corrente (reaproveita a chave de conta)
CREATE TABLE conta_corrente (
    id_conta       INT PRIMARY KEY
        REFERENCES conta(id_conta) ON DELETE CASCADE,
    limite_cheque_especial DECIMAL(12,2) NOT NULL DEFAULT 0 CHECK (limite_cheque_especial >= 0),
    tarifa_mensal          DECIMAL(8,2)  NOT NULL DEFAULT 0 CHECK (tarifa_mensal >= 0)
);

-- Subtipo: dados exclusivos de poupança (reaproveita a chave de conta)
CREATE TABLE conta_poupanca (
    id_conta               INT PRIMARY KEY
        REFERENCES conta(id_conta) ON DELETE CASCADE,
    taxa_rendimento_mensal DECIMAL(5,4) NOT NULL CHECK (taxa_rendimento_mensal >= 0),
    dia_aniversario        INT          NOT NULL CHECK (dia_aniversario BETWEEN 1 AND 28)
);

-- Associativa N:N entre cliente e conta (permite conta conjunta)
CREATE TABLE conta_titular (
    id_conta      INT         NOT NULL,
    id_cliente    INT         NOT NULL,
    tipo_titular  VARCHAR(20) NOT NULL DEFAULT 'PRINCIPAL'
        CHECK (tipo_titular IN ('PRINCIPAL', 'CONJUNTO')),
    data_vinculo  DATE        NOT NULL DEFAULT CURRENT_DATE,
    PRIMARY KEY (id_conta, id_cliente),
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
        ON DELETE CASCADE,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
);

-- Classificação das movimentações (alimentação, salário, moradia...)
CREATE TABLE categoria_transacao (
    id_categoria   SERIAL PRIMARY KEY,
    nome_categoria VARCHAR(50) NOT NULL UNIQUE,
    descricao      TEXT
);

-- Extrato: cada movimentação de uma conta
CREATE TABLE transacao (
    id_transacao     SERIAL PRIMARY KEY,
    id_conta         INT           NOT NULL,         -- conta dona do lançamento
    id_conta_destino INT,                            -- só preenchido em TRANSFERENCIA
    id_categoria     INT,
    tipo             VARCHAR(20)   NOT NULL
        CHECK (tipo IN ('DEPOSITO', 'SAQUE', 'TRANSFERENCIA', 'PAGAMENTO', 'TARIFA')),
    valor            DECIMAL(14,2) NOT NULL CHECK (valor > 0),
    data_hora        TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    descricao        VARCHAR(200),
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
        ON DELETE RESTRICT,                          -- protege o histórico financeiro
    FOREIGN KEY (id_conta_destino) REFERENCES conta(id_conta)
        ON DELETE RESTRICT,
    FOREIGN KEY (id_categoria) REFERENCES categoria_transacao(id_categoria)
        ON DELETE SET NULL,
    CHECK (tipo <> 'TRANSFERENCIA' OR id_conta_destino IS NOT NULL),
    CHECK (id_conta_destino IS NULL OR id_conta_destino <> id_conta)
);

-- Cartão de crédito vinculado a uma conta corrente e a um cliente
CREATE TABLE cartao (
    id_cartao      SERIAL PRIMARY KEY,
    id_conta       INT           NOT NULL,
    id_cliente     INT           NOT NULL,
    numero_final   CHAR(4)       NOT NULL,           -- somente os 4 últimos dígitos (PCI/LGPD)
    bandeira       VARCHAR(20)   NOT NULL,
    limite_credito DECIMAL(12,2) NOT NULL CHECK (limite_credito >= 0),
    validade       DATE          NOT NULL,
    status         VARCHAR(20)   NOT NULL DEFAULT 'ATIVO'
        CHECK (status IN ('ATIVO', 'BLOQUEADO', 'CANCELADO')),
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
        ON DELETE RESTRICT,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE CASCADE
);

-- Compras feitas no cartão
CREATE TABLE compra_cartao (
    id_compra       SERIAL PRIMARY KEY,
    id_cartao       INT           NOT NULL,
    estabelecimento VARCHAR(120)  NOT NULL,
    valor           DECIMAL(12,2) NOT NULL CHECK (valor > 0),
    parcelas        INT           NOT NULL DEFAULT 1 CHECK (parcelas BETWEEN 1 AND 24),
    data_compra     TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cartao) REFERENCES cartao(id_cartao)
        ON DELETE CASCADE
);

-- Contrato de empréstimo
CREATE TABLE emprestimo (
    id_emprestimo       SERIAL PRIMARY KEY,
    id_cliente          INT           NOT NULL,
    id_conta            INT           NOT NULL,      -- conta que recebeu o crédito
    valor_contratado    DECIMAL(12,2) NOT NULL CHECK (valor_contratado > 0),
    taxa_juros_mensal   DECIMAL(5,4)  NOT NULL CHECK (taxa_juros_mensal > 0),
    qtd_parcelas        INT           NOT NULL CHECK (qtd_parcelas BETWEEN 1 AND 120),
    data_contratacao    DATE          NOT NULL DEFAULT CURRENT_DATE,
    status              VARCHAR(20)   NOT NULL DEFAULT 'EM_DIA'
        CHECK (status IN ('EM_DIA', 'ATRASADO', 'QUITADO')),
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
        ON DELETE RESTRICT,                          -- dívida não some com o cadastro
    FOREIGN KEY (id_conta) REFERENCES conta(id_conta)
        ON DELETE RESTRICT
);

-- Parcelas de cada empréstimo
CREATE TABLE parcela_emprestimo (
    id_parcela      SERIAL PRIMARY KEY,
    id_emprestimo   INT           NOT NULL,
    numero_parcela  INT           NOT NULL CHECK (numero_parcela >= 1),
    valor_parcela   DECIMAL(12,2) NOT NULL CHECK (valor_parcela > 0),
    data_vencimento DATE          NOT NULL,
    data_pagamento  DATE,                            -- NULL = parcela ainda não paga
    UNIQUE (id_emprestimo, numero_parcela),
    FOREIGN KEY (id_emprestimo) REFERENCES emprestimo(id_emprestimo)
        ON DELETE CASCADE
);
