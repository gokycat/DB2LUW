--Proc que faz um DDL na base, para entao podermos chamá-la a a partir de uma condicional
/#
CREATE PROCEDURE NULLID.ExecImmed (IN instrucao VARCHAR(1000))
LANGUAGE SQL
BEGIN    
    EXECUTE IMMEDIATE instrucao;
END
#/

--Dropa a tabela se ela existir
/#
BEGIN ATOMIC

    IF ( 
        EXISTS (
            SELECT *
            FROM SYSIBM.TABLES
            WHERE TABLE_NAME = UPPER('Empregado')
                AND TABLE_SCHEMA = UPPER('DB2I101')
                AND TABLE_TYPE = 'BASE TABLE') 
        ) 
    THEN CALL NULLID.ExecImmed('DROP TABLE DB2I101.Empregado');
    END IF;

END
#/

--Criar a tabela
CREATE TABLE Empregado (
EMP_ID INT GENERATED ALWAYS AS IDENTITY 
                         (START WITH 1, INCREMENT BY 1, NO CACHE),
Numero INT,
Nome varchar(40),
Data_Nascimento date,
Salario integer) 
--IN TBSP_TESTE --Essa é um indicativo de qual tablespace voce deseja criar a tabela
;

--Inserir um registro
INSERT INTO Empregado (NUMERO,NOME, DATA_NASCIMENTO, SALARIO)
SELECT 
  1 
	, TRANSLATE(CHAR(BIGINT(RAND() * 10000000000)), 'abcdefgHij', '1234567890')
 	,CURRENT DATE - ((18 * 365) + RAND() * (47 * 365)) DAYS
 	, INTEGER(50000 + RAND() * 90000)
FROM SYSIBM.SYSDUMMY1


--Inserir em massa sem precisar de proc
/#
BEGIN
INSERT INTO Empregado (NUMERO, NOME, DATA_NASCIMENTO, SALARIO)
  WITH
  EMP_IDS (EMP_ID) AS
     (VALUES (1)
      UNION ALL
      SELECT EMP_ID + 1
        FROM EMP_IDS
        WHERE EMP_ID < 10000)
SELECT 
	EMP_ID 
	,TRANSLATE(CHAR(BIGINT(RAND() * 10000000000)), 'abcdefgHij', '1234567890')
 	,CURRENT DATE - ((18 * 365) + RAND() * (47 * 365)) DAYS
 	, INTEGER(50000 + RAND() * 90000)
FROM EMP_IDS;
END
#/