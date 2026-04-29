#!/bin/bash

# Definir cores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para imprimir com cores
print_green() { echo -e "${GREEN}$1${NC}"; }
print_yellow() { echo -e "${YELLOW}$1${NC}"; }
print_red() { echo -e "${RED}$1${NC}"; }
print_blue() { echo -e "${BLUE}$1${NC}"; }

# Função para verificar se comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        print_green "✓ $1"
    else
        print_red "✗ Erro: $2"
        exit 1
    fi
}

# Cabeçalho
print_green "======================================"
print_green "Temperature Processing API - Dev Setup"
print_green "======================================"
echo

# Verificar se Docker está rodando
print_yellow "Verificando se Docker está rodando..."
if ! docker version >/dev/null 2>&1; then
    print_red "Erro: Docker não está rodando ou não está instalado."
    print_red "Por favor, inicie o Docker e tente novamente."
    exit 1
fi
check_success "Docker está rodando" "Docker não está disponível"
echo

# Verificar se docker-compose existe
print_yellow "Verificando arquivo docker-compose.yml..."
if [ ! -f "docker-compose.yml" ]; then
    print_red "Erro: Arquivo docker-compose.yml não encontrado."
    print_red "Certifique-se de estar no diretório correto."
    exit 1
fi
check_success "docker-compose.yml encontrado" "Arquivo docker-compose.yml não encontrado"
echo

# Parar containers existentes
print_yellow "Parando containers existentes..."
docker-compose down >/dev/null 2>&1
print_green "✓ Containers anteriores parados"
echo

# Verificar se precisa rebuild
print_yellow "Verificando se precisa fazer rebuild..."
if ! docker images | grep -q "s7thiago/temperature-processing-api"; then
    print_yellow "Imagem não existe, fazendo build inicial..."
    docker-compose build
else
    read -p "Imagem já existe. Fazer rebuild completo? (recomendado apenas se mudou Dockerfile) [y/N]: " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_yellow "Fazendo rebuild completo..."
        docker-compose build --no-cache
    else
        print_yellow "Fazendo build incremental (mais rápido)..."
        docker-compose build
    fi
fi
if [ $? -ne 0 ]; then
    print_red "Erro no build da imagem. Verifique o Dockerfile."
    exit 1
fi
check_success "Build concluído com sucesso" "Falha no build da imagem"
echo

# Subir o ambiente
print_yellow "Subindo o ambiente de desenvolvimento..."
if ! docker-compose up -d; then
    print_red "Erro ao subir os containers."
    docker-compose logs backend
    exit 1
fi
check_success "Containers iniciados" "Falha ao iniciar containers"
echo

# Aguardar container ficar pronto
print_yellow "Aguardando container ficar pronto..."
sleep 10

# Verificar se container está rodando
if ! docker ps | grep -q "temperature-processing-api"; then
    print_red "Erro: Container não está rodando."
    print_red "Logs do container:"
    docker-compose logs backend
    exit 1
fi
check_success "Container está rodando" "Container não iniciou corretamente"
echo

# Executar warm-cache
print_yellow "Executando warm-cache para otimizar Gradle..."
if docker exec temperature-processing-api /usr/local/bin/warm-cache.sh; then
    check_success "Cache aquecido com sucesso" "Falha no warm-cache"
else
    print_yellow "⚠ Aviso: Warm-cache falhou, mas o ambiente está pronto."
    print_yellow "⚠ Você pode executar manualmente:"
    print_blue "  docker exec temperature-processing-api /usr/local/bin/warm-cache.sh"
fi
echo

# Status final
print_green "======================================"
print_green "AMBIENTE PRONTO PARA DESENVOLVIMENTO!"
print_green "======================================"
echo
print_yellow "Container: temperature-processing-api"
print_yellow "Portas expostas:"
echo "  - 8080 (Aplicação principal)"
echo "  - 8081 (Management/Actuator)"  
echo "  - 8082 (Adicional)"
echo
print_yellow "Comandos úteis:"
echo "  docker-compose logs backend                    # Ver logs"
echo "  docker exec -it temperature-processing-api zsh # Entrar no container"
echo "  docker-compose down                            # Parar ambiente"
echo
print_blue "Agora abra o VS Code com Remote-Containers na pasta do projeto!"
echo

# Perguntar se quer ver os logs
read -p "Deseja visualizar os logs do container? [y/N]: " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo
    print_yellow "Logs do container (Ctrl+C para sair):"
    docker-compose logs -f backend
fi