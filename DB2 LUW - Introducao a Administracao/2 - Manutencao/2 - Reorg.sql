--***** F'X' *****---
/*
Tabela:
F1: Overflows < 5%
F2: PCTFREE inferior a 30%
F3: N�mero de p�ginas que contem linhas deve ser inferior a 20% do total de p�ginas.
�ndice:
F4: CLUSTER_RATIO OU CLUSTER_FACTOR > 80%
-Algumas vezes sao criados v�rios indices na tabela, mas alguns indices tem uma baixa relacao de
cluster (agrupamento), uma ordem
bem diferente da tabela
F5: PCTFREE > 50%
-A porcentagem de espa�o utilizado no n�vel folha. Se for menor que 50%, dever� ser feito um reorg.
F6: > 1
-Veriffica que todas as entradas de �ndice no �ndice existente podem caber em um �ndice que � um
n�vel menor do que o �ndice existente.
Amount of space needed for an index if it was one level smaller
--------------------------------------------------------------- < 1
Amount of space needed for all the entries in the index
F7:
-O n�mero de RID pseudo-deletados em p�ginas n�o-pseudo-vazias deve ser inferior a 20 por cento.
F8:
-O n�mero de p�ginas no n�vel folha pseudo-vazias deve ser inferior a 20 por cento do n�mero total
de p�ginas de folha.
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
        
        
SELECT 'runstats on table ' || trim(tabschema) || '.' || trim(tabname) || ' with distribution and indexes all;'
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

SELECT 'CALL SYSPROC.ADMIN_CMD(''runstats on table ' || trim(tabschema) || '.' || trim(tabname) || ' with distribution and indexes all'');'
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
Active blocks - Total de Blocos ativos para MDC, blocos que cont�m dados.
*/
CALL SYSPROC.REORGCHK_IX_STATS('S', 'DB2I101');
/*
Firstkeycard - Numeros de valores distintos na primeira chave
First2keycard - Numero de valores distintos usando as duas primeiras colunas do indice
First3keycard - Numero de valores distintos usando as tres primeiras colunas do indice
First3keycard - Numero de valores distintos usando as quatro primeiras colunas do indice
PCTFREE - Percentual de p�ginas livres na p�gina do �ndice
Dados globais (que nao possuem particionamento):
Cluster ratio - grau de clusterizacao. Indica o percentual de chaves da tabela que acompanham o
�ndice
Dados para tabelas particionadas:
AVGPARTITION_CLUSTERRATIO
AVGPARTITION_CLUSTERFACTOR
AVGPARTITION_PAGE_FETCH_PAIRS
Ordem do �ndice (se � ascendente, ou descendente)
*/

--Aqui criar tabela Empregado!

CALL SYSPROC.REORGCHK_TB_STATS('T', 'DB2I101.EMPREGADO');

CALL SYSPROC.ADMIN_CMD('runstats on table DB2I101.EMPREGADO with distribution and indexes all');

-- TRUNCATE TABLE EMPREGADO DROP STORAGE IGNORE DELETE TRIGGERS IMMEDIATE;
-- ALTER TABLE Empregado ALTER COLUMN EMP_ID RESTART WITH 0;

--Ap�s isso aqui o F3 ser� necess�rio        
DELETE FROM Empregado E WHERE MOD(E.EMP_ID,2) = 0;
CALL SYSPROC.ADMIN_CMD('runstats on table DB2I101.EMPREGADO with distribution and indexes all');
CALL SYSPROC.REORGCHK_TB_STATS('T', 'DB2I101.EMPREGADO');


--Tentar for�ar um F1
SELECT 
        TABSCHEMA, TABNAME, TABLE_SCANS, ROWS_READ, ROWS_INSERTED, ROWS_UPDATED, OVERFLOW_ACCESSES, OVERFLOW_CREATES, PAGE_REORGS
        --*
FROM TABLE(MON_GET_TABLE(NULL, NULL, -2)) T
WHERE 1=1
        AND TABNAME = 'EMPREGADO'

SELECT * FROM EMPREGADO
UPDATE Empregado E SET NOME = REPEAT('A',40) WHERE MOD(E.EMP_ID,2) = 0;
CALL SYSPROC.ADMIN_CMD('runstats on table DB2I101.EMPREGADO with distribution and indexes all');
CALL SYSPROC.REORGCHK_TB_STATS('T', 'DB2I101.EMPREGADO');

SELECT 
        TABSCHEMA, TABNAME, TABLE_SCANS, ROWS_READ, ROWS_INSERTED, ROWS_UPDATED, OVERFLOW_ACCESSES, OVERFLOW_CREATES, PAGE_REORGS
        --*
FROM TABLE(MON_GET_TABLE(NULL, NULL, -2)) T
WHERE 1=1
        AND TABNAME = 'EMPREGADO'


--Forcar um F2

--Nao deu, vou ter que fazer c�culo de ROWID
--ALTER TABLE Empregado PCTFREE 40;
--SELECT T.PCTFREE, T.* FROM SYSCAT.TABLES T WHERE T.TABNAME = 'EMPREGADO';