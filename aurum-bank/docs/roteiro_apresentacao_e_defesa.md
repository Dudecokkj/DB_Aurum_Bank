# Roteiro da apresentação (10 min) e preparação da arguição

## Parte 1 — Pitch em 10 minutos

Divida os blocos entre os integrantes; cada um fala sobre o que fez (isso também ajuda na nota individual).

| Tempo | Slide / bloco | O que falar | Mostrar |
|-------|---------------|-------------|---------|
| 0:00–1:00 | **O Aurum Bank** | Banco digital fictício: contas, extrato, cartão, empréstimos. Por que o domínio é rico para banco de dados (dinheiro exige consistência). | Slide de abertura |
| 1:00–2:30 | **DER** | 12 entidades. Três padrões: especialização (`conta` → corrente/poupança), N:N (`conta_titular` = conta conjunta) e tabela de eventos (`transacao` com origem e destino). | `docs/der.png` |
| 2:30–3:30 | **Modelo lógico e DDL** | 3FN, `CHECK`, `UNIQUE`, `RESTRICT` x `CASCADE` (histórico financeiro protegido). Script reexecutável. | Trecho de `01_script_ddl.sql` |
| 3:30–5:00 | **DML e consultas** | Abertura de conta em 4 comandos; exemplo de JOIN + GROUP BY + HAVING; uma subconsulta correlacionada. | Rodar 2 consultas ao vivo |
| 5:00–6:30 | **Índices** | Base com 400 mil transações; extrato foi de 30 ms para 0,17 ms; mostrar `Seq Scan` → `Index Scan`. Custo dos índices (espaço e escrita). | Gráfico do relatório + `EXPLAIN` |
| 6:30–8:00 | **Transações e concorrência** | Perda de atualização (1.000 → 500 em vez de 0), `FOR UPDATE`, deadlock detectado e como evitá-lo (travar em ordem). | Saída de `testes/concorrencia.sh` |
| 8:00–9:00 | **Backup testado** | pg_dump, restauração em banco novo, conferência de 12 tabelas por contagem e md5, desastre simulado. | Saída de `testes/backup_teste.sh` |
| 9:00–10:00 | **Segurança e LGPD + fechamento** | Papéis com menor privilégio, views sem CPF, auditoria, anonimização com retenção legal. O que aprendemos e limitações. | Tabela de testes de segurança |

**Dicas:** ensaie com cronômetro; deixe o terminal com os scripts já carregados no banco; tenha um plano B (prints) se a demonstração ao vivo falhar.

## Parte 2 — Arguição individual: perguntas prováveis

Cada integrante precisa saber explicar **o próprio schema e scripts**. Respostas curtas, baseadas no projeto:

### Modelagem
1. **Por que `conta` tem subtipos?** Corrente e poupança têm atributos diferentes (cheque especial x rendimento). O supertipo guarda o que é comum e os subtipos reaproveitam a PK (`id_conta` é PK e FK).
2. **Como resolveram conta conjunta?** Relação N:N entre cliente e conta, com a tabela associativa `conta_titular` (PK composta conta + cliente).
3. **Por que `transacao` tem duas chaves para `conta`?** `id_conta` é a conta dona do lançamento e `id_conta_destino` só existe em transferências; um `CHECK` exige o destino quando o tipo é `TRANSFERENCIA` e proíbe destino igual à origem.
4. **Por que o valor é sempre positivo?** O sentido (entrada ou saída) vem do `tipo`; assim o sinal nunca fica ambíguo e `CHECK (valor > 0)` barra erros.
5. **Está na 3FN? Mostre um exemplo.** Sim. Dados da agência ficam em `agencia` e a categoria em `categoria_transacao`; nenhuma coluna não chave depende de outra coluna não chave.

### Integridade
6. **Por que `RESTRICT` em `transacao` e `emprestimo`, mas `CASCADE` em `cartao` e `parcela_emprestimo`?** Histórico financeiro e dívida não podem sumir com o cadastro; já cartões e parcelas só fazem sentido enquanto o dono existe.
7. **Como o banco impede saldo negativo indevido?** Pela transação com `FOR UPDATE` e pela condição `saldo >= valor` no `UPDATE`. (O cheque especial seria uma regra adicional de aplicação.)

### Consultas
8. **Diferença entre `WHERE` e `HAVING`?** `WHERE` filtra linhas antes de agrupar; `HAVING` filtra grupos depois da agregação.
9. **Por que usar `NOT EXISTS` e não `NOT IN` (Q5 do arquivo 05)?** `id_conta_destino` tem `NULL`; `NOT IN` com `NULL` na lista nunca é verdadeiro e devolveria 0 linhas.
10. **Para que serve o `LEFT JOIN` na consulta de agências?** Para listar também agências sem conta (a agência 4 aparece com 0).

### Índices
11. **Por que o índice `(id_conta, data_hora DESC)` é composto?** Filtra a conta e já entrega ordenado por data, sem etapa de ordenação.
12. **O que é índice parcial e onde usamos?** Indexa só parte das linhas: transferências (`id_conta_destino IS NOT NULL`) e parcelas em aberto (`data_pagamento IS NULL`). Fica menor e mais rápido.
13. **Se índice é bom, por que não indexar tudo?** Ocupa espaço e deixa `INSERT`/`UPDATE` mais lentos. Só indexamos as consultas medidas.
14. **Por que o PostgreSQL às vezes ignora o índice?** Quando a consulta devolve muitas linhas, ler a tabela inteira pode custar menos; `EXPLAIN` mostra a escolha.

### Transações e concorrência
15. **O que é atualização perdida? Mostre.** Duas sessões leem 1.000, cada uma grava 500; o resultado é 500 em vez de 0 (cenário 1 do teste).
16. **Como `FOR UPDATE` resolve?** Trava a linha; a segunda sessão espera o `COMMIT` e lê o saldo atualizado.
17. **O que é deadlock e como evitamos?** Duas transações esperando uma pela outra (1→3 e 3→1). Evitamos travando sempre pela ordem crescente de `id_conta`; se ainda ocorrer, o PostgreSQL aborta uma delas.
18. **Para que `SAVEPOINT`?** Desfazer só um trecho da transação sem perder o que veio antes.

### Backup, segurança e LGPD
19. **Como sabem que o backup funciona?** Restauramos em banco novo e comparamos contagem e md5 das 12 tabelas, e simulamos um `DROP TABLE` para recuperar.
20. **Qual o RPO?** Até 24 h com backup diário; WAL/PITR reduziria para minutos (proposto, não implementado).
21. **Como o atendimento é impedido de ver CPF?** Só tem `GRANT` na view; consultar `cliente` dá `permission denied`.
22. **Como atendem o direito de eliminação se o banco precisa guardar o histórico?** Anonimizamos o cadastro (`anonimizar_cliente`) e mantemos contas e lançamentos por obrigação legal; bloqueamos se houver empréstimo em aberto.

## Checklist antes de entregar

- [ ] Todos os scripts rodam do zero (DDL → carga → consultas) sem erro.
- [ ] Nomes, RAs, professor e instituição preenchidos no README, relatório e documento do projeto.
- [ ] Log de contribuições preenchido e coerente com o Git.
- [ ] Cada integrante sabe explicar seu trecho do schema e dos scripts.
- [ ] Cronometrou os 10 minutos.
