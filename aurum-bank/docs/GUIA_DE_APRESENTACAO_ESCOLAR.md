# Guia de explicação — Aurum Bank

## 1. Objetivo
O Aurum Bank é um banco digital fictício usado para aplicar conceitos de modelagem e SQL. O foco é demonstrar como estruturar, popular, consultar e administrar um banco de dados relacional.

## 2. DER e tabelas
O DER (`der.png`) representa visualmente entidades e relacionamentos. Cada tabela representa um conjunto de informações; as chaves primárias identificam registros e as chaves estrangeiras conectam tabelas e ajudam a preservar a integridade.

## 3. DDL — estrutura
O script `01_script_ddl.sql` define o esquema. DDL significa Data Definition Language: comandos como CREATE TABLE definem os objetos do banco. Constraints, por exemplo CHECK, UNIQUE e NOT NULL, ajudam a impedir dados inválidos.

## 4. Carga de dados
O script `01b_carga_dados.sql` insere registros fictícios. A carga permite que o banco tenha conteúdo para testar consultas e apresentar resultados.

## 5. DML — operações
DML significa Data Manipulation Language. INSERT adiciona registros, UPDATE altera registros e DELETE remove registros. Em operações de UPDATE/DELETE, filtros WHERE são importantes para limitar quais registros serão afetados.

## 6. DQL — consultas
DQL significa Data Query Language. SELECT recupera dados. WHERE filtra, ORDER BY ordena, JOIN relaciona tabelas, GROUP BY agrupa e funções agregadas (como COUNT e SUM) calculam valores sobre conjuntos de registros.

## 7. Recursos avançados
O arquivo `05_subconsultas_views_dcl_tcl.sql` reúne recursos como subconsultas, views, controle de permissões e transações. View é uma consulta armazenada que pode simplificar acesso aos dados. DCL controla permissões; TCL controla transações.

## 8. Índices e desempenho
Os scripts 06a e 06b criam uma base maior e avaliam índices. Um índice pode ajudar a localizar registros com menos trabalho, embora também ocupe espaço e tenha custo de manutenção em operações de escrita.

## 9. Concorrência
O script 07 aborda transações e cenários em que operações acontecem ao mesmo tempo. O objetivo é evitar inconsistências e entender bloqueios. Use somente em base de teste.

## 10. Segurança e privacidade
O script 08 demonstra controles e rotinas de administração. O relatório complementar discute segurança e LGPD. A demonstração deve usar dados fictícios, não dados reais de clientes.

## Sugestão de fala
“Nosso projeto simula o banco de dados de um banco digital fictício. Primeiro desenhamos o modelo de dados, depois criamos as tabelas e as regras de integridade com DDL. Inserimos dados fictícios, demonstramos operações de inclusão, alteração e exclusão, e fizemos consultas SQL. Por fim, o projeto explora recursos avançados como views, permissões, transações, índices, concorrência, backup e segurança. Organizamos os arquivos por etapa para facilitar a execução e explicar cada conteúdo.”
