/********************************************************************************************************************************
*********************************************************************************************************************************

    Autor: Raul Diego
    E-mail: raul.oliveira@sicoob.com.br
    Data criação: 14/10/2010
    ->Descrição: Script que faz um checkup das configuraçãoes e do status do DB2 e é divdido
    na versao 1.0 em 18 partes:
    ->Modo de execuçao: Execute o scprit de uma única vez a partir o DBVisualizer e consulte as abas geradas por statement
    
    1-Recursos do ambiente      2-DB_Paths and Variables        3-DB_CFG and DBM_CFG
    4-Processos                 5-Memory Sets                   6-Memory Pools 
    7-Buffer Pool               8-TableSpaces                   9-Tabelas
    10-Indices                  11-Log                          12-UOWs
    13-PKG_Cache_Last_Hour      14-PKG_Cache_Current_SQL        15-Containers
    16-DB_History               17-Lactches                     18-LockWaits
    19-LockChain                20-Utilities
    
    Compatibilidade: DB2 LUW 10.1 (View de Latches por exemplo nao existe no 9.7)

    Histórico:
        - 15/10/2014: Colocadas todas as UOWs e nao somete as em Execucao. Tempo da ultima atualizacao em PKG_Cache_Current_SQL 
        - 16/10/2014: Acrescentado qual percentual do package cache aquela consulta utiliza
        - 13/11/2014: Acrescentado o script de Lock Chain (mto top) do Luti
        - 13/11/2014: Acrescentado informaçoes como lock_Count no bloco de LOCK
        - 14/11/2014: Acrescentado as informaçoes da sessao mais antiga que esta "travando" log (by Euler)
        
*********************************************************************************************************************************
********************************************************************************************************************************/


;--1-Recurso do ambiente ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH EnvRec AS (
SELECT T.HOST_NAME,    T.OS_NAME ,    
    T.CPU_USAGE_TOTAL,    T.CPU_LOAD_MEDIUM,    T.CPU_LOAD_LONG, T.CPU_IDLE,    T.CPU_IOWAIT ,    
    T.MEMORY_TOTAL,    T.MEMORY_FREE ,    T.CPU_SYSTEM,    T.CPU_USER,
    T.VIRTUAL_MEM_TOTAL,    T.VIRTUAL_MEM_RESERVED,    T.VIRTUAL_MEM_FREE ,
    T.MEMORY_SWAP_TOTAL,    T.MEMORY_SWAP_FREE,    T.SWAP_PAGE_SIZE,    T.SWAP_PAGES_IN,    T.SWAP_PAGES_OUT ,
    --T.CPU_LOAD_SHORT ,
    T.CPU_TOTAL,    T.CPU_ONLINE,    T.CPU_CONFIGURED,    T.CPU_SPEED,    T.CPU_HMT_DEGREE ,    
    T.OS_VERSION,    T.OS_RELEASE,    T.MACHINE_IDENTIFICATION,    T.OS_LEVEL,
    (SELECT INSTALLED_PROD FROM SYSIBMADM.ENV_PROD_INFO) AS INSTALLED_PROD,
    (SELECT SERVICE_LEVEL FROM SYSIBMADM.ENV_INST_INFO) AS SERVICE_LEVEL,
    (SELECT LICENSE_INSTALLED FROM SYSIBMADM.ENV_PROD_INFO) AS LICENSED_INSTALLED,
    (SELECT DBI.DB_SIZE / (1024*1024*1024) FROM SYSTOOLS.STMG_DBSIZE_INFO DBI) AS DB_SIZE_GB,
    (SELECT DBI.DB_CAPACITY / (1024*1024*1024) FROM SYSTOOLS.STMG_DBSIZE_INFO DBI) AS DB_CAPACITY_GB
FROM TABLE (SYSPROC.ENV_GET_SYSTEM_RESOURCES()) AS T 
)
SELECT L.Area, L.Counter1, L.Valor1, L.Counter2, L.Valor2,L.Counter3, L.Valor3, L.Counter4, L.Valor4,L.Counter5, L.Valor5
FROM EnvRec T 
  ,LATERAL (VALUES 
                ('--Sistema Operacional--','HOST_NAME->',T.HOST_NAME,'OS_NAME->',T.OS_NAME,'OS_VERSION->', T.OS_VERSION, 'OS_RELEASE->', T.OS_RELEASE, 'OS_LEVEL->', T.OS_LEVEL)
               ,('--Instalacao DB2--','INSTALLED_PROD->', T.INSTALLED_PROD,'SERVICE_LEVEL->', T.SERVICE_LEVEL,'LICENSED_INSTALLED->', T.LICENSED_INSTALLED,'MACHINE_IDENTIFICATION->', T.MACHINE_IDENTIFICATION,'Diretorio->', 'NAO IMPLEMENTADO')
               ,('--CPU Perf--','CPU_USAGE_TOTAL->',CAST(T.CPU_USAGE_TOTAL AS VARCHAR(15)),  'CPU_LOAD_MEDIUM->',  CAST(CAST(T.CPU_LOAD_MEDIUM AS DECIMAL(16,2)) AS VARCHAR(20)), 'CPU_LOAD_LONG->',   CAST(CAST(T.CPU_LOAD_LONG AS DECIMAL(16,2)) AS VARCHAR(20)),'CPU_IDLE->', CAST(T.CPU_IDLE AS VARCHAR(15)), 'CPU_IOWAIT->',    CAST(T.CPU_IOWAIT AS VARCHAR(15)))
               ,('--CPU Installed--','CPU_TOTAL->', CAST(T.CPU_TOTAL AS VARCHAR(2)),'CPU_ONLINE->', CAST(T.CPU_ONLINE AS VARCHAR(2)),'CPU_CONFIGURED->', CAST(T.CPU_CONFIGURED AS VARCHAR(2)),'CPU_SPEED->', CAST(T.CPU_SPEED AS VARCHAR(15)),'CPU_HMT_DEGREE->', CAST(T.CPU_HMT_DEGREE AS VARCHAR(15)))
               ,('--Mem Perf--','MEMORY_TOTAL->', CAST(T.MEMORY_TOTAL AS VARCHAR(15)),'MEMORY_FREE->', CAST(T.MEMORY_FREE AS VARCHAR(15)),'VIRTUAL_MEM_TOTAL->', CAST(T.VIRTUAL_MEM_TOTAL AS VARCHAR(15)),'VIRTUAL_MEM_RESERVED->', CAST(T.VIRTUAL_MEM_RESERVED AS VARCHAR(15)),'VIRTUAL_MEM_FREE->', CAST(T.VIRTUAL_MEM_FREE AS VARCHAR(15)))
               ,('--SWAP--','MEMORY_SWAP_TOTAL->', CAST(T.MEMORY_SWAP_TOTAL AS VARCHAR(15)),'MEMORY_SWAP_FREE->', CAST(T.MEMORY_SWAP_FREE AS VARCHAR(15)),'SWAP_PAGE_SIZE->', CAST(T.SWAP_PAGE_SIZE AS VARCHAR(15)),'SWAP_PAGES_IN->', CAST(T.SWAP_PAGES_IN AS VARCHAR(15)),'SWAP_PAGES_OUT->', CAST(T.SWAP_PAGES_OUT AS VARCHAR(15)))
               ,('--Database--','DB_SIZE_GB->', CAST(T.DB_SIZE_GB AS VARCHAR(15)),'DB_CAPACITY_GB->', CAST(T.DB_CAPACITY_GB AS VARCHAR(15)),'N/A->', CAST('N/A' AS VARCHAR(15)),'N/A->', CAST('N/A' AS VARCHAR(15)),'N/A->', CAST('N/A' AS VARCHAR(15)))
          ) AS L(Area,Counter1, Valor1, Counter2, Valor2,Counter3, Valor3, Counter4, Valor4,Counter5, Valor5)
WITH UR;



--2-DBPaths-Variables ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT 'PATHS' AS TYPE_DADO, TYPE AS NAME, DB.PATH AS VALUE
FROM SYSIBMADM.DBPATHS DB
UNION ALL
SELECT 'VARIABLES' AS TYPE_DADO, RV.REG_VAR_NAME AS NAME, RV.REG_VAR_VALUE AS VALUE
FROM SYSIBMADM.REG_VARIABLES RV
WITH UR;

--3-DB_CFG_&_DBM_CFG::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT 'DB_CFG' AS TYPE, DB.NAME, DB.VALUE, DB.DEFERRED_VALUE 
FROM SYSIBMADM.DBCFG DB
UNION ALL 
SELECT 'DBM_CFG' AS TYPE, DBM.NAME, DBM.VALUE, DBM.DEFERRED_VALUE
FROM SYSIBMADM.DBMCFG DBM
WITH UR;L

--4-Processos  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH SYSRES AS 
     (
        SELECT SUM(CPU_USER) AS SUM_CPU_USER
              ,SUM(CPU_SYSTEM) AS SUM_CPU_SYSTEM
        FROM TABLE(ENV_GET_DB2_SYSTEM_RESOURCES(-2))
     )
SELECT DB2_PROCESS_NAME, DB2_PROCESS_ID
,CPU_USER
,DECIMAL((CPU_USER * 100)/SUM_CPU_USER,10,2) AS PERCENT_CPU_USER
,CPU_SYSTEM
,DECIMAL((CPU_SYSTEM * 100)/SUM_CPU_SYSTEM,10,2) AS PERCENT_CPU_SYSTEM
FROM TABLE(ENV_GET_DB2_SYSTEM_RESOURCES(-2)) AS T
, SYSRES AS S
ORDER BY CPU_USER DESC, CPU_SYSTEM DESC
WITH UR;

--5-Memory Sets  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT T.DB_NAME
        ,T.MEMORY_SET_TYPE
        ,CAST(T.MEMORY_SET_SIZE / 1024 AS VARCHAR(15))  AS MEMORY_SET_SIZE_MB
        ,CAST(T.MEMORY_SET_COMMITTED / 1024 AS VARCHAR(15)) AS MEMORY_SET_COMMITTED_MB
        ,CAST(T.MEMORY_SET_USED / 1024 AS VARCHAR(15)) AS MEMORY_SET_USED 
        ,CAST(T.MEMORY_SET_USED_HWM / 1024 AS VARCHAR(15)) AS MEMORY_SET_USED_HWM_MB
FROM TABLE( 
       MON_GET_MEMORY_SET(NULL, CURRENT_SERVER, -2)) AS T
UNION ALL
SELECT  
        'MaxInstanceMemory_GB->' AS DB_NAME
        ,CAST(MAX_PARTITION_MEM/(1024.0*1024*1024) AS VARCHAR(15)) || ' GB' AS MEMORY_SET_TYPE
        ,'CurrentInstanceMem_GB->' AS MEMORY_SET_SIZE_MB
        ,CAST(CURRENT_PARTITION_MEM/(1024.0*1024*1024) AS VARCHAR(15)) || ' GB' AS MEMORY_SET_COMMITTED_MB
        ,'PeakInstaceMem_GB' AS MEMORY_SET_USED
        ,CAST(PEAK_PARTITION_MEM/(1024.0*1024*1024) AS VARCHAR(15)) || ' GB' AS MEMORY_SET_USED_HWM_MB  
FROM TABLE (SYSPROC.ADMIN_GET_DBP_MEM_USAGE(-1)) AS T
WITH UR;

--6-Memory Pools ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT T.MEMORY_SET_TYPE
        ,T.MEMORY_POOL_TYPE
        ,SUM(T.MEMORY_POOL_USED)/1024 as MEMORY_POOL_USED_MB
        ,SUM(T.MEMORY_POOL_USED_HWM) /1024 AS MEMORY_POOL_USED_HWM_MB
FROM TABLE(MON_GET_MEMORY_POOL(NULL, CURRENT_SERVER, -2)) T
GROUP BY T.MEMORY_POOL_TYPE, T.MEMORY_SET_TYPE
ORDER BY T.MEMORY_SET_TYPE, MEMORY_POOL_USED_MB DESC
WITH UR;

--7-BufferPool  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH BPMETRICS AS
    ( SELECT bp_name,
            AUTOMATIC,
            BP_CUR_BUFFSZ,
            pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads +
            pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads AS logical_reads,
            pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads +
            pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads AS physical_reads,
            pool_data_l_reads, pool_temp_data_l_reads, pool_index_l_reads,
            pool_data_p_reads, pool_temp_data_p_reads, pool_index_p_reads,
            member,
            BLOCK_IOS,
            PAGES_FROM_BLOCK_IOS
        FROM TABLE(MON_GET_BUFFERPOOL('',-2)) AS METRICS
    )
SELECT VARCHAR(bp_name,20) AS bp_name,     AUTOMATIC,    BP_CUR_BUFFSZ,    
    logical_reads,    physical_reads,
    CASE
        WHEN logical_reads > 0
        THEN DEC((1 - (FLOAT(physical_reads) / FLOAT(logical_reads))) * 100,5,2)
        ELSE NULL
    END AS HIT_RATIO,
    pool_data_l_reads, pool_index_l_reads,
     CASE
        WHEN pool_data_l_reads > 0
        THEN (pool_index_l_reads * 100) / (pool_index_l_reads + pool_data_l_reads) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
    END AS Percent_Util_Index_Logical,
    pool_data_p_reads, pool_index_p_reads,
     CASE
        WHEN pool_data_l_reads > 0
        THEN (pool_index_p_reads * 100) / (pool_index_p_reads + pool_data_p_reads) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
    END AS Percent_Util_Index_Physical,
    pool_temp_data_l_reads, pool_temp_data_p_reads 
FROM BPMETRICS
WITH UR;

--8-TableSpaces  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT T.TBSP_NAME, TBSP_CONTENT_TYPE, VARCHAR(TBSP_PAGE_SIZE/1024) || 'K' AS PAGE_SIZE
,RECLAIMABLE_SPACE_ENABLED AS RECLAIMABLE
,TBSP_TOTAL_PAGES*TBSP_PAGE_SIZE/(1024*1024) AS SIZE_TBSP_MB
,TBSP_USED_PAGES *TBSP_PAGE_SIZE/(1024*1024) AS TBSP_USED_PAGES_MB
,TBSP_FREE_PAGES *TBSP_PAGE_SIZE/(1024*1024) AS TBSP_FREE_PAGES_MB
,TBSP_USABLE_PAGES*TBSP_PAGE_SIZE/(1024*1024) AS TBSP_USABLE_PAGES_MB
,POOL_WRITE_TIME
,CASE
        WHEN POOL_WRITE_TIME > 0
        THEN POOL_WRITE_TIME / (POOL_DATA_WRITES + POOL_XDA_WRITES + POOL_INDEX_WRITES) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
 END AS AVG_Time_Write
,POOL_DATA_WRITES, POOL_INDEX_WRITES
,CASE
        WHEN POOL_DATA_WRITES > 0
        THEN (POOL_INDEX_WRITES * 100) / (POOL_INDEX_WRITES + POOL_DATA_WRITES) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
 END AS Percent_Write_Index
,POOL_DATA_P_READS, POOL_INDEX_P_READS
,CASE
        WHEN POOL_DATA_P_READS > 0
        THEN (POOL_INDEX_P_READS * 100) / (POOL_INDEX_P_READS + POOL_DATA_P_READS) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
 END AS Percent_READ_P_Index
,POOL_TEMP_DATA_P_READS, POOL_TEMP_INDEX_P_READS
,POOL_DATA_L_READS, POOL_INDEX_L_READS
,CASE
        WHEN POOL_DATA_L_READS > 0
        THEN (POOL_INDEX_L_READS * 100) / (POOL_INDEX_L_READS + POOL_DATA_L_READS) --DEC((1 - (FLOAT(pool_index_l_reads) / FLOAT(pool_data_l_reads))) * 100,5,2)
        ELSE NULL 
 END AS Percent_READ_L_Index
,POOL_TEMP_DATA_L_READS, POOL_TEMP_INDEX_L_READS
--,TBSP_TOTAL_PAGES, TBSP_USED_PAGES, TBSP_FREE_PAGES, TBSP_USABLE_PAGES, TBSP_PAGE_TOP, TBSP_MAX_PAGE_TOP
, TBSP_PAGE_TOP, TBSP_MAX_PAGE_TOP
, TBSP_ID, TBSP_TYPE
, TABLESPACE_MIN_RECOVERY_TIME AS TBSP_MIN_REC_TIME
FROM TABLE(MON_GET_TABLESPACE('',-2)) AS T
ORDER BY pool_data_p_reads DESC
WITH UR;

--8-DistribuicaoTableSpaces  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT MGC.TBSP_NAME
        , MGT.TBSP_PAGE_SIZE /1024 || 'K' AS PAGESIZE 
        , (MGT.TBSP_USED_PAGES * MGT.TBSP_PAGE_SIZE)/1024/1024 AS TBSP_SIZE_MB
        , CASE
                WHEN LOCATE('db2inst1/NODE', MGC.CONTAINER_NAME) > 0
                THEN SUBSTRING(MGC.CONTAINER_NAME, 0, LOCATE('db2inst1/NODE', MGC.CONTAINER_NAME), OCTETS)
                ELSE CONTAINER_NAME
          END AS FS_PATH
        , MGC.FS_TOTAL_SIZE/1024/1024/1024 AS FS_TOTAL_SIZE_GB
        , MGC.FS_USED_SIZE/1024/1024/1024 AS FS_USED_SIZE_GB
        , CAST((MGC.FS_USED_SIZE * 100.0) / MGC.FS_TOTAL_SIZE AS DECIMAL(10,2)) AS PCT_FS_USED
        , (MGC.TOTAL_PAGES * MGT.TBSP_PAGE_SIZE)/1024/1024 AS TBSP_CONTAINER_SIZE_MB
        , CAST(((MGC.TOTAL_PAGES * MGT.TBSP_PAGE_SIZE) * 100.0) / MGC.FS_USED_SIZE AS DECIMAL(10,2)) AS PCT_TBS_CONTAINER_USED
        , CASE
                WHEN LOCATE('db2inst1/NODE', MGC.CONTAINER_NAME) > 0
                THEN SUBSTRING(MGC.CONTAINER_NAME, LOCATE((CURRENT_SERVER || '/T'), MGC.CONTAINER_NAME), LENGTH(MGC.CONTAINER_NAME,OCTETS), OCTETS)
                ELSE CONTAINER_NAME
          END AS FILE_NAME_CONTAINER
        , MGT.TBSP_REBALANCER_MODE, MGT.TBSP_USING_AUTO_STORAGE, MGT.TBSP_AUTO_RESIZE_ENABLED, MGT.TBSP_STATE, MGT.RECLAIMABLE_SPACE_ENABLED
        , MGC.USABLE_PAGES, MGC.FS_ID, MGC.DB_STORAGE_PATH_ID
        , MGC.CONTAINER_NAME
FROM TABLE(MON_GET_CONTAINER(NULL, -2)) MGC
INNER JOIN TABLE(MON_GET_TABLESPACE(NULL, -2)) MGT
        ON MGC.TBSP_NAME = MGT.TBSP_NAME
--WHERE MGC.TBSP_NAME IN ('CTBTBS0012014') 
ORDER BY PCT_TBS_CONTAINER_USED DESC
WITH UR;

--9-Tabelas  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH MonGetRow AS
    ( SELECT VARCHAR(tabschema,20)          AS tabschema,
            VARCHAR(tabname,20)             AS tabname,
            SUM(rows_read)                  AS total_rows_read,
            SUM(rows_inserted)              AS total_rows_inserted,
            SUM(rows_updated)               AS total_rows_updated,
            SUM(rows_deleted)               AS total_rows_deleted, 
            SUM(TABLE_SCANS) AS table_scans,
            SUM(OVERFLOW_ACCESSES) AS OVERFLOW_ACCESSES,
            SUM(OVERFLOW_CREATES) AS OVERFLOW_CREATES ,
            SUM(PAGE_REORGS) AS PAGE_REORGS                     
        FROM TABLE(MON_GET_TABLE('','',-2)) AS t
        GROUP BY tabschema,
            tabname
        ORDER BY total_rows_read DESC
    )
    ,
    MonGetTable AS
    ( SELECT DISTINCT VARCHAR(T.tabschema,20)          AS tabschema,
            VARCHAR(T.tabname,20)             AS tabname,
            MGR.total_rows_read AS ROWS_READ,
            MGR.total_rows_inserted AS rows_inserted,
            MGR.total_rows_updated AS rows_updated,
            MGR.total_rows_deleted AS rows_deleted,
            T.TAB_TYPE,
            MGR.TABLE_SCANS,
            MGR.OVERFLOW_ACCESSES,
            MGR.OVERFLOW_CREATES ,
            MGR.PAGE_REORGS,
            T.TBSP_ID,
            T.INDEX_TBSP_ID,
            T.LONG_TBSP_ID,
            DATA_OBJECT_L_PAGES, 
            LOB_OBJECT_L_PAGES, 
            INDEX_OBJECT_L_PAGES, 
            (SELECT DBI.DB_SIZE / (1024*1024) FROM SYSTOOLS.STMG_DBSIZE_INFO DBI) AS DB_SIZE_MB
        FROM TABLE (MON_GET_TABLE('','',-2)) AS T
        INNER JOIN MonGetRow                AS MGR
        ON  T.tabschema = MGR.tabschema
        AND T.tabname = MGR.tabname
    )
SELECT DISTINCT
        T.TABSCHEMA, T.TABNAME, VARCHAR(TBS.TBSP_PAGE_SIZE/1024) || 'K' AS PAGE_SIZE
        --,DECIMAL((((FLOAT(st.npages)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2) * 100)/DB_SIZE_MB), 15,2) AS Percent_Use 
        ,DECIMAL(FLOAT(T.DATA_OBJECT_L_PAGES)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2)  AS data_used_mb
        ,DECIMAL(FLOAT(T.INDEX_OBJECT_L_PAGES)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2)  AS index_used_mb
        ,DECIMAL(FLOAT(T.LOB_OBJECT_L_PAGES)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2)  AS lob_used_mb
        ,ST.CARD, ST.COLCOUNT, ST.AVGROWSIZE, ST.NPAGES, ST.FPAGES
        ,T.TAB_TYPE
        ,TBS.TBSP_NAME
        ,IDX_TBS.TBSP_NAME AS IDX_TBSP_NAME
        ,LONG_TBS.TBSP_NAME AS LONG_TBSP_NAME
        ,T.TABLE_SCANS
        --, T.OVERFLOW_ACCESSES, T.OVERFLOW_CREATES
        ,T.ROWS_READ, T.ROWS_INSERTED, T.ROWS_UPDATED, T.ROWS_DELETED
        ,T.PAGE_REORGS, ST.STATS_TIME
        ,T.DATA_OBJECT_L_PAGES 
        ,T.LOB_OBJECT_L_PAGES 
        ,T.INDEX_OBJECT_L_PAGES
        ,DECIMAL(FLOAT(st.npages)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2)  AS used_mb_syscat
        ,DECIMAL(FLOAT(st.fpages)/ ( 1024 / (TBS.TBSP_PAGE_SIZE/1024)),9,2)  AS allocated_mb_syscat
FROM MonGetTable AS T
INNER JOIN SYSCAT.TABLES AS ST 
        ON T.TABNAME = ST.TABNAME AND T.TABSCHEMA = ST.TABSCHEMA
INNER JOIN TABLE(MON_GET_TABLESPACE('',-2)) AS TBS
        ON T.TBSP_ID = TBS.TBSP_ID
LEFT JOIN TABLE(MON_GET_TABLESPACE('',-2)) AS IDX_TBS
        ON T.INDEX_TBSP_ID = IDX_TBS.TBSP_ID
LEFT JOIN TABLE(MON_GET_TABLESPACE('',-2)) AS LONG_TBS
        ON T.LONG_TBSP_ID = LONG_TBS.TBSP_ID
WHERE T.TABSCHEMA NOT LIKE '%SYS%'
ORDER BY T.TABNAME
WITH UR;

--10-Indices  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH IDXSUM AS 
        (
                SELECT TABSCHEMA, TABNAME, IID
                , MAX(DATA_PARTITION_ID) AS MAX_PARTITION_ID
                , SUM(NLEAF) AS NLEAF, SUM(INDEX_SCANS) AS INDEX_SCANS, SUM(INDEX_ONLY_SCANS) AS INDEX_ONLY_SCANS, SUM(INT_NODE_SPLITS) AS INT_NODE_SPLITS
                , SUM(BOUNDARY_LEAF_NODE_SPLITS) AS BOUNDARY_LEAF_NODE_SPLITS, SUM(NONBOUNDARY_LEAF_NODE_SPLITS) AS NONBOUNDARY_LEAF_NODE_SPLITS, SUM(PAGE_ALLOCATIONS) AS PAGE_ALLOCATIONS
                , SUM(INDEX_JUMP_SCANS) AS INDEX_JUMP_SCANS
                FROM TABLE(MON_GET_INDEX('','', -2)) as T
                WHERE TABSCHEMA NOT LIKE '%SYS%'
                GROUP BY TABSCHEMA, TABNAME, IID
        )
SELECT SI.INDNAME, T.TABSCHEMA,T.TABNAME,  T.IID
, SI.COLNAMES, T.DATA_PARTITION_ID, T.NLEAF, T.NLEVELS
,IDXSUM.NLEAF ,IDXSUM.INDEX_SCANS ,IDXSUM.INT_NODE_SPLITS ,IDXSUM.BOUNDARY_LEAF_NODE_SPLITS 
,IDXSUM.NONBOUNDARY_LEAF_NODE_SPLITS ,IDXSUM.PAGE_ALLOCATIONS  ,IDXSUM.INDEX_JUMP_SCANS
,SI.UNIQUERULE
,SI.INDEXTYPE, SI.CLUSTERFACTOR, SI.CLUSTERRATIO, SI.SEQUENTIAL_PAGES, SI.DENSITY, SI.REVERSE_SCANS
,SI.COMPRESSION, SI.NUMRIDS, SI.NUMRIDS_DELETED, SI.LASTUSED, SI.PAGESPLIT
FROM TABLE(MON_GET_INDEX('','', -2)) as T
INNER JOIN IDXSUM
        ON IDXSUM.TABSCHEMA = T.TABSCHEMA AND IDXSUM.TABNAME = T.TABNAME AND IDXSUM.IID = T.IID
INNER JOIN SYSCAT.INDEXES SI
        ON T.TABNAME = SI.TABNAME AND T.IID = SI.IID
WHERE T.TABSCHEMA NOT LIKE '%SYS%'
ORDER BY SI.INDNAME
WITH UR;

--11-Log  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT
    T.TOTAL_LOG_AVAILABLE / 1024 / 1024 / 1024.0  AS TOTAL_LOG_AVAILABLE_GB
    ,(T.TOTAL_LOG_USED * 100) / (T.TOTAL_LOG_USED + T.TOTAL_LOG_AVAILABLE)||'%' AS PERCENT_LOG_USED
    ,C.UOW_START_TIME as OLDER_UOW_START_TIME
    ,C.SESSION_AUTH_ID as OLDER_SESSION_AUTH_ID
    ,C.APPLICATION_ID as OLDER_APPLICATION_ID
    ,C.WORKLOAD_OCCURRENCE_STATE
    ,B.STMT_TEXT
    ,T.APPLID_HOLDING_OLDEST_XACT as OLDER_APPHANDLE
    ,T.FIRST_ACTIVE_LOG
    ,T.LAST_ACTIVE_LOG
    ,T.CURRENT_ACTIVE_LOG
    ,T.CURRENT_ARCHIVE_LOG
    ,T.CURRENT_LSO, T.CURRENT_LSN,T.OLDEST_TX_LSN, T.APPLID_HOLDING_OLDEST_XACT 
    ,T.LOG_TO_REDO_FOR_RECOVERY,T.NUM_LOGS_AVAIL_FOR_RENAME 
    ,T.CUR_COMMIT_DISK_LOG_READS, T.CUR_COMMIT_TOTAL_LOG_READS, T.CUR_COMMIT_LOG_BUFF_LOG_READS
    ,T.LOG_READS, T.LOG_WRITES, T.LOG_READ_TIME, T.LOG_WRITE_TIME, NUM_LOG_WRITE_IO, T.NUM_LOG_READ_IO
FROM
    TABLE(SYSPROC.MON_GET_TRANSACTION_LOG(-2)) AS T
LEFT JOIN SYSIBMADM.MON_CURRENT_SQL AS B
        ON T.APPLID_HOLDING_OLDEST_XACT = B.APPLICATION_HANDLE
LEFT JOIN TABLE(SYSPROC.MON_GET_UNIT_OF_WORK(null,-2)) AS C 
        ON T.APPLID_HOLDING_OLDEST_XACT = C.APPLICATION_HANDLE
WITH UR;

--12-UOWs  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT 
 T.APPLICATION_HANDLE, T.APPLICATION_ID,UOW_ID, T.WORKLOAD_OCCURRENCE_STATE, T.CLIENT_WRKSTNNAME, T.SESSION_AUTH_ID
,T.UOW_START_TIME, T.UOW_LOG_SPACE_USED/1024 AS UOW_LOG_SPACE_USED_KB, T.TOTAL_CPU_TIME, T.TOTAL_WAIT_TIME,T.SORT_OVERFLOWS
,T.ROWS_MODIFIED, T.ROWS_READ, T.ROWS_RETURNED
,T.TOTAL_COMPILE_TIME
,T.TOTAL_COMMIT_TIME, T.TOTAL_ROLLBACK_TIME
,T.LOCK_ESCALS, T.LOCK_TIMEOUTS, T.LOCK_WAIT_TIME, T.LOCK_WAITS, T.LOG_BUFFER_WAIT_TIME, T.LOG_DISK_WAIT_TIME, T.LOG_DISK_WAITS_TOTAL
,T.TCPIP_RECV_VOLUME, T.TCPIP_SEND_VOLUME, T.TCPIP_RECV_WAIT_TIME, T.TCPIP_RECVS_TOTAL, T.TCPIP_SEND_WAIT_TIME, T.TCPIP_SENDS_TOTAL
,T.TOTAL_RUNSTATS_TIME,T.TOTAL_RUNSTATS, T.TOTAL_REORG_TIME, T.TOTAL_REORGS, T.TOTAL_REORGS, T.TOTAL_LOAD_TIME, T.TOTAL_LOADS, T.TOTAL_SYNC_RUNSTATS_TIME ,T.TOTAL_SYNC_RUNSTATS
,T.INTRA_PARALLEL_STATE
FROM TABLE(MON_GET_UNIT_OF_WORK(NULL, -1)) AS T
ORDER BY WORKLOAD_OCCURRENCE_STATE
WITH UR;

--13-PKG_Cache_Last_Hour  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH C AS 
(
    SELECT SUM(TOTAL_CPU_TIME) AS SUM_TOTALCPUTime
    FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL,NULL, -1)) AS T
)
SELECT TOTAL_CPU_TIME/NUM_EXEC_WITH_METRICS as AVG_CPU_TIME
,CASE
    WHEN T.TOTAL_CPU_TIME <> 0 THEN (T.TOTAL_CPU_TIME * 100.0) / C.SUM_TOTALCPUTime --DECIMAL((T.TOTAL_CPU_TIME*100)/C.TotalCPUTime,10,2)
    ELSE NULL
 END AS PercentUsoCPU
,T.QUERY_COST_ESTIMATE
,T.STMT_TEXT
,T.EFFECTIVE_ISOLATION, NUM_EXECUTIONS, NUM_EXEC_WITH_METRICS
,T.PREP_TIME, T.TOTAL_CPU_TIME, STMT_EXEC_TIME
,T.TOTAL_ACT_TIME, T.TOTAL_ACT_WAIT_TIME
,CASE
    WHEN T.TOTAL_ACT_TIME = 0 THEN T.TOTAL_ACT_TIME
    WHEN T.TOTAL_ACT_TIME <> 0 THEN (T.TOTAL_ACT_WAIT_TIME * 100) / T.TOTAL_ACT_TIME
 END AS Percent_WaitAct
,T.ROWS_MODIFIED, T.ROWS_READ, T.ROWS_RETURNED
,T.POOL_DATA_L_READS, T.POOL_INDEX_L_READS, T.POOL_TEMP_DATA_L_READS, T.POOL_TEMP_INDEX_L_READS
,T.POOL_DATA_P_READS, T.POOL_INDEX_P_READS, T.POOL_TEMP_DATA_P_READS, T.POOL_TEMP_INDEX_P_READS
,T.POOL_DATA_WRITES, T.POOL_INDEX_WRITES
,T.LOG_BUFFER_WAIT_TIME, T.LOG_DISK_WAIT_TIME, T.LOG_DISK_WAITS_TOTAL, T.NUM_LOG_BUFFER_FULL
,T.TOTAL_SORTS, T.SORT_OVERFLOWS
,T.LOCK_ESCALS, T.LOCK_WAITS, T.LOCK_TIMEOUTS
,T.STMT_TYPE_ID,STMT_PKG_CACHE_ID, T.INSERT_TIMESTAMP
,T.EVMON_WAITS_TOTAL
,LAST_METRICS_UPDATE
,CAST(T.STMT_TEXT AS VARCHAR(600)) AS CONSULTA
--,T.NUM
FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL,NULL, -1)) AS T
     ,C
WHERE T.NUM_EXEC_WITH_METRICS <> 0
--AND DAY(INSERT_TIMESTEAMP) = DAY(CURRENT_TIMESTAMP)
AND HOUR(INSERT_TIMESTAMP) BETWEEN HOUR(CURRENT_TIMESTAMP)-1 AND HOUR(CURRENT_TIMESTAMP)
ORDER BY AVG_CPU_TIME DESC
WITH UR;

--14-PKG_Cache_Current_SQL  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH A1 AS 
(SELECT application_handle,activity_id, uow_id FROM TABLE(wlm_get_workload_occurrence_activities(null, -1)) 
    WHERE activity_id > 0 
), 
GAD AS 
(SELECT A1.application_handle, 
          A1.activity_id, 
          A1.uow_id, 
          BIGINT(STMT_PKG_CACHE_ID) AS STMT_PKG_CACHE_ID 
  FROM A1, 
        TABLE(MON_GET_ACTIVITY_DETAILS(A1.application_handle, A1.uow_id,A1.activity_id, -1)) AS ACTDETAILS, 
        XMLTABLE (XMLNAMESPACES( DEFAULT 'http://www.ibm.com/xmlns/prod/db2/mon'), 
         '$actmetrics/db2_activity_details' 
         PASSING XMLPARSE(DOCUMENT ACTDETAILS.DETAILS) AS "actmetrics" 
         COLUMNS 
         "STMT_TEXT" VARCHAR(1024) PATH 'stmt_text', 
         "TOTAL_ACT_TIME" INTEGER PATH 'activity_metrics/total_act_time', 
         "TOTAL_ACT_WAIT_TIME" INTEGER PATH 'activity_metrics/total_act_wait_time', 
         "STMT_PKG_CACHE_ID" BIGINT PATH 'stmt_pkg_cache_id') 
         AS ACTMETRICS
 ), 
C AS 
(
    SELECT SUM(TOTAL_CPU_TIME) AS SUM_TOTALCPUTime
    FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL,NULL, -1)) AS T
)
SELECT STMT_PKG_CACHE_ID
,T.QUERY_COST_ESTIMATE
,CASE
    WHEN T.NUM_EXEC_WITH_METRICS <> 0 THEN T.TOTAL_CPU_TIME/T.NUM_EXEC_WITH_METRICS
    ELSE NULL
 END AS AVG_CPU_TIME
,CASE
    WHEN T.TOTAL_CPU_TIME <> 0 THEN (T.TOTAL_CPU_TIME * 100.0) / C.SUM_TOTALCPUTime --DECIMAL((T.TOTAL_CPU_TIME*100)/C.TotalCPUTime,10,2)
    ELSE NULL
 END AS PercentUsoCPU
,T.STMT_TEXT
,T.EFFECTIVE_ISOLATION, NUM_EXECUTIONS, NUM_EXEC_WITH_METRICS
,T.PREP_TIME, T.TOTAL_CPU_TIME, STMT_EXEC_TIME
, T.TOTAL_ACT_TIME, T.TOTAL_ACT_WAIT_TIME
, CASE
    WHEN T.TOTAL_ACT_TIME = 0 THEN T.TOTAL_ACT_TIME
    WHEN T.TOTAL_ACT_TIME <> 0 THEN (T.TOTAL_ACT_WAIT_TIME * 100) / T.TOTAL_ACT_TIME
  END AS Percent_WaitAct
,T.ROWS_MODIFIED, T.ROWS_READ, T.ROWS_RETURNED
,T.POOL_DATA_L_READS, T.POOL_INDEX_L_READS, T.POOL_TEMP_DATA_L_READS, T.POOL_TEMP_INDEX_L_READS
,T.POOL_DATA_P_READS, T.POOL_INDEX_P_READS, T.POOL_TEMP_DATA_P_READS, T.POOL_TEMP_INDEX_P_READS
,T.POOL_DATA_WRITES, T.POOL_INDEX_WRITES
,T.LOG_BUFFER_WAIT_TIME, T.LOG_DISK_WAIT_TIME, T.LOG_DISK_WAITS_TOTAL, T.NUM_LOG_BUFFER_FULL
,T.TOTAL_SORTS, T.SORT_OVERFLOWS
,T.LOCK_ESCALS, T.LOCK_WAITS, T.LOCK_TIMEOUTS
,T.STMT_TYPE_ID, T.INSERT_TIMESTAMP
,T.EVMON_WAITS_TOTAL
,LAST_METRICS_UPDATE
,CAST(T.STMT_TEXT AS VARCHAR(600)) AS CONSULTA
FROM TABLE(MON_GET_PKG_CACHE_STMT (NULL, NULL,NULL, -1)) AS T
     ,C
WHERE BIGINT(T.STMT_PKG_CACHE_ID) IN (SELECT STMT_PKG_CACHE_ID FROM GAD)
ORDER BY AVG_CPU_TIME DESC
WITH UR;

--15-Containers  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT 
T.tbsp_name
,T.container_name
,T.total_pages
,(T.total_pages*TS.TBSP_PAGE_SIZE)/(1024*1024) as total_pages_mb
,T.usable_pages
,CASE WHEN T.usable_pages > 0
        THEN DEC(100*(FLOAT(T.usable_pages)/FLOAT(T.total_pages)),5,2)
        ELSE DEC(-1,5,2)
 END as PagesUtilization
,T.fs_used_size/1024/1024/1024 AS fs_used_size_GB
,T.fs_total_size/1024/1024/1024 as fs_total_size_GB
,CASE WHEN T.fs_total_size > 0
        THEN DEC(100*(FLOAT(T.fs_used_size)/FLOAT(T.fs_total_size)),5,2)
        ELSE DEC(-1,5,2)
 END as fs_utilization
,T.pages_read
,T.pages_written
,T.pool_read_time
,T.pool_write_time
,T.container_type
,T.container_id
,T.tbsp_id
,T.fs_id
,T.db_storage_path_id
FROM TABLE(MON_GET_CONTAINER('',-1)) AS T
INNER JOIN TABLE(MON_GET_TABLESPACE('',-2)) AS TS
        ON T.TBSP_ID = TS.TBSP_ID
WITH UR;
 
--16-DB_HISTORY  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
SELECT
	CURRENT SERVER as "Database"
	,timestampdiff(4,char(timestamp(end_time)-timestamp(start_time))) as "Durantion(min)"
	,timestampdiff(8,char(timestamp(end_time)-timestamp(start_time))) as "Durantion(hour)"
	,timestamp(start_time) as "Inicio"
	,seqnum
	,timestamp(end_time) as "Final"
        ,CASE
		WHEN OPERATION = 'A' THEN 'Add Table Space' 
		WHEN OPERATION = 'B' THEN 'Backup'
		WHEN OPERATION = 'C' THEN 'Load Copy'
		WHEN OPERATION = 'D' THEN 'Dropped Table'
		WHEN OPERATION = 'F' THEN 'RollFforward'
		WHEN OPERATION = 'G' THEN 'Reorganize Table'
		WHEN OPERATION = 'L' THEN 'Load'
		WHEN OPERATION = 'N' THEN 'Rename Table Space'
		WHEN OPERATION = 'O' THEN 'Drop Table Space'
		WHEN OPERATION = 'Q' THEN 'Quiesce'
		WHEN OPERATION = 'R' THEN 'Restore'
		WHEN OPERATION = 'T' THEN 'Alter Table Space'
		WHEN OPERATION = 'U' THEN 'Unload'
		WHEN OPERATION = 'X' THEN 'Archive Logs'
	END Operation
	,CASE
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'D' THEN 'Delta Offline'
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'E' THEN 'Delta Online'
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'F' THEN 'Offline'
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'I' THEN 'Incremental Offline'
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'N' THEN 'Online'
		WHEN OPERATION = 'B' AND OPERATIONTYPE = 'O' THEN 'Incremental Online'
		WHEN OPERATION = 'F' AND OPERATIONTYPE = 'E' THEN 'End of Logs'
		WHEN OPERATION = 'F' AND OPERATIONTYPE = 'P' THEN 'Point in Time'
		WHEN OPERATION = 'L' AND OPERATIONTYPE = 'I' THEN 'Insert'
		WHEN OPERATION = 'L' AND OPERATIONTYPE = 'R' THEN 'Replace'
		WHEN OPERATION = 'Q' AND OPERATIONTYPE = 'S' THEN 'Quiesce Share'
		WHEN OPERATION = 'Q' AND OPERATIONTYPE = 'U' THEN 'Quiesce Update'
		WHEN OPERATION = 'Q' AND OPERATIONTYPE = 'X' THEN 'Quiesce Exclusive'
		WHEN OPERATION = 'Q' AND OPERATIONTYPE = 'Z' THEN 'Quiesce Reset'
		WHEN OPERATION = 'R' AND OPERATIONTYPE = 'F' THEN 'Offline'
		WHEN OPERATION = 'R' AND OPERATIONTYPE = 'I' THEN 'Incremental Offline'
		WHEN OPERATION = 'R' AND OPERATIONTYPE = 'N' THEN 'Online'
		WHEN OPERATION = 'R' AND OPERATIONTYPE = 'O' THEN 'Incremental Online'
		WHEN OPERATION = 'R' AND OPERATIONTYPE = 'R' THEN 'Rebuild'
		WHEN OPERATION = 'T' AND OPERATIONTYPE = 'C' THEN 'Add Containers'
		WHEN OPERATION = 'T' AND OPERATIONTYPE = 'R' THEN 'Rebalance'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = 'F' THEN 'Fail Archive Path'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = 'M' THEN 'Mirror Log Path'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = 'N' THEN 'Forced Truncation via ARCHIVE LOG command'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = 'P' THEN 'Primary Log Path'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = '1' THEN 'First Log Archive Method'
		WHEN OPERATION = 'X' AND OPERATIONTYPE = '2' THEN 'Second Log Archive Method'
		ELSE 'NULL'
	END OperationType
	,CASE 
		WHEN OBJECTTYPE = 'D' THEN 'Full Database'
		WHEN OBJECTTYPE = 'I' THEN 'Index'
		WHEN OBJECTTYPE = 'P' THEN 'Table Space'
		WHEN OBJECTTYPE = 'R' THEN 'Range Partition Table'
		WHEN OBJECTTYPE = 'T' THEN 'Table'
		ELSE 'NULL'
	END ObjectType
	,CASE
		WHEN OBJECTTYPE = 'A' THEN 'TSM'
		WHEN OBJECTTYPE = 'C' THEN 'Client'
		WHEN OBJECTTYPE = 'D' THEN 'Disk'
		WHEN OBJECTTYPE = 'F' THEN 'Snapshot Backup'
		WHEN OBJECTTYPE = 'K' THEN 'Diskette'
		WHEN OBJECTTYPE = 'L' THEN 'Local'
		WHEN OBJECTTYPE = 'N' THEN 'Generated Internally by DB2'
		WHEN OBJECTTYPE = 'O' THEN 'Other Vendor Device Support'
		WHEN OBJECTTYPE = 'P' THEN 'Pipe'
		WHEN OBJECTTYPE = 'R' THEN 'Remote Fetch Data'
		WHEN OBJECTTYPE = 'S' THEN 'Server'
		WHEN OBJECTTYPE = 'T' THEN 'Tape'
		WHEN OBJECTTYPE = 'U' THEN 'User Exit'
		WHEN OBJECTTYPE = 'X' THEN 'XOpen XBSA Interface'
		ELSE 'NULL'
	END DeviceType
	,LOCATION
	,CASE
		WHEN ENTRY_STATUS = 'A' THEN 'Active'
		WHEN ENTRY_STATUS = 'D' THEN 'Deleted (future use)'
		WHEN ENTRY_STATUS = 'E' THEN 'Expired'
		WHEN ENTRY_STATUS = 'I' THEN 'Inative'
		WHEN ENTRY_STATUS = 'N' THEN 'Not Yet Commited'
		WHEN ENTRY_STATUS = 'Y' THEN 'Commited or Active'
		ELSE 'NULL'
	END Entry_Status
	,SEQNUM, EID,FIRSTLOG, LASTLOG, SQLSTATE 
	,TBSPNAMES, TABSCHEMA, TABNAME
	,BACKUP_ID
	,COMMENT
	,CMD_TEXT
	,SQLWARN
	,SQLERRP, SQLERRD1,SQLERRD2,SQLERRD3,SQLERRD4,SQLERRD5,SQLERRD6,SQLWARN
	--, *
FROM SYSIBMADM.DB_HISTORY
WHERE  
timestamp(END_TIME) > CURRENT_TIMESTAMP - 30 DAYS
ORDER BY timestamp(start_time) DESC
WITH UR;

--17-Latches  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH C AS 
   (
        SELECT SUM(TOTAL_EXTENDED_LATCH_WAITS) AS SUM_TOTAL_EXTENDED_LATCH_WAITS, SUM(TOTAL_EXTENDED_LATCH_WAIT_TIME) AS SUM_TOTAL_EXTENDED_LATCH_WAIT_TIME 
        FROM TABLE(SYSPROC.MON_GET_EXTENDED_LATCH_WAIT(-1))
   )
SELECT T.LATCH_NAME
,TOTAL_EXTENDED_LATCH_WAITS
,DECIMAL((TOTAL_EXTENDED_LATCH_WAITS * 100)/SUM_TOTAL_EXTENDED_LATCH_WAITS,15,2) AS PERCENT_TOTAL_EXTENDED_LATCH_WAITS
,TOTAL_EXTENDED_LATCH_WAIT_TIME
,DECIMAL((TOTAL_EXTENDED_LATCH_WAIT_TIME * 100)/SUM_TOTAL_EXTENDED_LATCH_WAIT_TIME,15,2) AS PERCENT_TOTAL_EXTENDED_LATCH_WAIT_TIME
FROM C,
TABLE(SYSPROC.MON_GET_EXTENDED_LATCH_WAIT(-1)) T
ORDER BY TOTAL_EXTENDED_LATCH_WAITS DESC, TOTAL_EXTENDED_LATCH_WAIT_TIME DESC
WITH UR;

--18-LockWaits  ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
WITH AW AS (
                SELECT lock_name,
                        hld_member,
                        lock_status,
                        hld_application_handle
                FROM TABLE (MON_GET_APPL_LOCKWAIT(NULL, -2)) T
          ),MGL AS (
SELECT GL.APPLICATION_HANDLE ,GL.LOCK_NAME ,GL.LOCK_OBJECT_TYPE_ID  
,GL.LOCK_OBJECT_TYPE  ,GL.LOCK_MODE  ,GL.LOCK_CURRENT_MODE  ,GL.LOCK_STATUS  ,GL.LOCK_ATTRIBUTES   
,GL.LOCK_RELEASE_FLAGS  ,GL.LOCK_RRIID  ,GL.LOCK_COUNT  ,GL.LOCK_HOLD_COUNT  ,GL.TBSP_ID  ,GL.TAB_FILE_ID  
FROM AW,
TABLE (MON_GET_LOCKS(
        CLOB('<lock_name>' || AW.lock_name || '</lock_name>'),
         -2)) GL
)
SELECT LW.TABSCHEMA, LW.TABNAME,LW.LOCK_OBJECT_TYPE, LW.LOCK_WAIT_ELAPSED_TIME
,LW.LOCK_MODE, LW.LOCK_CURRENT_MODE, LW.LOCK_MODE_REQUESTED
,MGL.LOCK_RRIID  ,MGL.LOCK_COUNT  ,MGL.LOCK_HOLD_COUNT
,LW.HLD_APPLICATION_HANDLE ,LW.HLD_USERID, LW.HLD_APPLICATION_NAME
,LW.REQ_APPLICATION_HANDLE ,LW.REQ_USERID, LW.REQ_APPLICATION_NAME ,LW.REQ_AGENT_TID
,LW.HLD_CURRENT_STMT_TEXT
,LW.REQ_STMT_TEXT
,LW.LOCK_NAME
,VARCHAR(LW.HLD_CURRENT_STMT_TEXT) AS HLD_CURRENT_STMT
,VARCHAR(LW.REQ_STMT_TEXT) AS REQ_STMT
FROM SYSIBMADM.MON_LOCKWAITS LW
LEFT JOIN MGL ON LW.LOCK_NAME = MGL.LOCK_NAME AND LW.HLD_APPLICATION_HANDLE = MGL.APPLICATION_HANDLE
WITH UR;

--19-LockChain ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

WITH LockChain (AppHandle_LockRequester, AppName_LockRequester, UserId_LockRequester, AppHandle_LockOwner
        , AppName_LockOwner, UserID_LockOwner, LOCK_WAIT_ELAPSED_TIME, TABSCHEMA, TABNAME, Nivel, LockGraph, SQLStatement_LockOwner)
AS (
    SELECT
        REQ_APPLICATION_HANDLE AS AppHandle_LockRequester
        , REQ_Application_Name AS AppName_LockRequester
        , REQ_USERID AS UserId_LockRequester        
        , HLD_APPLICATION_HANDLE AS AppHandle_LockOwner
        , HLD_Application_Name AS AppName_LockOwner
        , HLD_USERID AS UserID_LockOwner        
        , LOCK_WAIT_ELAPSED_TIME
        , TABSCHEMA
        , TABNAME        
        , 1 AS Nivel
        , CAST(HLD_APPLICATION_HANDLE AS VARCHAR(10)) || ' --> ' || CAST(REQ_APPLICATION_HANDLE AS VARCHAR(10)) AS LockGraph
        , COALESCE(LEFT(HLD_CURRENT_STMT_TEXT, 4000), '<Instrucao SQL nao capturada>') AS SQLStatement_LockOwner
        --, LW.*
    FROM SYSIBMADM.MON_LOCKWAITS AS LW
        
    UNION ALL
    
    SELECT 
        LW.REQ_APPLICATION_HANDLE AS AppHandle_LockRequester
        , LW.REQ_Application_Name AS AppName_LockRequester
        , LW.REQ_USERID AS UserId_LockRequester        
        , LW.HLD_APPLICATION_HANDLE AS AppHandle_LockOwner
        , LW.HLD_Application_Name AS AppName_LockOwner
        , LW.HLD_USERID AS UserID_LockOwner
        , LW.LOCK_WAIT_ELAPSED_TIME
        , LW.TABSCHEMA
        , LW.TABNAME        
        , 1 + LC.Nivel AS Nivel
        , CAST(LW.HLD_APPLICATION_HANDLE AS VARCHAR(10)) || ' --> ' || LC.LockGraph AS LockGraph
        , COALESCE(LEFT(LW.HLD_CURRENT_STMT_TEXT, 4000), '<Instrucao SQL nao capturada>') AS SQLStatement_LockOwner
    FROM SYSIBMADM.MON_LOCKWAITS AS LW
    , LockChain AS LC
    where LC.AppHandle_LockOwner = LW.REQ_APPLICATION_HANDLE
        -- Condição de parada
        AND LC.Nivel < 15    
)
SELECT
    L.AppHandle_LockRequester
    , L.AppName_LockRequester
    , L.UserId_LockRequester
    , L.AppHandle_LockOwner
    , L.AppName_LockOwner
    , L.UserID_LockOwner
    , L.LOCK_WAIT_ELAPSED_TIME AS DuracaoBloqueio_Segundos
    , L.TABSCHEMA AS Esquema
    , L.TABNAME AS Objeto
    , L.Nivel
    , L.LockGraph AS Grafico
    , L.SQLStatement_LockOwner AS InstrucaoSQL
FROM LockChain AS L
ORDER BY Nivel DESC, LOCK_WAIT_ELAPSED_TIME DESC, AppHandle_LockOwner ASC
WITH UR;

--20-Utilities ::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::

SELECT SU.UTILITY_TYPE, SU.UTILITY_PRIORITY, SU.UTILITY_DESCRIPTION, SU.UTILITY_DBNAME
        , (DEC(DEC(SUP.PROGRESS_COMPLETED_UNITS,20,2) / DEC(SUP.PROGRESS_TOTAL_UNITS,20,2),10,2) * 100.0) AS PROGRESS_COMPLETED_PERCENT
        , CASE
                WHEN SUP.PROGRESS_WORK_METRIC = 'BYTES'
                THEN SUP.PROGRESS_TOTAL_UNITS /1024/1024
                ELSE SUP.PROGRESS_TOTAL_UNITS /1024/1024
          END AS PROGRES_TOTAL_UNITS_MB
        , CASE
                WHEN SUP.PROGRESS_WORK_METRIC = 'BYTES'
                THEN SUP.PROGRESS_COMPLETED_UNITS /1024/1024
                ELSE SUP.PROGRESS_COMPLETED_UNITS /1024/1024
          END AS PROGRESS_COMPLETED_UNITS_MB
        , SUP.UTILITY_STATE, SUP.PROGRESS_SEQ_NUM
        , SU.UTILITY_START_TIME, SU.SNAPSHOT_TIMESTAMP
FROM SYSIBMADM.SNAPUTIL SU
LEFT JOIN SYSIBMADM.SNAPUTIL_PROGRESS SUP
        ON SU.UTILITY_ID = SUP.UTILITY_ID
;


-- CALL NULLID.COLLECT_CPUSTATS2(1);