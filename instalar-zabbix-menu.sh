#!/bin/bash
set -e

### ============================================
### Função: Detectar IP público automaticamente
### ============================================
get_ip() {
    SERVER_IP=$(curl -s ifconfig.me)
}


### ============================================
### Função 1: Instalação usando IP da VPS
### ============================================
install_ip() {
    clear
    echo "====================================="
    echo " INSTALAÇÃO ZABBIX 7.4 (USANDO IP)"
    echo "====================================="

    ZBX_DB_PASS="senha123"
    get_ip

    apt update -y
    apt upgrade -y

    wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
    dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
    apt update -y

    apt install -y zabbix-server-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent mysql-server php8.1-fpm

    mysql -uroot <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

    zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p"$ZBX_DB_PASS" zabbix

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

    systemctl restart nginx zabbix-server zabbix-agent php8.1-fpm
    systemctl enable nginx zabbix-server zabbix-agent php8.1-fpm

    echo ""
    echo "====================================="
    echo " ZABBIX INSTALADO COM SUCESSO!"
    echo " Acesse: http://$SERVER_IP"
    echo "====================================="
}



### ============================================
### Função 2: Instalação com domínio + SSL Certbot
### ============================================
install_ssl() {
    clear
    echo "============================================="
    echo " INSTALAÇÃO ZABBIX 7.4 COM SSL AUTOMÁTICO"
    echo "============================================="

    read -p "Digite o domínio para instalar o Zabbix: " ZBX_DOMAIN
    read -p "Digite a senha do banco Zabbix: " ZBX_DB_PASS

    apt update -y
    apt upgrade -y

    wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
    dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
    apt update -y

    apt install -y zabbix-server-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent mysql-server php8.1-fpm python3-certbot-nginx

    mysql -uroot <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

    zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql -uzabbix -p"$ZBX_DB_PASS" zabbix

    cat <<EOF > /etc/zabbix/nginx.conf
server {
    listen 80;
    server_name $ZBX_DOMAIN;

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

    systemctl restart nginx

    certbot --nginx -d $ZBX_DOMAIN --non-interactive --agree-tos -m admin@$ZBX_DOMAIN

    systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
    systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm

    echo ""
    echo "====================================="
    echo " INSTALAÇÃO COM SSL FINALIZADA!"
    echo " Acesse: https://$ZBX_DOMAIN"
    echo "====================================="
}



### ==============================
