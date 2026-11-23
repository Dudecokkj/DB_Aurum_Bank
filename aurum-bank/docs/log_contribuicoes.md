# Log de contribuições — Aurum Bank

> Preencha **por marco** quem fez o quê. Cada integrante deve conseguir explicar, na arguição individual, tudo o que está registrado em seu nome. Dica: use o histórico de commits do Git como prova (`git log --author="Nome" --oneline`).

## Como preencher

- **Responsável:** quem fez o trabalho (pode haver mais de um nome).
- **Revisão:** quem conferiu e rodou o resultado.
- **Evidência:** commit, arquivo ou print que comprova.
- Seja específico ("escrevi as consultas Q8 a Q15 do arquivo 04"), não genérico ("ajudei no banco").

## Marcos e entregáveis

| Marco | Prazo | Entregável | Responsável | Revisão | Evidência (arquivo/commit) |
|-------|-------|-----------|-------------|---------|----------------------------|
| Escolha do domínio | 18/08 | Domínio escolhido e ideia do sistema | _[nome]_ | _[nome]_ | `docs/` |
| DER | 01/09 | Diagrama entidade-relacionamento | _[nome]_ | _[nome]_ | `docs/der.png` |
| Modelo lógico + DDL | 13/10 | Esquema normalizado e `01_script_ddl.sql` | _[nome]_ | _[nome]_ | `sql/01_script_ddl.sql` |
| Carga de dados | 09/11 | `01b_carga_dados.sql` e `06a_carga_volume.sql` | _[nome]_ | _[nome]_ | `sql/01b_*`, `sql/06a_*` |
| DML | 09/11 | `02_operacoes_dml.sql` | _[nome]_ | _[nome]_ | `sql/02_*` |
| DQL I e II | 09/11 | `03` (14 consultas) e `04` (22 consultas) | _[nome]_ | _[nome]_ | `sql/03_*`, `sql/04_*` |
| Subconsultas, views, DCL, TCL | 09/11 | `05_subconsultas_views_dcl_tcl.sql` | _[nome]_ | _[nome]_ | `sql/05_*` |
| Índices | 09/11 | `06b_indices.sql` e análise dos planos | _[nome]_ | _[nome]_ | `sql/06b_*` |
| Plano de concorrência | 09/11 | `07_concorrencia.sql` e `testes/concorrencia.sh` | _[nome]_ | _[nome]_ | `sql/07_*`, `testes/` |
| Plano de backup testado | 09/11 | `backup/` e `testes/backup_teste.sh` | _[nome]_ | _[nome]_ | `backup/`, `testes/` |
| Administração, segurança e LGPD | 30/11 | `08_administracao_seguranca_lgpd.sql` | _[nome]_ | _[nome]_ | `sql/08_*` |
| Relatório final (6 a 10 páginas) | 30/11 | `Relatorio_Final_Administracao_Seguranca_LGPD.docx` | _[nome]_ | _[nome]_ | `docs/` |
| Ensaio de banca | 30/11 | Simulação da defesa | Todos | — | — |
| Apresentação e arguição | 01/12 | Pitch de 10 min + arguição individual | Todos | — | `docs/roteiro_apresentacao_e_defesa.md` |

## Resumo por integrante

| Integrante | RA | Principais entregas | % estimado do trabalho |
|------------|----|---------------------|------------------------|
| _[Nome 1]_ | _[RA]_ | | |
| _[Nome 2]_ | _[RA]_ | | |
| _[Nome 3]_ | _[RA]_ | | |
| _[Nome 4]_ | _[RA]_ | | |
| _[Nome 5]_ | _[RA]_ | | |

## Reuniões e decisões (opcional, mas ajuda na defesa)

| Data | Decisão tomada | Quem participou |
|------|----------------|-----------------|
| _[dd/mm]_ | Ex.: usar supertipo/subtipo para conta corrente e poupança | _[nomes]_ |
| _[dd/mm]_ | Ex.: extrato imutável (app só faz INSERT em `transacao`) | _[nomes]_ |
