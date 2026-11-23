-- ============================================================
-- Aurum Bank - Sistema Bancário
-- Administração, segurança e LGPD
-- Execute depois dos scripts 01 a 05 (usa as views do script 05).
-- Reexecutável. Papéis são NOLOGIN: na produção cada pessoa/aplicação
-- recebe um usuário LOGIN com senha forte que herda um destes papéis.
-- ============================================================

-- ------------------------------------------------------------
-- 1) Papéis (princípio do menor privilégio)
-- ------------------------------------------------------------
DO $$
DECLARE r text;
BEGIN
    FOREACH r IN ARRAY ARRAY['app_banco', 'analista', 'auditor', 'backup_operador'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
        END IF;
    END LOOP;
END
$$;

GRANT app_banco, analista, auditor, backup_operador TO CURRENT_USER;

-- Ninguém além do dono cria objetos no schema public
REVOKE CREATE ON SCHEMA public FROM PUBLIC;
GRANT  USAGE  ON SCHEMA public TO app_banco, analista, auditor, backup_operador;

-- ------------------------------------------------------------
-- 2) Visão sem dados pessoais para o time de análise
-- ------------------------------------------------------------
CREATE OR REPLACE VIEW vw_analise_transacoes AS
SELECT date_trunc('month', t.data_hora)::date AS mes,
       ag.nome                               AS agencia,
       c.tipo_conta,
       t.tipo,
       COALESCE(cat.nome_categoria, 'Sem categoria') AS categoria,
       t.valor
FROM transacao t
JOIN conta c                       ON c.id_conta      = t.id_conta
JOIN agencia ag                    ON ag.id_agencia   = c.id_agencia
LEFT JOIN categoria_transacao cat  ON cat.id_categoria = t.id_categoria;

-- ------------------------------------------------------------
-- 3) Trilha de auditoria (LGPD art. 37 e 46: registrar e proteger)
--    A tabela guarda QUEM mudou O QUÊ e QUANDO, sem copiar dados pessoais.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS log_auditoria (
    id_log      BIGSERIAL PRIMARY KEY,
    tabela      VARCHAR(50)  NOT NULL,
    operacao    VARCHAR(20)  NOT NULL,
    id_registro INT,
    usuario_db  VARCHAR(80)  NOT NULL DEFAULT current_user,
    data_hora   TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    detalhe     JSONB
);

-- Conta: registra mudança de saldo e de status (sem dados do cliente)
CREATE OR REPLACE FUNCTION fn_auditar_conta() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NEW.saldo IS DISTINCT FROM OLD.saldo OR NEW.status IS DISTINCT FROM OLD.status THEN
        INSERT INTO log_auditoria (tabela, operacao, id_registro, detalhe)
        VALUES ('conta', 'UPDATE', NEW.id_conta,
                jsonb_build_object('saldo_antes', OLD.saldo, 'saldo_depois', NEW.saldo,
                                   'status_antes', OLD.status, 'status_depois', NEW.status));
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_auditar_conta ON conta;
CREATE TRIGGER trg_auditar_conta AFTER UPDATE ON conta
    FOR EACH ROW EXECUTE FUNCTION fn_auditar_conta();

-- Cliente: registra só os NOMES das colunas alteradas (nunca os valores)
CREATE OR REPLACE FUNCTION fn_auditar_cliente() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
DECLARE colunas text[];
BEGIN
    SELECT array_agg(n.key ORDER BY n.key) INTO colunas
    FROM jsonb_each(to_jsonb(NEW)) n
    JOIN jsonb_each(to_jsonb(OLD)) o USING (key)
    WHERE n.value IS DISTINCT FROM o.value;
    IF colunas IS NOT NULL THEN
        INSERT INTO log_auditoria (tabela, operacao, id_registro, detalhe)
        VALUES ('cliente', 'UPDATE', NEW.id_cliente, jsonb_build_object('colunas_alteradas', colunas));
    END IF;
    RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_auditar_cliente ON cliente;
CREATE TRIGGER trg_auditar_cliente AFTER UPDATE ON cliente
    FOR EACH ROW EXECUTE FUNCTION fn_auditar_cliente();

-- ------------------------------------------------------------
-- 4) Direito de eliminação/anonimização (LGPD art. 18, IV e VI)
--    O banco é obrigado a guardar o histórico financeiro (obrigação legal,
--    art. 16, I): por isso NÃO apagamos contas e lançamentos; anonimizamos
--    os dados pessoais do cadastro. Não anonimiza quem tem empréstimo aberto.
-- ------------------------------------------------------------
CREATE OR REPLACE FUNCTION anonimizar_cliente(p_id_cliente INT) RETURNS VOID
LANGUAGE plpgsql SECURITY DEFINER SET search_path = public AS $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente WHERE id_cliente = p_id_cliente) THEN
        RAISE EXCEPTION 'Cliente % não existe', p_id_cliente;
    END IF;
    IF EXISTS (SELECT 1 FROM emprestimo
               WHERE id_cliente = p_id_cliente AND status <> 'QUITADO') THEN
        RAISE EXCEPTION 'Cliente % possui empréstimo em aberto: anonimização bloqueada', p_id_cliente;
    END IF;

    UPDATE cliente
    SET nome            = 'CLIENTE ANONIMIZADO',
        email           = 'anonimo-' || id_cliente || '@anonimizado.invalid',
        senha_hash      = 'ANONIMIZADO',
        cpf             = 'ANON-' || id_cliente,
        data_nascimento = DATE '1900-01-01',
        renda_mensal    = NULL
    WHERE id_cliente = p_id_cliente;

    UPDATE cartao SET status = 'CANCELADO' WHERE id_cliente = p_id_cliente;

    INSERT INTO log_auditoria (tabela, operacao, id_registro, detalhe)
    VALUES ('cliente', 'ANONIMIZACAO', p_id_cliente, jsonb_build_object('motivo', 'solicitação do titular (LGPD art. 18)'));
END $$;

REVOKE ALL ON FUNCTION anonimizar_cliente(INT) FROM PUBLIC;   -- só quem recebe GRANT executa

-- ------------------------------------------------------------
-- 5) Permissões (GRANT) por papel
-- ------------------------------------------------------------
-- Aplicação: lê e grava o necessário; NÃO apaga lançamentos nem contas.
GRANT SELECT, INSERT, UPDATE ON cliente, conta, conta_corrente, conta_poupanca, conta_titular,
      cartao, compra_cartao, emprestimo, parcela_emprestimo TO app_banco;
GRANT SELECT, INSERT         ON transacao TO app_banco;            -- extrato é imutável
GRANT SELECT                 ON agencia, categoria_transacao TO app_banco;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO app_banco;
GRANT EXECUTE ON FUNCTION anonimizar_cliente(INT) TO app_banco;

-- Análise: só a view sem dados pessoais
GRANT SELECT ON vw_analise_transacoes TO analista;

-- Auditoria: só lê o log
GRANT SELECT ON log_auditoria TO auditor;

-- Backup: lê tudo, não altera nada (pg_dump)
GRANT pg_read_all_data TO backup_operador;

-- ------------------------------------------------------------
-- 6) Testes de segurança (rode como sessão do dono; cada bloco volta ao normal)
-- ------------------------------------------------------------
-- T1 (deve FUNCIONAR): a aplicação registra um lançamento.
BEGIN;
SET LOCAL ROLE app_banco;
INSERT INTO transacao (id_conta, tipo, valor, descricao) VALUES (1, 'DEPOSITO', 10.00, 'Teste de papel');
ROLLBACK;

-- T2 (deve DAR ERRO): a aplicação não pode apagar lançamentos.
-- BEGIN; SET LOCAL ROLE app_banco; DELETE FROM transacao WHERE id_transacao = 1; ROLLBACK;
-- Esperado: ERROR: permission denied for table transacao

-- T3 (deve DAR ERRO): a aplicação não pode alterar lançamentos (extrato imutável).
-- BEGIN; SET LOCAL ROLE app_banco; UPDATE transacao SET valor = 1 WHERE id_transacao = 1; ROLLBACK;
-- Esperado: ERROR: permission denied for table transacao

-- T4 (deve FUNCIONAR): o analista consulta a visão agregável.
BEGIN;
SET LOCAL ROLE analista;
SELECT agencia, tipo, SUM(valor) AS total FROM vw_analise_transacoes GROUP BY agencia, tipo ORDER BY agencia, tipo LIMIT 5;
ROLLBACK;

-- T5 (deve DAR ERRO): o analista não enxerga CPF.
-- BEGIN; SET LOCAL ROLE analista; SELECT cpf FROM cliente; ROLLBACK;
-- Esperado: ERROR: permission denied for table cliente

-- T6 (deve DAR ERRO): o auditor não altera nada, nem o próprio log.
-- BEGIN; SET LOCAL ROLE auditor; DELETE FROM log_auditoria; ROLLBACK;
-- Esperado: ERROR: permission denied for table log_auditoria

-- T7 (deve FUNCIONAR): a trilha registra a alteração de saldo.
BEGIN;
UPDATE conta SET saldo = saldo + 1 WHERE id_conta = 1;
SELECT tabela, operacao, id_registro, detalhe FROM log_auditoria ORDER BY id_log DESC LIMIT 1;
ROLLBACK;

-- T8 (LGPD): anonimiza o cliente 12 (sem empréstimo) e confere. Rode a carga 01b para desfazer.
BEGIN;
SELECT anonimizar_cliente(12);
SELECT id_cliente, nome, email, cpf, renda_mensal FROM cliente WHERE id_cliente = 12;
ROLLBACK;

-- T9 (deve DAR ERRO): cliente 3 tem empréstimo em aberto.
-- SELECT anonimizar_cliente(3);
-- Esperado: ERROR: Cliente 3 possui empréstimo em aberto: anonimização bloqueada

-- ------------------------------------------------------------
-- 7) Rotina de administração (manutenção e monitoramento)
-- ------------------------------------------------------------
-- Manutenção (agende toda madrugada; o autovacuum já cuida do dia a dia):
-- VACUUM (ANALYZE);
-- Tamanho do banco e das maiores tabelas:
SELECT pg_size_pretty(pg_database_size(current_database())) AS tamanho_banco;
SELECT relname AS tabela, pg_size_pretty(pg_total_relation_size(relid)) AS tamanho_total
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC
LIMIT 5;
-- Sessões ativas e consultas lentas:
SELECT pid, usename, state, now() - query_start AS duracao, left(query, 60) AS consulta
FROM pg_stat_activity
WHERE datname = current_database() AND state <> 'idle' AND pid <> pg_backend_pid();
-- Quem tem acesso a quê (conferir periodicamente):
SELECT grantee, table_name, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privilegios
FROM information_schema.role_table_grants
WHERE grantee IN ('app_banco', 'analista', 'auditor', 'atendimento') AND table_schema = 'public'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;
