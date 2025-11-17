#!/bin/bash
set -e

### ================================
### CONFIGURAÇÕES EDITÁVEIS
### ================================
ZBX_DB_PASS="SENHADOBANCO"           # senha do banco
ZBX_DOMAIN="seu-dominio.com.br"      # domínio do Zabbix
PHP_FPM_SOCKET="/run/php/php8.1-fpm.sock"
### ================================


echo "======================================"
echo "  INSTALAÇÃO ZABBIX 7.4 + SSL CERTBOT"
echo "======================================"
sleep 2


### 1) Atualizar sistema
apt update -y
apt upgrade -y


### 2) Instalar repositório Zabbix
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
apt update -y


### 3) Instalar pacotes principais
apt install -y \
    zabbix-server-mysql \
    zabbix-frontend-php \
    zabbix-nginx-conf \
    zabbix-sql-scripts \
    zabbix-agent \
    mysql-server \
    python3-certbot-nginx


### 4) Iniciar MySQL
systemctl enable mysql
systemctl restart mysql


### 5) Criar banco e usuário Zabbix
mysql -uroot <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
SET GLOBAL log_bin_trust_function_creators = 1;
FLUSH PRIVILEGES;
EOF


### 6) Importar schema
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | \
mysql --default-character-set=utf8mb4 -uzabbix -p"$ZBX_DB_PASS" zabbix

mysql -uroot <<EOF
SET GLOBAL log_bin_trust_function_creators = 0;
EOF


### 7) Configurar zabbix_server.conf
cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$ZBX_DB_PASS
CacheSize=512M
StartPollers=10
EOF


### 8) Configurar NGINX para o domínio
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
        fastcgi_pass unix:$PHP_FPM_SOCKET;
        fastcgi_index index.php;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF


### 9) Testar configuração
nginx -t


### 10) Reiniciar NGINX
systemctl restart nginx


### 11) Gerar SSL – Certbot automação
certbot --nginx -d $ZBX_DOMAIN --non-interactive --agree-tos -m admin@$ZBX_DOMAIN


### 12) Gerar locale pt-BR
locale-gen pt_BR.UTF-8
update-locale


### 13) Reiniciar serviços Zabbix e PHP
systemctl restart zabbix-server zabbix-agent nginx php8.1-fpm
systemctl enable zabbix-server zabbix-agent nginx php8.1-fpm


echo ""
echo "=============================================="
echo " INSTALAÇÃO FINALIZADA COM SUCESSO!"
echo " Acesse: https://$ZBX_DOMAIN"
echo ""
echo " Login padrão:"
echo " → Usuário: Admin"
echo " → Senha: zabbix"
echo "=============================================="
