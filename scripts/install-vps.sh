#!/bin/bash

# ============================================
# Meeting AI Platform - VPS Installation Script
# Ubuntu 20.04 + Docker
# ============================================

set -e  # Exit on error

# ============================================
# Colors for output
# ============================================
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ============================================
# Configuration Variables
# ============================================
INSTALL_DIR="/opt/meeting-ai-platform"
PROJECT_DIR=""
INSTALL_TYPE="production"  # development or production
WITH_SSL=false
DOMAIN=""

# ============================================
# Helper Functions
# ============================================

print_banner() {
    echo -e "${BLUE}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║       Meeting AI Platform - VPS Installation             ║"
    echo "║       Ubuntu 20.04 + Docker                              ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_step() {
    echo ""
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${CYAN} $1 ${NC}"
    echo -e "${CYAN}═══════════════════════════════════════════════════════════${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

check_root() {
    if [ "$EUID" -ne 0 ]; then 
        print_error "Este script precisa ser executado como root (use sudo)"
        exit 1
    fi
}

# ============================================
# System Update
# ============================================
update_system() {
    print_step "Atualizando Sistema"
    
    print_info "Atualizando pacotes do sistema..."
    apt-get update -y
    apt-get upgrade -y
    
    # Instalar pacotes essenciais
    print_info "Instalando dependências essenciais..."
    apt-get install -y \
        curl \
        wget \
        git \
        vim \
        htop \
        ufw \
        fail2ban \
        unattended-upgrades \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release
    
    print_success "Sistema atualizado com sucesso!"
}

# ============================================
# Install Docker
# ============================================
install_docker() {
    print_step "Instalando Docker"
    
    if command -v docker &> /dev/null; then
        print_warning "Docker já está instalado"
        docker --version
    else
        print_info "Instalando Docker..."
        
        # Instalar Docker repository
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        apt-get update
        apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        print_success "Docker instalado com sucesso!"
    fi
    
    # Instalar Docker Compose standalone (backup)
    if ! command -v docker-compose &> /dev/null; then
        print_info "Instalando Docker Compose standalone..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
        
        print_success "Docker Compose instalado!"
    else
        print_info "Docker Compose já está instalado"
    fi
    
    docker --version
    docker compose version || docker-compose --version
    
    # Configurar Docker para iniciar no boot
    systemctl enable docker
    systemctl start docker
    
    print_success "Docker configurado para iniciar automaticamente!"
}

# ============================================
# Configure Firewall
# ============================================
configure_firewall() {
    print_step "Configurando Firewall (UFW)"
    
    # Habilitar UFW
    ufw --force reset
    
    # Portas básicas
    ufw allow 22/tcp comment 'SSH'
    ufw allow 80/tcp comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow 3478/tcp comment 'STUN/TURN'
    ufw allow 3478/udp comment 'STUN/TURN'
    ufw allow 5349/tcp comment 'STUN/TURN TLS'
    ufw allow 5349/udp comment 'STUN/TURN TLS'
    ufw allow 49152:49200/udp comment 'TURN RTP Range'
    
    # Habilitar firewall
    ufw --force enable
    
    print_success "Firewall configurado!"
    ufw status
}

# ============================================
# Configure Fail2Ban
# ============================================
configure_fail2ban() {
    print_step "Configurando Fail2Ban"
    
    # Configurar basic jail para SSH
    cat > /etc/fail2ban/jail.local <<EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5
destemail = root@localhost
sendername = Fail2Ban
action = %(action_)s

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
EOF
    
    systemctl restart fail2ban
    systemctl enable fail2ban
    
    print_success "Fail2Ban configurado!"
}

# ============================================
# Clone/Copy Project
# ============================================
setup_project() {
    print_step "Configurando Projeto"
    
    # Determinar diretório do projeto
    if [ -z "$PROJECT_DIR" ]; then
        if [ -f "/opt/meeting-ai-platform" ]; then
            PROJECT_DIR="/opt/meeting-ai-platform"
        elif [ -f "./docker-compose.yml" ]; then
            PROJECT_DIR="$(pwd)"
        else
            print_error "Diretório do projeto não encontrado!"
            read -p "Digite o caminho completo do projeto ou URL do repositório: " project_path
            
            if [[ $project_path == http* ]]; then
                print_info "Clonando repositório..."
                git clone $project_path $INSTALL_DIR
                PROJECT_DIR=$INSTALL_DIR
            else
                PROJECT_DIR=$project_path
            fi
        fi
    fi
    
    cd "$PROJECT_DIR"
    print_success "Projeto configurado em: $PROJECT_DIR"
}

# ============================================
# Create Environment File
# ============================================
create_env_file() {
    print_step "Criando Arquivo de Configuração (.env)"
    
    if [ -f .env ]; then
        print_warning "Arquivo .env já existe. Fazendo backup..."
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    # Gerar secrets seguros
    JWT_SECRET=$(openssl rand -hex 32)
    POSTGRES_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-25)
    REDIS_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-25)
    TURN_PASSWORD=$(openssl rand -base64 24 | tr -d "=+/" | cut -c1-25)
    
    # Criar arquivo .env
    cat > .env <<EOF
# ============================================
# Meeting AI Platform - Environment Variables
# ============================================

# ============================================
# Environment
# ============================================
ENVIRONMENT=$INSTALL_TYPE
DEBUG=False

# ============================================
# Application
# ============================================
APP_NAME=Meeting AI Platform
JWT_SECRET=$JWT_SECRET
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=30

# ============================================
# Database
# ============================================
POSTGRES_USER=meeting_user
POSTGRES_PASSWORD=$POSTGRES_PASSWORD
POSTGRES_DB=meeting_db
DATABASE_URL=postgresql://meeting_user:$POSTGRES_PASSWORD@postgres:5432/meeting_db

# ============================================
# Redis
# ============================================
REDIS_URL=redis://redis:6379/0

# ============================================
# OpenAI API
# ============================================
OPENAI_API_KEY=sk-your-openai-api-key-here
WHISPER_MODEL=base

# ============================================
# Anthropic API
# ============================================
ANTHROPIC_API_KEY=sk-ant-your-anthropic-api-key-here
CLAUDE_MODEL=claude-3-opus-20240229

# ============================================
# CORS
# ============================================
CORS_ORIGINS=["http://localhost:3000"]

# ============================================
# WebRTC / TURN Server
# ============================================
TURN_SERVER_URL=turn:$DOMAIN:3478
TURN_SERVER_USERNAME=meeting
TURN_SERVER_PASSWORD=$TURN_PASSWORD

# ============================================
# Transcrição
# ============================================
TRANSCRIPTION_LANGUAGE=pt
ENABLE_SPEAKER_DIARIZATION=True

# ============================================
# AI Analysis
# ============================================
AI_ANALYSIS_ENABLED=True
AI_ANALYSIS_INTERVAL=300
AI_ANALYSIS_MIN_WORDS=100

# ============================================
# File Uploads
# ============================================
MAX_UPLOAD_SIZE=100MB

# ============================================
# Logging
# ============================================
LOG_LEVEL=INFO
EOF
    
    print_success "Arquivo .env criado!"
    print_warning "⚠️  IMPORTANTE: Configure as seguintes variáveis no arquivo .env:"
    print_warning "   - OPENAI_API_KEY"
    print_warning "   - ANTHROPIC_API_KEY"
    if [ "$WITH_SSL" = true ]; then
        print_warning "   - CORS_ORIGINS (adicione seu domínio)"
    fi
    echo ""
    read -p "Pressione ENTER para continuar ou Ctrl+C para editar o .env agora..."
}

# ============================================
# Create Directories
# ============================================
create_directories() {
    print_step "Criando Diretórios Necessários"
    
    # Criar diretórios do backend
    mkdir -p backend/recordings
    mkdir -p backend/transcriptions
    mkdir -p backend/logs
    
    # Criar diretórios do frontend
    mkdir -p frontend/public
    mkdir -p frontend/src
    
    # Criar diretórios do nginx
    mkdir -p nginx/ssl
    
    # Criar diretórios de backup
    mkdir -p backups
    
    print_success "Diretórios criados!"
}

# ============================================
# Build Docker Images
# ============================================
build_images() {
    print_step "Construindo Imagens Docker"
    
    print_info "Isso pode levar alguns minutos..."
    
    if [ "$INSTALL_TYPE" = "production" ]; then
        docker compose build --no-cache
    else
        docker compose build
    fi
    
    print_success "Imagens Docker construídas!"
}

# ============================================
# Start Services
# ============================================
start_services() {
    print_step "Iniciando Serviços"
    
    if [ "$INSTALL_TYPE" = "production" ]; then
        docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
    else
        docker compose up -d
    fi
    
    print_info "Aguardando serviços iniciarem..."
    sleep 15
    
    print_success "Serviços iniciados!"
}

# ============================================
# Run Database Migrations
# ============================================
run_migrations() {
    print_step "Executando Migrations do Banco de Dados"
    
    print_info "Aguardando PostgreSQL estar pronto..."
    sleep 10
    
    # Executar migrations
    docker compose exec -T backend alembic upgrade head || print_warning "Migrations podem já estar aplicadas"
    
    print_success "Migrations executadas!"
}

# ============================================
# Setup Backup Script
# ============================================
setup_backup() {
    print_step "Configurando Backup Automático"
    
    cat > /usr/local/bin/meeting-backup.sh <<'EOFSCRIPT'
#!/bin/bash
# Meeting AI Platform - Backup Script

BACKUP_DIR="/opt/meeting-ai-platform/backups"
DATE=$(date +%Y%m%d_%H%M%S)

cd /opt/meeting-ai-platform

# Criar diretório de backup se não existir
mkdir -p $BACKUP_DIR

# Backup do banco de dados
docker compose exec -T postgres pg_dump -U meeting_user meeting_db > "$BACKUP_DIR/db_backup_$DATE.sql"

# Backup dos arquivos
tar -czf "$BACKUP_DIR/files_backup_$DATE.tar.gz" \
    backend/recordings \
    backend/transcriptions \
    backend/logs \
    nginx/ssl 2>/dev/null

# Remover backups antigos (manter últimos 7 dias)
find $BACKUP_DIR -type f -mtime +7 -delete

echo "Backup concluído: $DATE"
EOFSCRIPT
    
    chmod +x /usr/local/bin/meeting-backup.sh
    
    # Configurar cron job para backup diário às 2:00 AM
    (crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/meeting-backup.sh >> /var/log/meeting-backup.log 2>&1") | crontab -
    
    print_success "Backup automático configurado (diariamente às 2:00 AM)!"
}

# ============================================
# Setup SSL (Let's Encrypt)
# ============================================
setup_ssl() {
    if [ "$WITH_SSL" = false ]; then
        return
    fi
    
    if [ -z "$DOMAIN" ]; then
        print_warning "Domínio não fornecido. Pulando configuração SSL."
        return
    fi
    
    print_step "Configurando SSL com Let's Encrypt"
    
    # Instalar Certbot
    apt-get install -y certbot
    
    # Parar nginx temporariamente
    docker compose stop nginx
    
    # Obter certificado
    certbot certonly --standalone -d "$DOMAIN" -n --agree-tos --email admin@"$DOMAIN"
    
    # Copiar certificados
    cp /etc/letsencrypt/live/"$DOMAIN"/fullchain.pem nginx/ssl/cert.pem
    cp /etc/letsencrypt/live/"$DOMAIN"/privkey.pem nginx/ssl/key.pem
    
    # Reiniciar nginx
    docker compose up -d nginx
    
    print_success "SSL configurado!"
    print_info "Configure auto-renewal: certbot renew --dry-run"
}

# ============================================
# Health Check
# ============================================
health_check() {
    print_step "Verificando Saúde dos Serviços"
    
    print_info "Aguardando serviços estabilizarem..."
    sleep 20
    
    # Verificar containers
    echo ""
    print_info "Status dos containers:"
    docker compose ps
    
    echo ""
    print_info "Verificando conectividade..."
    
    # Testar backend
    if curl -f http://localhost:8000/health &>/dev/null; then
        print_success "Backend está respondendo!"
    else
        print_error "Backend não está respondendo!"
    fi
    
    # Testar frontend
    if curl -f http://localhost:3000 &>/dev/null; then
        print_success "Frontend está respondendo!"
    else
        print_warning "Frontend ainda não está pronto (normal se estiver em build)"
    fi
    
    echo ""
}

# ============================================
# Print Summary
# ============================================
print_summary() {
    print_step "Instalação Concluída!"
    
    echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║           Instalação Finalizada com Sucesso!             ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    echo -e "${BLUE}Informações Importantes:${NC}"
    echo ""
    echo -e "${YELLOW}URLs de Acesso:${NC}"
    echo "  • Frontend:  http://$(hostname -I | awk '{print $1}'):3000"
    echo "  • Backend:   http://$(hostname -I | awk '{print $1}'):8000"
    echo "  • API Docs:  http://$(hostname -I | awk '{print $1}'):8000/docs"
    echo ""
    
    if [ "$WITH_SSL" = true ] && [ -n "$DOMAIN" ]; then
        echo -e "${YELLOW}URLs com SSL:${NC}"
        echo "  • Frontend:  https://$DOMAIN"
        echo "  • Backend:   https://$DOMAIN/api"
    fi
    
    echo ""
    echo -e "${YELLOW}Credenciais Padrão:${NC}"
    echo "  • Email:    admin@meetingai.com"
    echo "  • Senha:    admin123"
    echo -e "${RED}  ⚠️  ALTERE A SENHA IMEDIATAMENTE!${NC}"
    echo ""
    
    echo -e "${YELLOW}Comandos Úteis:${NC}"
    echo "  • Ver logs:          cd $PROJECT_DIR && docker compose logs -f"
    echo "  • Reiniciar:         cd $PROJECT_DIR && docker compose restart"
    echo "  • Parar:              cd $PROJECT_DIR && docker compose stop"
    echo "  • Status:             docker compose ps"
    echo "  • Backup manual:      /usr/local/bin/meeting-backup.sh"
    echo ""
    
    echo -e "${YELLOW}Configuração .env:${NC}"
    echo "  • Localização: $PROJECT_DIR/.env"
    echo "  • Edite este arquivo para configurar API keys!"
    echo ""
    
    echo -e "${YELLOW}Próximos Passos:${NC}"
    echo "  1. Edite $PROJECT_DIR/.env e configure suas API keys"
    echo "  2. Reinicie os containers: docker compose restart"
    echo "  3. Acesse a plataforma no navegador"
    echo "  4. Altere a senha do administrador"
    echo ""
    
    if [ -z "$OPENAI_API_KEY" ] || [ -z "$ANTHROPIC_API_KEY" ]; then
        echo -e "${RED}⚠️  IMPORTANTE: Configure as API keys no arquivo .env antes de usar o sistema!${NC}"
        echo ""
    fi
}

# ============================================
# Main Installation Flow
# ============================================
main() {
    clear
    print_banner
    
    # Verificar se é root
    check_root
    
    # Perguntar configurações
    echo -e "${CYAN}Configurações de Instalação:${NC}"
    echo ""
    
    read -p "Tipo de instalação [production/development] (padrão: production): " install_type
    INSTALL_TYPE=${install_type:-production}
    
    read -p "Configurar SSL com Let's Encrypt? [s/N]: " ssl_choice
    if [[ $ssl_choice =~ ^[Ss]$ ]]; then
        WITH_SSL=true
        read -p "Digite o domínio (exemplo: exemplo.com): " DOMAIN
    fi
    
    read -p "Diretório de instalação (padrão: /opt/meeting-ai-platform): " install_dir
    if [ -n "$install_dir" ]; then
        INSTALL_DIR="$install_dir"
    fi
    
    echo ""
    read -p "Pressione ENTER para começar a instalação ou Ctrl+C para cancelar..."
    
    # Iniciar instalação
    update_system
    install_docker
    configure_firewall
    configure_fail2ban
    setup_project
    create_directories
    create_env_file
    build_images
    start_services
    run_migrations
    setup_backup
    
    if [ "$WITH_SSL" = true ]; then
        setup_ssl
    fi
    
    health_check
    print_summary
}

# ============================================
# Run Installation
# ============================================
main "$@"

