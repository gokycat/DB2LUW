--***** F* *****---
/*
Tabela:
F1: Overflows < 5%
F2: PCTFREE inferior a 30%
F3: Número de páginas que contem linhas deve ser inferior a 20% do total de páginas.
Índice:
F4: CLUSTER_RATIO OU CLUSTER_FACTOR > 80%
-Algumas vezes sao criados vários indices na tabela, mas alguns indices tem uma baixa relacao de
cluster (agrupamento), uma ordem
bem diferente da tabela
F5: PCTFREE > 50%
-A porcentagem de espaço utilizado no nível folha. Se for menor que 50%, deverá ser feito um reorg.
F6: > 1
-Veriffica que todas as entradas de índice no índice existente podem caber em um índice que é um
nível menor do que o índice existente.
Amount of space needed for an index if it was one level smaller
--------------------------------------------------------------- < 1
Amount of space needed for all the entries in the index
F7:
-O número de RID pseudo-deletados em páginas não-pseudo-vazias deve ser inferior a 20 por cento.
F8:
-O número de páginas no nível folha pseudo-vazias deve ser inferior a 20 por cento do número total
de páginas de folha.
*/

----------------------------------------------------------------------------------------------------
------------------ Gerar comandos para rodar da linha de comando -----------------------------------
----------------------------------------------------------------------------------------------------

CALL SYSPROC.ADMIN_CMD('update db cfg using AUTO_MAINT OFF');
CALL SYSPROC.ADMIN_CMD('update db cfg using AUTO_TBL_MAINT OFF');
CALL SYSPROC.ADMIN_CMD('update db cfg using AUTO_RUNSTATS OFF');
CALL SYSPROC.ADMIN_CMD('update db cfg using AUTO_STMT_STATS OFF');
CALL SYSPROC.ADMIN_CMD('update db cfg using CUR_COMMIT ON');
CALL SYSPROC.ADMIN_CMD('update db cfg using LOGPRIMARY 200');
CALL SYSPROC.ADMIN_CMD('update db cfg using LOGSECOND 0');

SELECT 'reorgchk update statistics on table ' || TRIM(tabschema) || '.' || TRIM(tabname) || ';' 
        AS "REORGCHK WITH UPDATE STATISTCS"
FROM syscat.tables
WHERE 1=1
        AND type = 'T'
        AND TABSCHEMA NOT IN ('SYSCAT', 'SYSIBM','SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS') ; 

SELECT 'reorg table ' || rtrim(tabschema) || '.' || trim(tabname) || ';'
        AS "REORG TABLE"
FROM syscat.tables 
WHERE 1=1
        AND type = 'T'
        AND TABSCHEMA NOT IN ('SYSCAT', 'SYSIBM','SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS') ; 
        
        
SELECT 'runstats on table ' || trim(tabschema) || '.' || trim(tabname) || ' and indexes all;'
        AS "RUNSTATS"
FROM syscat.tables 
WHERE 1=1
        AND type = 'T'
        AND TABSCHEMA NOT IN ('SYSCAT', 'SYSIBM','SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS') ; 

---------------------------------------------------------------------------------------
------------------ Gerar comandos para rodar da IDE -----------------------------------
---------------------------------------------------------------------------------------

--CALL SYSPROC.REORGCHK_TB_STATS(<S OR T>, <Schema Name OR TABLE Name>);
CALL SYSPROC.REORGCHK_TB_STATS('S', 'DB2I101');
CALL SYSPROC.REORGCHK_IX_STATS('S', 'DB2I101');

SELECT 'CALL SYSPROC.ADMIN_CMD(''reorg table ' || rtrim(tabschema) || '.' || trim(tabname) || ''');'
        AS "REORG TABLE"
FROM syscat.tables 
WHERE 1=1
        AND type = 'T'
        AND TABSCHEMA NOT IN ('SYSCAT', 'SYSIBM','SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS') ; 

SELECT 'CALL SYSPROC.ADMIN_CMD(''runstats on table ' || trim(tabschema) || '.' || trim(tabname) || ' and indexes all'');'
        AS "RUNSTATS"
FROM syscat.tables 
WHERE 1=1
        AND type = 'T'
        AND TABSCHEMA NOT IN ('SYSCAT', 'SYSIBM','SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS') ; 


---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


--CALL SYSPROC.REORGCHK_TB_STATS(<S OR T>, <Schema Name OR TABLE Name>);
CALL SYSPROC.REORGCHK_TB_STATS('S', 'DB2I101');
/*
TSize: FPages * PageSize
TSize_MB = FPages * PageSize / (1024 * 1024) ou TSize
Active blocks - Total de Blocos ativos para MDC, blocos que contém dados.
*/
CALL SYSPROC.REORGCHK_IX_STATS('S', 'DB2I101');
/*
Firstkeycard -
First2keycard -
First3keycard -
First3keycard -
PCTFREE - Percentual de páginas livres na página do índice
Colcount -
Dados globais (que nao possuem particionamento):
Cluster ratio - grau de clusterizacao. Indica o percentual de chaves da tabela que acompanham o
índice
Cluster factor -
Page_fetch_pairs
Dados para tabelas particionadas:
AVGPARTITION_CLUSTERRATIO
AVGPARTITION_CLUSTERFACTOR
AVGPARTITION_PAGE_FETCH_PAIRS
Ordem do índice (se é ascendente, ou descendente)
*/
SELECT DISTINCT TABSCHEMA
FROM SYSCAT.TABLES;
SELECT *
FROM SESSION.TB_STATS
SELECT *
FROM SESSION.TB_STATS
WHERE REORG LIKE '%*%'