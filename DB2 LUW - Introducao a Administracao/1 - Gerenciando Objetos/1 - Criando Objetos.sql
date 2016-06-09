--************************************ BufferPool **********************************************************

--Criação de bufferpool com tamanho gerenciado pelo STMM
--DROP BUFFERPOOL BP4K
CREATE BUFFERPOOL BP4K SIZE AUTOMATIC PAGESIZE 4K;

-- Verificar a criação do Bufferpool
SELECT * FROM SYSCAT.BUFFERPOOLS P;

-- Verificar a o tamanho e configuração do bufferpool
SELECT B.BP_NAME, B.AUTOMATIC, B.BP_CUR_BUFFSZ, (B.BP_CUR_BUFFSZ * SB.PAGESIZE) / (1024 * 1024) AS BP_MB 
FROM TABLE(MON_GET_BUFFERPOOL(NULL, -1)) B
INNER JOIN SYSCAT.BUFFERPOOLS SB
        ON B.BP_NAME = SB.BPNAME 

--Aqui olhamos a view memory pool
SELECT * FROM TABLE(MON_GET_MEMORY_POOL(NULL, NULL, -2)) T;

--Aqui olhamos o bufferpool pela view memory pool
SELECT DB_NAME, MEMORY_SET_TYPE, MEMORY_POOL_TYPE, MEMORY_POOL_USED / 1024 /1024 AS MEMORY_POOL_USED_MB 
FROM TABLE(MON_GET_MEMORY_POOL(NULL, NULL, -2)) T
WHERE MEMORY_POOL_TYPE = 'BP'
;

ALTER BUFFERPOOL BP4K SIZE 400;

--***************************************** TABLESPACE ***************************************************

CREATE TABLESPACE TBSP_TESTE PAGESIZE 4K BUFFERPOOL BP4K

SELECT * FROM SYSCAT.TABLESPACES
SELECT * FROM TABLE(MON_GET_TABLESPACE(NULL, -2)) T;

SELECT TBSP_NAME, TBSP_CONTENT_TYPE, STORAGE_GROUP_NAME 
FROM TABLE(MON_GET_TABLESPACE(NULL, -2)) T
WHERE 1=1
        AND TBSP_USING_AUTO_STORAGE = 1
        AND STORAGE_GROUP_NAME = 'IBMSTOGROUP'

--***************************************** Storage Group ************************************************

CREATE STOGROUP SG_1 ON '/db2/data/stogroups/sg_1'

CREATE STOGROUP SG_2 ON '/db2/data/stogroups/sg_2'

ALTER STOGROUP SG_1 ADD '/db2/data/stogroups/sg1_path2'

ALTER TABLESPACE TBSP_TESTE USING STOGROUP SG_1;
ALTER TABLESPACE TBSP_TESTE USING STOGROUP IBMSTOGROUP;
--ALTER STOGROUP SG_1 SET AS DEFAULT;
ALTER TABLESPACE IBMDB2SAMPLEREL USING STOGROUP SG_1;


--ALTER TABLESPACE TBSP_TESTE REBALANCE;


SELECT * FROM TABLE(MON_GET_CONTAINER(NULL, -2)) T;
SELECT * FROM SYSCAT.STOGROUPS SG


--***************************************** SO's commands ************************************************

-- db2 list db directory
-- db2 get dbm cfg
-- db2 get db cfg
-- db2top
-- db2pd 
--    -edus
--    -dbptnmem
--    -storagepaths
--    -storagegroups