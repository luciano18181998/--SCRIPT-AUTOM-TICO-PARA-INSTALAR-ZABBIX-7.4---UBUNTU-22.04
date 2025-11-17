# 🚀 Instalador Automático – Zabbix 7.4 para Ubuntu 22.04

![Shell Script](https://img.shields.io/badge/Shell%20Script-Automation-green?style=for-the-badge)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-orange?style=for-the-badge)
![Zabbix Version](https://img.shields.io/badge/Zabbix-7.4-red?style=for-the-badge)
![Cloudflare Tunnel](https://img.shields.io/badge/Cloudflare-Tunnel-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Project-Active-brightgreen?style=for-the-badge)

---

# 📌 Sobre o Projeto

Este repositório contém uma coleção completa de **Scripts Automáticos** para instalar e configurar o **Zabbix 7.4** no **Ubuntu 22.04**, de forma totalmente profissional e simplificada.

Ele suporta todos os tipos de ambiente:

### ✔ Instalação por **IP da VPS**  
### ✔ Instalação por **Domínio com SSL Certbot**  
### ✔ Instalação por **Domínio (Modo Especial para Clouds)**  
### ✔ Instalação por **Cloudflare Tunnel**  
### ✔ Instalação por **Cloudflare Tunnel Modo Cloud (Oracle/OVH/Contabo)**  
### ✔ Instalação Especial **IP – Oracle / OVH / Contabo**  
### ✔ **Menu Interativo com 7 opções de instalação**

Todos os scripts realizam:

- Instalação completa do Zabbix  
- Configuração do MySQL/MariaDB  
- Correção automática do **ERROR 1419 (HY000)**  
- Configuração do PHP 8.1 + FPM  
- Configuração do NGINX (porta certa para cada modo)  
- Importação automática do banco  
- Ativação e início de serviços  
- Suporte para SSL automático (Certbot)  
- Suporte completo para Cloudflare Tunnel  

---

# 🟩 Instalar o Menu Principal (1 Comando)

Execute no terminal da sua VPS:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-menu.sh)
```

🟦 Instalação Modo Forçado (caso sua VPS não suporte )
# 🟢forçar a instalação Instale Com Apenas 1 Comando
```bash
curl -fsSL https://raw.githubusercontent.com/luciano18181998/--SCRIPT-AUTOM-TICO-PARA-INSTALAR-ZABBIX-7.4---UBUNTU-22.04/main/install-zabbix-menu.sh -o install.sh
chmod +x install.sh
./install.sh
```