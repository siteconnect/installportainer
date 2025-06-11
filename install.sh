#!/bin/bash

# Cores
GREEN='\e[32m'
YELLOW='\e[33m'
RED='\e[31m'
BLUE='\e[34m'
NC='\e[0m'

# Função para mostrar spinner de carregamento
spinner() {
    local pid=$1
    local delay=0.1
    local spinstr='|/-\'
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr"
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b"
    done
    printf "    \b\b\b\b"
}

# Função para verificar requisitos do sistema
check_system_requirements() {
    echo -e "${BLUE}Verificando requisitos do sistema...${NC}"
    
    # Verificar espaço em disco (em GB, removendo a unidade 'G')
    local free_space=$(df -BG / | awk 'NR==2 {print $4}' | tr -d 'G')
    if [ "$free_space" -lt 10 ]; then
        echo -e "${RED}❌ Erro: Espaço em disco insuficiente. Mínimo requerido: 10GB${NC}"
        return 1
    fi
    
    # Verificar memória RAM
    local total_mem=$(free -g | awk 'NR==2 {print $2}')
    if [ $total_mem -lt 2 ]; then
        echo -e "${RED}❌ Erro: Memória RAM insuficiente. Mínimo requerido: 2GB${NC}"
        return 1
    fi
    
    echo -e "${GREEN}✅ Requisitos do sistema atendidos${NC}"
    return 0
}

# Função para imprimir um banner que permanece na tela
function print_banner {
  clear
  echo -e "${GREEN}"
  echo "============================================="
  echo "           PORTALDOZAP.COM.BR                "
  echo "============================================="
  echo -e "${NC}"
}
# Logo animado simples

show_animated_logo() {
 echo -e "${YELLOW}"          "SISTEMA PARA MÚLTIPLOS ATENDIMENTOS " 
 echo " ███╗   ███╗ ██╗   ██╗  ██╗     ████████╗  ██╗   ██████████╗   █████╗    ██████╗  " 
 echo " ████╗ ████║ ██║   ██║  ██║     ╚══██╔══╝  ██║    ╚═══ ██╔╝   ██╔══██╗   ██╔══ ██╗ "
 echo " ██╔████╔██║ ██║   ██║  ██║        ██║     ██║      ██║       ████████   ███████╔╝   "
 echo " ██║╚██╔╝██║ ██║   ██║  ██║        ██║     ██║    ██║         ██╔══ ██║  ██ ╔═══╝   " 
 echo " ██║ ╚═╝ ██║ ╚██████╔╝  ███████╗   ██║     ██║   █████████    ██║   ██║  ██║       "
 echo " ╚═╝     ╚═╝ ╚═════╝    ╚══════╝   ╚═╝     ╚═╝  ╚   ═   ╝     ╚═╝   ╚═╝  ╚═╝     "  
 echo -e "${NC}"
}

# Função para mostrar um banner colorido
function show_banner() {
    echo -e "${GREEN}=============================================================================="
    echo -e "=                                                                            ="
    echo -e "=                 ${YELLOW}Preencha as informações solicitadas abaixo${GREEN}                 ="
    echo -e "=                                                                            ="
    echo -e "==============================================================================${NC}"
}

# Função para mostrar uma mensagem de etapa com barra de progresso
function show_step() {
    local current=$1
    local total=5
    local percent=$((current * 100 / total))
    local completed=$((percent / 2))
    
    echo -ne "${GREEN}Passo ${YELLOW}$current/$total ${GREEN}["
    for ((i=0; i<50; i++)); do
        if [ $i -lt $completed ]; then
            echo -ne "="
        else
            echo -ne " "
        fi
    done
    echo -e "] ${percent}%${NC}"
}

# Mostrar banner inicial
clear
show_animated_logo
show_banner
echo ""

# Solicitar informações do usuário
show_step 1
read -p "📧 Endereço de e-mail: " email
echo ""
show_step 2
read -p "🌐 Dominio do Traefik (ex: traefik.seudominio.com): " traefik
echo ""
show_step 3
read -s -p "🔑 Senha do Traefik: " senha
echo ""
echo ""
show_step 4
read -p "🌐 Dominio do Portainer (ex: portainer.seudominio.com): " portainer
echo ""
show_step 5
read -p "🌐 Dominio do Edge (ex: edge.seudominio.com): " edge
echo ""

# Verificação de dados
clear
echo -e "${BLUE}📋 Resumo das Informações${NC}"
echo -e "${GREEN}================================${NC}"
echo -e "📧 Seu E-mail: ${YELLOW}$email${NC}"
echo -e "🌐 Dominio do Traefik: ${YELLOW}$traefik${NC}"
echo -e "🔑 Senha do Traefik: ${YELLOW}********${NC}"
echo -e "🌐 Dominio do Portainer: ${YELLOW}$portainer${NC}"
echo -e "🌐 Dominio do Edge: ${YELLOW}$edge${NC}"
echo -e "${GREEN}================================${NC}"
echo ""

read -p "As informações estão certas? (y/n): " confirma1
if [ "$confirma1" == "y" ]; then
    clear
    
    # Verificar requisitos do sistema
    check_system_requirements || exit 1
    
    echo -e "${BLUE}🚀 Iniciando instalação...${NC}"
    
    #########################################################
    # INSTALANDO DEPENDENCIAS
    #########################################################
    echo -e "${YELLOW}📦 Atualizando sistema e instalando dependências...${NC}"
    (sudo apt update -y && sudo apt upgrade -y) > /dev/null 2>&1 &
    spinner $!
    
    echo -e "${YELLOW}🐳 Instalando Docker...${NC}"
    (sudo apt install -y curl && \
    curl -fsSL https://get.docker.com -o get-docker.sh && \
    sudo sh get-docker.sh) > /dev/null 2>&1 &
    spinner $!
    
    mkdir -p ~/Portainer && cd ~/Portainer
    echo -e "${GREEN}✅ Dependências instaladas com sucesso${NC}"
    sleep 2
    clear

    #########################################################
    # CRIANDO DOCKER-COMPOSE.YML
    #########################################################
    cat > docker-compose.yml <<EOL
services:
  traefik:
    container_name: traefik
    image: "traefik:latest"
    restart: always
    command:
      - --entrypoints.web.address=:80
      - --entrypoints.websecure.address=:443
      - --api.insecure=true
      - --api.dashboard=true
      - --providers.docker
      - --log.level=ERROR
      - --certificatesresolvers.leresolver.acme.httpchallenge=true
      - --certificatesresolvers.leresolver.acme.email=$email
      - --certificatesresolvers.leresolver.acme.storage=./acme.json
      - --certificatesresolvers.leresolver.acme.httpchallenge.entrypoint=web
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "/var/run/docker.sock:/var/run/docker.sock:ro"
      - "./acme.json:/acme.json"
    labels:
      - "traefik.http.routers.http-catchall.rule=hostregexp(\`{host:.+}\`)"
      - "traefik.http.routers.http-catchall.entrypoints=web"
      - "traefik.http.routers.http-catchall.middlewares=redirect-to-https"
      - "traefik.http.middlewares.redirect-to-https.redirectscheme.scheme=https"
      - "traefik.http.routers.traefik-dashboard.rule=Host(\`$traefik\`)"
      - "traefik.http.routers.traefik-dashboard.entrypoints=websecure"
      - "traefik.http.routers.traefik-dashboard.service=api@internal"
      - "traefik.http.routers.traefik-dashboard.tls.certresolver=leresolver"
      - "traefik.http.middlewares.traefik-auth.basicauth.users=$senha"
      - "traefik.http.routers.traefik-dashboard.middlewares=traefik-auth"
  portainer:
    image: portainer/portainer-ce:latest
    command: -H unix:///var/run/docker.sock
    restart: always
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data
    labels:
      - "traefik.enable=true"
      - "traefik.http.routers.frontend.rule=Host(\`$portainer\`)"
      - "traefik.http.routers.frontend.entrypoints=websecure"
      - "traefik.http.services.frontend.loadbalancer.server.port=9000"
      - "traefik.http.routers.frontend.service=frontend"
      - "traefik.http.routers.frontend.tls.certresolver=leresolver"
      - "traefik.http.routers.edge.rule=Host(\`$edge\`)"
      - "traefik.http.routers.edge.entrypoints=websecure"
      - "traefik.http.services.edge.loadbalancer.server.port=8000"
      - "traefik.http.routers.edge.service=edge"
      - "traefik.http.routers.edge.tls.certresolver=leresolver"
volumes:
  portainer_data:
EOL

    #########################################################
    # CERTIFICADOS LETSENCRYPT
    #########################################################
    echo -e "${YELLOW}📝 Gerando certificado LetsEncrypt...${NC}"
    touch acme.json
    sudo chmod 600 acme.json
    
    #########################################################
    # INICIANDO CONTAINER
    #########################################################
    echo -e "${YELLOW}🚀 Iniciando containers...${NC}"
    (sudo docker compose up -d) > /dev/null 2>&1 &
    spinner $!
    
    clear
    show_animated_logo
    
    echo -e "${GREEN}🎉 Instalação concluída com sucesso!${NC}"
    echo -e "${BLUE}📝 Informações de Acesso:${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "🔗 Portainer: ${YELLOW}https://$portainer${NC}"
    echo -e "🔗 Traefik: ${YELLOW}https://$traefik${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo -e "${BLUE}💡 Dica: Aguarde alguns minutos para que os certificados SSL sejam gerados${NC}"
    echo -e "${GREEN}🌟 Visite: https://portaldozap.com.br${NC}"
else
    echo -e "${RED}❌ Instalação cancelada. Por favor, inicie novamente.${NC}"
    exit 0
fi
