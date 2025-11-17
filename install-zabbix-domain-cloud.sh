#!/bin/bash
set -e

### ============================================
###  Instalador Zabbix 7.4 – Domínio + SSL Certbot
###  Compatível com Oracle / OVH / Contabo
### ============================================

echo "=============================================="
echo "      INSTALADOR ZABBIX 7.4 (DOMÍNIO + SSL)"
echo "=============================================="
echo ""

### 1) Ler domínio
read -p "Digite o domínio (ex: monitor.seudominio.com.br): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ ERRO: Você deve informar um domínio válido."
    exit 1
fi

### 2) Senhas
ZBX_DB_PASS="zabbix123"
MYSQL_ROOT_PASS="root123"

echo ""
echo "➡ Usando senha MySQL root: $MYSQL_ROOT_PASS"
echo "➡ Usando senha do banco Zabbix: $ZBX_DB_PASS"
echo ""

sleep 2

### 3) Atualizar sistema
echo "➡ Atualizando sistema..."
apt update -y
apt upgrade -y

### 4) Instalar dependências
echo "➡ Instalando dependências..."
apt install -y wget curl nano unzip \
    php8.1 php8.1-fpm php8.1-mbstring php8.1-xml php8.1-bcmath php8.1-ldap php8.1-gd \
    mysql-server python3-certbot-nginx

### 5) Instalar repositório do Zabbix
echo "➡ Instalando repositório do Zabbix..."
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
apt update

### 6) Instalar Zabbix
echo "➡ Instalando Zabbix 7.4..."
apt install -y zabbix-server-mysql zabbix-frontend-php zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

### 7) Ajustar MySQL para CLOUD (evita ERRO 1419)
echo "➡ Ajustando MySQL (modo compatibilidade Cloud)..."

mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';
FLUSH PRIVILEGES;
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

### 8) Criar banco Zabbix
mysql -uroot -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

### 9) Importar tabelas Zabbix (SEM ERRO)
echo "➡ Importando tabelas..."
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql -uroot -p"$MYSQL_ROOT_PASS" zabbix

### 10) Desabilitar trust creators depois (mais seguro)
mysql -uroot -p"$MYSQL_ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

### 11) Configurar Zabbix Server
echo "➡ Configurando Zabbix..."
cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$ZBX_DB_PASS
EOF

### 12) Configurar NGINX para o domínio (modo Zabbix via NGINX nativo)
echo "➡ Configurando NGINX..."

cat <<EOF > /etc/zabbix/nginx.conf
server {
    listen 80;
    server_name $DOMAIN;

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

### 13) Gerar SSL Let’s Encrypt automaticamente
echo "➡ Gerando SSL com Certbot..."
certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos -m admin@$DOMAIN

### 14) Reiniciar serviços
echo "➡ Reiniciando serviços..."
systemctl restart mysql
systemctl restart zabbix-server zabbix-agent php8.1-fpm nginx
systemctl enable zabbix-server zabbix-agent

echo ""
echo "=============================================="
echo "      INSTALAÇÃO COMPLETA COM SUCESSO!"
echo "=============================================="
echo " Acesse agora: https://$DOMAIN"
echo " Login: Admin"
echo " Senha: zabbix"
echo "=============================================="
