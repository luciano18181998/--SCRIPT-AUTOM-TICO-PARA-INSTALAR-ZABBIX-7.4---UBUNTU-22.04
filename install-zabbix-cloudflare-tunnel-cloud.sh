#!/bin/bash
set -e

### ============================================
###  Instalador Zabbix 7.4 – Cloudflare Tunnel
###  Compatível com Oracle / OVH / Contabo
###  SEM uso de portas 80/443
### ============================================

echo "=============================================="
echo "      INSTALADOR ZABBIX 7.4 – TÚNEL CLOUDFLARE"
echo "=============================================="
echo ""

### 1) Ler o domínio Cloudflare (CNAME do túnel)
read -p "Digite o subdomínio que irá acessar o Zabbix (ex: monitor.seudominio.com.br): " DOMAIN

if [ -z "$DOMAIN" ]; then
    echo "❌ ERRO: Você deve informar um domínio válido."
    exit 1
fi

### Senhas automáticas
ZBX_DB_PASS="zabbix123"
MYSQL_ROOT_PASS="root123"

echo ""
echo "➡ Senha MySQL root: $MYSQL_ROOT_PASS"
echo "➡ Senha banco Zabbix : $ZBX_DB_PASS"
echo ""

sleep 2

### 2) Atualizar sistema
echo "➡ Atualizando sistema..."
apt update -y
apt upgrade -y

### 3) Instalar dependências
echo "➡ Instalando dependências..."
apt install -y wget curl nano unzip php8.1 php8.1-fpm \
php8.1-mbstring php8.1-xml php8.1-bcmath php8.1-ldap php8.1-gd \
mysql-server

### 4) Instalar Cloudflared
echo "➡ Instalando Cloudflared (túnel)..."
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
dpkg -i cloudflared-linux-amd64.deb

### 5) Criar túnel automaticamente
echo "➡ Criando túnel Cloudflare..."

cloudflared tunnel login

TUNNEL_NAME="zabbix-tunnel"
cloudflared tunnel create $TUNNEL_NAME

TUNNEL_ID=$(cloudflared tunnel list | grep $TUNNEL_NAME | awk '{print $1}')

echo "➡ Tunnel ID: $TUNNEL_ID"

### 6) Instalar repositório Zabbix
echo "➡ Instalando repositório Zabbix..."
wget https://repo.zabbix.com/zabbix/7.4/release/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest_7.4+ubuntu22.04_all.deb
dpkg -i zabbix-release_latest_7.4+ubuntu22.04_all.deb
apt update

### 7) Instalar Zabbix
echo "➡ Instalando Zabbix 7.4..."
apt install -y zabbix-server-mysql zabbix-nginx-conf zabbix-sql-scripts zabbix-agent

### 8) Corrigir MySQL para evitar erro 1419
echo "➡ Ajustando MySQL (modo compatibilidade Cloud)..."

mysql -uroot <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$MYSQL_ROOT_PASS';
FLUSH PRIVILEGES;
SET GLOBAL log_bin_trust_function_creators = 1;
EOF

### 9) Criar banco e usuário
mysql -uroot -p"$MYSQL_ROOT_PASS" <<EOF
CREATE DATABASE zabbix CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;
CREATE USER 'zabbix'@'localhost' IDENTIFIED BY '$ZBX_DB_PASS';
GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost';
FLUSH PRIVILEGES;
EOF

### 10) Importar schema
echo "➡ Importando estrutura do banco..."
zcat /usr/share/zabbix/sql-scripts/mysql/server.sql.gz | mysql -uroot -p"$MYSQL_ROOT_PASS" zabbix

mysql -uroot -p"$MYSQL_ROOT_PASS" -e "SET GLOBAL log_bin_trust_function_creators = 0;"

### 11) Configurar Zabbix Server
echo "➡ Configurando serviço Zabbix..."
cat <<EOF > /etc/zabbix/zabbix_server.conf
LogFile=/var/log/zabbix/zabbix_server.log
DBHost=localhost
DBName=zabbix
DBUser=zabbix
DBPassword=$ZBX_DB_PASS
EOF

### 12) Configuração especial NGINX para Cloudflare Tunnel
echo "➡ Configurando NGINX para Cloudflare Tunnel..."

cat <<EOF > /etc/zabbix/nginx.conf
server {
    listen 8080;
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

### 13) Criar roteamento Cloudflare Tunnel
echo "➡ Criando roteamento do túnel..."

mkdir -p /etc/cloudflared

cat <<EOF > /etc/cloudflared/config.yml
tunnel: $TUNNEL_ID
credentials-file: /root/.cloudflared/$TUNNEL_ID.json

ingress:
  - hostname: $DOMAIN
    service: http://localhost:8080
  - service: http_status:404
EOF

cloudflared tunnel route dns $TUNNEL_NAME $DOMAIN

### 14) Iniciar túnel
systemctl enable cloudflared
systemctl restart cloudflared

### 15) Reiniciar serviços Zabbix
systemctl restart mysql zabbix-server zabbix-agent php8.1-fpm nginx

echo ""
echo "=============================================="
echo "   INSTALAÇÃO COMPLETA – TÚNEL CLOUDFLARE OK"
echo "=============================================="
echo " ➤ Acesse seu Zabbix:"
echo "     https://$DOMAIN"
echo ""
echo " ➤ Login: Admin"
echo " ➤ Senha: zabbix"
echo "=============================================="
