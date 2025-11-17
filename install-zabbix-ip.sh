#!/bin/bash
set -e

### Detectar IP automaticamente
SERVER_IP=$(curl -s ifconfig.me)

echo "==============================="
echo " IP Detectado: $SERVER_IP"
echo "==============================="

ZBX_DB_PASS="senha123"  # coloque a senha

### 1) Atualizar
apt update -y
apt upgrade -y

### 2) Instalar Zabbix
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
apt update
apt install -y zabbix-server-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent mysql-server php8.1-fpm

### 3) Criar banco
mysql -uroot <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

### 4) Importar tabelas
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p"$ZBX_DB_PASS" zabbix

### 5) Configurar zabbix_server.conf
cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$ZBX_DB_PASS
EOF

### 6) Configurar NGINX usando o IP
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

### 7) Reiniciar serviços
systemctl restart nginx zabbix-server zabbix-agent php8.1-fpm
systemctl enable nginx zabbix-server zabbix-agent php8.1-fpm

echo ""
echo "====================================="
echo " INSTALAÇÃO FINALIZADA!"
echo " Acesse: http://$SERVER_IP"
echo " Usuário: Admin"
echo " Senha: zabbix"
echo "====================================="
