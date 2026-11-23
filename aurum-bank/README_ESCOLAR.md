# Aurum Bank — Projeto escolar de Banco de Dados

## O que é o projeto?
O Aurum Bank é uma simulação de banco digital feita para demonstrar conteúdos de Banco de Dados usando PostgreSQL. Os dados são fictícios. O projeto representa agências, clientes, contas, titulares, movimentações, cartões e empréstimos.

## Como abrir
1. Extraia a pasta ZIP para um local de sua preferência.
2. Abra a pasta `aurum-bank` no VS Code (ou outro editor).
3. Instale/abra o PostgreSQL e o pgAdmin.
4. No pgAdmin, crie um banco chamado `aurum`.
5. Abra o Query Tool desse banco e execute os arquivos SQL na ordem abaixo. Os arquivos podem ser abertos no editor e copiados para o Query Tool, ou executados pelo recurso de abrir arquivo do Query Tool.

## Ordem recomendada para a apresentação e execução
Para a demonstração principal, execute:
1. `sql/01_script_ddl.sql` — cria a estrutura (tabelas, chaves e regras).
2. `sql/01b_carga_dados.sql` — insere dados fictícios para demonstrar.
3. `sql/03_consultas_dql.sql` — consultas básicas (SELECT).
4. `sql/04_consultas_dql2.sql` — consultas com junções e agregações.
5. `sql/05_subconsultas_views_dcl_tcl.sql` — recursos avançados; leia o arquivo e execute os blocos adequados ao ambiente.
6. `sql/08_administracao_seguranca_lgpd.sql` — recursos de administração e segurança; requer permissões adequadas e deve ser lido antes da execução.

`sql/02_operacoes_dml.sql` contém exemplos de INSERT, UPDATE e DELETE e pode modificar os dados. Use com atenção e, se desejar repetir a demonstração, recrie a base ou recarregue os scripts iniciais.

## O que existe em cada pasta?
- `sql/`: scripts organizados por etapa do conteúdo de banco de dados.
- `docs/`: DER, relatórios, roteiro de apresentação e materiais de apoio.
- `backup/`: scripts de backup e restauração via ferramentas do PostgreSQL.
- `testes/`: scripts de teste automatizado em shell; são opcionais e voltados a ambientes compatíveis com Linux/macOS ou shell apropriado.

## Explicação dos arquivos SQL
- `01_script_ddl.sql`: DDL (Data Definition Language). Define tabelas, tipos, constraints, PKs, FKs e regras de integridade.
- `01b_carga_dados.sql`: carga de dados fictícios para permitir consultas e demonstrações.
- `02_operacoes_dml.sql`: DML (Data Manipulation Language), como INSERT, UPDATE e DELETE, e exemplos de operações.
- `03_consultas_dql.sql`: DQL (Data Query Language): consultas para visualizar e filtrar informações.
- `04_consultas_dql2.sql`: consultas que combinam tabelas, agregam resultados e usam agrupamentos.
- `05_subconsultas_views_dcl_tcl.sql`: subconsultas, views, permissões (DCL) e transações (TCL). Alguns comandos dependem de privilégios.
- `06a_carga_volume.sql`: gera uma quantidade maior de dados para testes de desempenho. É opcional e pode consumir tempo/recursos.
- `06b_indices.sql`: cria índices e compara planos/tempos de consultas. Requer que a base de desempenho esteja preparada.
- `07_concorrencia.sql`: demonstra transações, bloqueios e cenários de concorrência. Estude o roteiro antes de executar.
- `08_administracao_seguranca_lgpd.sql`: demonstra rotinas de administração, segurança e privacidade. Alguns comandos são exclusivos de administradores.

## Etapas avançadas opcionais
Os scripts `06a`, `06b` e `07`, assim como os scripts da pasta `backup/` e `testes/`, não são necessários para uma apresentação inicial. Eles servem para demonstrações aprofundadas. Não execute scripts de backup, restauração, concorrência, permissões ou exclusão em um banco com dados importantes.

## Materiais de apoio
- `docs/der.png`: diagrama de entidades e relacionamentos.
- `docs/Projeto_A3_Aurum_Bank.docx`: documento principal da A3.
- `docs/Relatorio_Final_Administracao_Seguranca_LGPD.docx`: relatório complementar.
- `docs/roteiro_apresentacao_e_defesa.md`: roteiro e perguntas para apresentação.
- `docs/log_contribuicoes.md`: registro de contribuições do trabalho.
- `docs/grafico_indices.png`: visualização relacionada ao estudo de índices.

> Este projeto não precisa de Git nem GitHub. Basta manter a pasta organizada no computador e abrir os arquivos localmente.
