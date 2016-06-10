# Backups no DB2

#dropa o banco e apaga as pastas
db2 connect to sample; db2 force applications all; db2 terminate; db2 deactivate db sample
db2 drop database SAMPLE
rm -Rf /home/db2i101/databases/SAMPL*

#apaga as pastas
mkdir -p /home/db2i101/databases/SAMPLE/logs; mkdir -p /home/db2i101/databases/SAMPLE/log_arch
mkdir -p /home/db2i101/databases/SAMPLE/backups; mkdir -p /home/db2i101/databases/SAMPLE/monitores/db2trc

#cria o banco
time db2sampl -name SAMPLE -dbpath '/home/db2i101/databases/SAMPLE/' -sql -xml -verbose

db2 connect to SAMPLE

#configura o banco para sair do modo de log circular
db2 update db cfg using LOGPRIMARY 200
db2 update db cfg using LOGSECOND 0
db2 update db cfg using NEWLOGPATH '/home/db2i101/databases/SAMPLE/logs'
db2 update db cfg using LOGARCHMETH1 disk:/home/db2i101/databases/SAMPLE/log_arch

#reinicia a instancia para efetivar as configuracoes
db2stop force; db2start

#backup offline
db2 BACKUP DATABASE SAMPLE TO /home/db2i101/databases/SAMPLE/backups/ 

db2 connect to SAMPLE

#Cria um tabela para termos como base
db2 "
CREATE TABLE Backup (
ID INT GENERATED ALWAYS AS IDENTITY 
                         (START WITH 1, INCREMENT BY 1, NO CACHE),
Numero INT,
Descricao varchar(200)
,Horario TIMESTAMP WITH DEFAULT CURRENT_TIMESTAMP
) 
--IN TBSP_TESTE --Essa é um indicativo de qual tablespace voce deseja criar a tabela
"

db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS PRIMEIRO BACKUP FULL OFFLINE')"

#backup online
db2 BACKUP DATABASE SAMPLE ONLINE TO /home/db2i101/databases/SAMPLE/backups/

db2 connect to SAMPLE
db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS O PRIMEIRO BACKUP ONLINE')"

#arquiva o log, mudando a pasta dele, mandando-o para a pasta log_archive
db2 ARCHIVE LOG FOR DATABASE SAMPLE;


db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS O PRIMEIRO ARCHIVE')"


db2 BACKUP DATABASE SAMPLE ONLINE TO /home/db2i101/databases/SAMPLE/backups/

db2 connect to SAMPLE
db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS O SEGUNDO BACKUP ONLINE')"

db2 ARCHIVE LOG FOR DATABASE SAMPLE;

db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS O SEGUNDO ARCHIVE')"

db2 ARCHIVE LOG FOR DATABASE SAMPLE;

db2 "INSERT INTO Backup (NUMERO, DESCRICAO) VALUES (1, 'APOS O TERCEIRO ARCHIVE')"

#guardar os dados da tabela:
ID	NUMERO	DESCRICAO							HORARIO
1	1		APOS PRIMEIRO BACKUP FULL OFFLINE	2016-06-10 13:05:57
2	1		APOS O PRIMEIRO BACKUP ONLINE		2016-06-10 13:06:28
3	1		APOS O PRIMEIRO ARCHIVE				2016-06-10 13:06:39
4	1		APOS O SEGUNDO BACKUP ONLINE		2016-06-10 13:09:38
5	1		APOS O SEGUNDO ARCHIVE				2016-06-10 13:09:49
6	1		APOS O TERCEIRO ARCHIVE				2016-06-10 13:09:59

#guardar os dados da pasta:
db2i101@svrdb2:~> ls -lhtr /home/db2i101/databases/SAMPLE/backups/
total 467M
-rw------- 1 db2i101 db2admin 157M Jun 10 18:05 SAMPLE.0.db2i101.DBPART000.20160610130528.001
-rw------- 1 db2i101 db2admin 155M Jun 10 18:06 SAMPLE.0.db2i101.DBPART000.20160610130608.001
-rw------- 1 db2i101 db2admin 155M Jun 10 18:06 SAMPLE.0.db2i101.DBPART000.20160610130649.001

#dropa o banco e apaga as pastas
db2 connect to sample; db2 force applications all; db2 terminate; db2 deactivate db sample
db2 drop database SAMPLE

#começar o restore:

db2 restore db SAMPLE from /home/db2i101/databases/SAMPLE/backups/ taken at 20160610182056 on '/home/db2i101/databases/SAMPLE/' newlogpath '<Log_Directory>'

db2 restore db SAMPLE from /home/db2i101/databases/SAMPLE/backups/ taken at 20160610182056
db2 "rollforward db SAMPLE to end of backup and stop overflow log path (/home/db2i101/databases/SAMPLE/log_arch)"

db2 "rollforward db SAMPLE to end of logs and stop overflow log path (/home/db2i101/databases/SAMPLE/log_arch)"

db2 "rollforward db SAMPLE to end of logs and stop overflow log path (/home/db2i101/databases/SAMPLE/log_arch)"

db2 "rollforward db SAMPLE to 2016-06-10-13.00.00 using local time and stop overflow log path (/home/db2i101/databases/SAMPLE/log_arch)"
db2 rollforward query status