#!/bin/bash

clear
echo -e "\e[1;32m=============================================="
echo -e "           INSTALADOR ZABBIX 7.4 – MENU"
echo -e "==============================================\e[0m"

echo -e "\e[1;33m1 - Instalar Zabbix via IP (Padrão)"
echo "2 - Instalar Zabbix com Domínio + SSL Certbot"
echo "3 - Instalar Zabbix com Túnel Cloudflare"
echo "4 - Reiniciar serviços do Zabbix (Server/Agent/NGINX/PHP)"
echo ""
echo "5 - Instalar Zabbix via IP – Modo Cloud (Oracle / OVH / Contabo)"
echo "6 - Instalar Zabbix com Domínio – Modo Cloud (Oracle / OVH / Contabo)"
echo "7 - Instalar Zabbix com Túnel Cloudflare – Modo Cloud (Oracle / OVH / Contabo)"
echo -e "0 - Sair\e[0m"

echo -e "\e[1;32m==============================================\e[0m"
read -p "Digite a opção desejada: " opcao

case $opcao in

  1)
    echo -e "\n🔧 Instalando via IP..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-ip.sh)
    ;;

  2)
    echo -e "\n🔐 Instalando Domínio + SSL Certbot..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-ssl-certbot.sh)
    ;;

  3)
    echo -e "\n🌐 Instalando via Túnel Cloudflare..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-cloudflare-tunnel.sh)
    ;;

  4)
    echo -e "\n🔄 Reiniciando serviços..."
    systemctl restart zabbix-server zabbix-agent php8.1-fpm nginx
    systemctl enable zabbix-server zabbix-agent
    echo -e "✔ Serviços reiniciados!"
    read -p "Pressione ENTER para voltar ao menu..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-menu.sh)
    ;;

  5)
    echo -e "\n🟫 Instalando via IP – Modo Cloud (Oracle / OVH / Contabo)..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-ip-oracle-ovh-contabo.sh)
    ;;

  6)
    echo -e "\n🟪 Instalando Domínio – Modo Cloud (Oracle / OVH / Contabo)..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-domain-cloud.sh)
    ;;

  7)
    echo -e "\n🟧 Instalando Túnel Cloudflare – Modo Cloud (Oracle / OVH / Contabo)..."
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-cloudflare-tunnel-cloud.sh)
    ;;

  0)
    echo -e "\n👋 Saindo..."
    exit 0
    ;;

  *)
    echo -e "\n❌ Opção inválida!"
    sleep 2
    bash <(curl -fsSL \
https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-menu.sh)
    ;;
esac
