#!/bin/bash
set -e

### Detectar IP automaticamente
SERVER_IP=$(curl -s ifconfig.me)

echo "==============================="
echo " IP Detectado: $SERVER_IP"
echo "==============================="

### Senha do banco Zabbix
ZBX_DB_PASS="senha123"

### Senha do root do MySQL (gerar automática se não existir)
MYSQL_ROOT_PASS="root123"

### 1) Atualizar
apt update -y
apt upgrade -y

### 2) Instalar Zabbix + MySQL
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent mysql-server php8.1-fpm

### 3) Ajustar o MySQL para não dar ERRO 1419
echo "⚙ Ajustando MySQL para permitir importação..."

mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';
FLUSH PRIVILEGES;
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

### 4) Criar banco e usuário Zabbix
mysql -uroot -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

### 5) Importar tabelas Zabbix SEM ERROS
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql -uroot -p"$MYSQL_ROOT_PASS" zabbix

### Desativar log_bin_trust_function_creators
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

### 6) Configurar zabbix_server.conf
cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$ZBX_DB_PASS
EOF

### 7) Configurar NGINX
cat <<EOF > /etc/zabbix/nginx.conf
server {
    listen 80;
    server_name $SERVER_IP;

    root /usr/share/zabbix/ui;
    index index.php;

    location / {
        try_files \$uri \$uri/ /index.php;
    }

    location ~ [^/]\.php(/|$) {
        fastcgi_pass unix:/run/php/php8.1-fpm.sock;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF

### 8) Reiniciar serviços
systemctl restart mysql nginx zabbix-server zabbix-agent php8.1-fpm
systemctl enable mysql nginx zabbix-server zabbix-agent php8.1-fpm

echo ""
echo "====================================="
echo " INSTALAÇÃO FINALIZADA!"
echo " Acesse: http://$SERVER_IP"
echo " Usuário: Admin"
echo " Senha: zabbix"
echo "====================================="
