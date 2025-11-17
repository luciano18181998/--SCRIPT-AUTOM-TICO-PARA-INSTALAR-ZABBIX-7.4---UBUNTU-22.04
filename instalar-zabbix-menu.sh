clear
echo -e "\e[1;32m=============================================="
echo -e "        INSTALADOR ZABBIX 7.4 – MENU"
echo -e "==============================================\e[0m"

echo -e "\e[1;33m1 - Instalar Zabbix usando IP da VPS"
echo "2 - Instalar Zabbix com SSL (Certbot)"
echo "3 - Instalar Zabbix com Túnel Cloudflare"
echo "4 - Reiniciar serviços do Zabbix"
echo -e "0 - Sair\e[0m"

echo -e "\e[1;32m==============================================\e[0m"
read -p "Digite a opção desejada: " opcao

case $opcao in
  1)
    bash install-zabbix-ip.sh
    ;;
  2)
    bash install-zabbix-ssl-certbot.sh
    ;;
  3)
    bash install-zabbix-cloudflare-tunnel.sh
    ;;
  4)
    echo -e "\n🔄 Reiniciando serviços..."
    systemctl restart zabbix-server zabbix-agent php8.1-fpm nginx
    systemctl enable zabbix-server zabbix-agent
    echo -e "✔ Serviços reiniciados!\n"
    read -p "Pressione Enter para voltar ao menu..."
    ;;
  0)
    echo -e "\n👋 Saindo..."
    exit 0
    ;;
  *)
    echo -e "\n❌ Opção inválida!"
    sleep 2
    ;;
esac
