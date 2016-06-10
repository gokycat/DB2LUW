# Instalacao do DB2

#para Ubuntu pode ser necessário
apt-get install lib32stdc++6 libpam0g:i386 libaio1
ln -s /lib/i386-linux-gnu/libpam.so.0 /lib/libpam.so.0

#acessar a pasta onde descompactou o DB2

#Cria grupos
groupadd db2admin
groupadd db2maint
groupadd db2ctrl
groupadd db2mon

#cria o usuário
useradd -c "Usuário da instância 10.5" -g db2admin -m -d /home/db2i101 db2i101

#Acessa a parta da instalacao, na pasta instance
cd /opt/ibm/db2/V10.1/instance

#Cria a instancia
./db2icrt -u db2i101 db2i101 #ou  : ./db2icrt -a db2srv -u db2i101 db2i101

#Configura a instancia
su - db2i101
db2 update dbm cfg using SVCENAME 50105
db2set DB2COMM=tcpip
db2ls

#Pronto para começar a criacao dos bancos
mkdir /home/db2inst1/databases/SAMPLE/
