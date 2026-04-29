@echo off
setlocal enabledelayedexpansion

:: Definir cores para output
set "GREEN=[32m"
set "YELLOW=[33m"
set "RED=[31m"
set "RESET=[0m"

echo %GREEN%======================================%RESET%
echo %GREEN%Temperature Processing API - Dev Setup%RESET%
echo %GREEN%======================================%RESET%
echo.

:: Verificar se Docker está rodando
echo %YELLOW%Verificando se Docker está rodando...%RESET%
docker version >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%Erro: Docker não está rodando ou não está instalado.%RESET%
    echo %RED%Por favor, inicie o Docker Desktop e tente novamente.%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Docker está rodando%RESET%
echo.

:: Verificar se docker-compose existe
echo %YELLOW%Verificando arquivo docker-compose.yml...%RESET%
if not exist "docker-compose.yml" (
    echo %RED%Erro: Arquivo docker-compose.yml não encontrado.%RESET%
    echo %RED%Certifique-se de estar no diretório correto.%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ docker-compose.yml encontrado%RESET%
echo.

:: Parar containers existentes
echo %YELLOW%Parando containers existentes...%RESET%
docker-compose down
echo.

:: Verificar se precisa rebuild
echo %YELLOW%Verificando se precisa fazer rebuild...%RESET%
docker images | findstr "s7thiago/temperature-processing-api" >nul
if %ERRORLEVEL% neq 0 (
    echo %YELLOW%Imagem não existe, fazendo build inicial...%RESET%
    docker-compose build
) else (
    choice /C YN /M "Imagem já existe. Fazer rebuild completo (recomendado apenas se mudou Dockerfile)"
    if !ERRORLEVEL! == 1 (
        echo %YELLOW%Fazendo rebuild completo...%RESET%
        docker-compose build --no-cache
    ) else (
        echo %YELLOW%Fazendo build incremental (mais rápido)...%RESET%
        docker-compose build
    )
)
if %ERRORLEVEL% neq 0 (
    echo %RED%Erro no build da imagem. Verifique o Dockerfile.%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Build concluído com sucesso%RESET%
echo.

:: Subir o ambiente
echo %YELLOW%Subindo o ambiente de desenvolvimento...%RESET%
docker-compose up -d
if %ERRORLEVEL% neq 0 (
    echo %RED%Erro ao subir os containers.%RESET%
    pause
    exit /b 1
)
echo %GREEN%✓ Containers iniciados%RESET%
echo.

:: Aguardar container ficar pronto
echo %YELLOW%Aguardando container ficar pronto...%RESET%
timeout /t 10 /nobreak >nul

:: Verificar se container está rodando
docker ps | findstr "temperature-processing-api" >nul
if %ERRORLEVEL% neq 0 (
    echo %RED%Erro: Container não está rodando.%RESET%
    docker-compose logs backend
    pause
    exit /b 1
)
echo %GREEN%✓ Container está rodando%RESET%
echo.

:: Executar warm-cache
echo %YELLOW%Executando warm-cache para otimizar Gradle...%RESET%
docker exec temperature-processing-api /usr/local/bin/warm-cache.sh
if %ERRORLEVEL% neq 0 (
    echo %YELLOW%Aviso: Warm-cache falhou, mas o ambiente está pronto.%RESET%
    echo %YELLOW%Você pode executar manualmente: docker exec temperature-processing-api /usr/local/bin/warm-cache.sh%RESET%
) else (
    echo %GREEN%✓ Cache aquecido com sucesso%RESET%
)
echo.

:: Status final
echo %GREEN%======================================%RESET%
echo %GREEN%AMBIENTE PRONTO PARA DESENVOLVIMENTO!%RESET%
echo %GREEN%======================================%RESET%
echo.
echo %YELLOW%Container: temperature-processing-api%RESET%
echo %YELLOW%Portas expostas:%RESET%
echo   - 8080 (Aplicação principal)
echo   - 8081 (Management/Actuator)  
echo   - 8082 (Adicional)
echo.
echo %YELLOW%Comandos úteis:%RESET%
echo   docker-compose logs backend          - Ver logs
echo   docker exec -it temperature-processing-api zsh  - Entrar no container
echo   docker-compose down                  - Parar ambiente
echo.
echo %YELLOW%Agora abra o VS Code com Remote-Containers na pasta do projeto!%RESET%
echo.

:: Perguntar se quer ver os logs
choice /C YN /M "Deseja visualizar os logs do container"
if %ERRORLEVEL% == 1 (
    echo.
    echo %YELLOW%Logs do container (Ctrl+C para sair):%RESET%
    docker-compose logs -f backend
)

pause