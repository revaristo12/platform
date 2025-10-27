# 📦 Guia de Instalação - VPS Ubuntu 20.04

Este guia fornece instruções detalhadas para instalar o Meeting AI Platform em um servidor VPS com Ubuntu 20.04 e Docker.

---

## 📋 Índice

- [Requisitos](#requisitos)
- [Instalação Rápida](#instalação-rápida)
- [Instalação Manual](#instalação-manual)
- [Configuração Pós-Instalação](#configuração-pós-instalação)
- [Solução de Problemas](#solução-de-problemas)
- [Segurança](#segurança)
- [Backup e Restauração](#backup-e-restauração)
- [Atualização](#atualização)

---

## 🔧 Requisitos

### Servidor VPS

- **SO**: Ubuntu 20.04 LTS ou superior
- **CPU**: Mínimo 2 cores (recomendado: 4+ cores)
- **RAM**: Mínimo 4GB (recomendado: 8GB+)
- **Disco**: Mínimo 20GB (recomendado: 50GB+)
- **Conexão**: Mínimo 10Mbps upload/download

### Serviços Necessários

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **Firewall**: UFW (incluído no Ubuntu)
- **Fail2Ban**: Proteção contra ataques

### API Keys (Obrigatório)

- **OpenAI API Key**: Para transcrição (Whisper) e análise (GPT)
  - Obtenha em: https://platform.openai.com/api-keys
- **Anthropic API Key**: Para análise avançada (Claude)
  - Obtenha em: https://console.anthropic.com/

### Opcional

- Domínio próprio (para SSL)
- Certificado SSL (Let's Encrypt ou comercial)

---

## 🚀 Instalação Rápida

### Passo 1: Preparar o Servidor

```bash
# Atualizar sistema
sudo apt update && sudo apt upgrade -y

# Instalar dependências básicas
sudo apt install -y curl wget git vim
```

### Passo 2: Executar Script de Instalação

```bash
# Clonar o repositório
git clone <seu-repositorio> /opt/meeting-ai-platform

# Ou baixar apenas o script
wget https://raw.githubusercontent.com/seu-repo/meeting-ai-platform/main/scripts/install-vps.sh
chmod +x install-vps.sh

# Executar instalação
sudo ./install-vps.sh
```

O script irá:
- ✅ Instalar Docker e Docker Compose
- ✅ Configurar firewall (UFW)
- ✅ Configurar Fail2Ban
- ✅ Criar arquivo .env
- ✅ Buildar containers
- ✅ Iniciar serviços
- ✅ Configurar backup automático
- ✅ Configurar SSL (opcional)

---

## 🔨 Instalação Manual

### 1. Instalar Docker

```bash
# Remover versões antigas
sudo apt remove docker docker-engine docker.io containerd runc

# Instalar repositório Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Instalar Docker
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Instalar Docker Compose standalone (backup)
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verificar instalação
docker --version
docker compose version
```

### 2. Configurar Firewall

```bash
# Permitir portas necessárias
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 3478/tcp  # STUN/TURN
sudo ufw allow 3478/udp  # STUN/TURN
sudo ufw allow 5349/tcp  # TURN TLS
sudo ufw allow 5349/udp  # TURN TLS
sudo ufw allow 49152:49200/udp  # TURN RTP Range

# Habilitar firewall
sudo ufw enable
sudo ufw status
```

### 3. Clonar o Projeto

```bash
# Criar diretório
sudo mkdir -p /opt/meeting-ai-platform
sudo chown $USER:$USER /opt/meeting-ai-platform

# Clonar repositório
git clone <seu-repositorio> /opt/meeting-ai-platform
cd /opt/meeting-ai-platform
```

### 4. Configurar .env

```bash
# Copiar arquivo de exemplo
cp .env.example .env

# Editar configurações
nano .env
```

Configure as seguintes variáveis:

```env
# Obrigatório - APIs
OPENAI_API_KEY=sk-seu-key-aqui
ANTHROPIC_API_KEY=sk-ant-seu-key-aqui

# Obrigatório - Segurança
JWT_SECRET=$(openssl rand -hex 32)
POSTGRES_PASSWORD=$(openssl rand -base64 24)

# Opcional - Domínio (se tiver)
DOMAIN=seu-dominio.com
```

### 5. Buildar e Iniciar

```bash
# Criar diretórios necessários
mkdir -p backend/recordings backend/transcriptions backend/logs
mkdir -p frontend/public frontend/src
mkdir -p nginx/ssl
mkdir -p backups

# Buildar containers
docker compose build

# Iniciar em produção
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d

# Verificar status
docker compose ps
docker compose logs -f
```

---

## ⚙️ Configuração Pós-Instalação

### 1. Configurar API Keys

Edite o arquivo `.env`:

```bash
nano .env
```

Configure:
- `OPENAI_API_KEY`: Sua chave da OpenAI
- `ANTHROPIC_API_KEY`: Sua chave da Anthropic
- `JWT_SECRET`: Já foi gerado automaticamente
- `POSTGRES_PASSWORD`: Já foi gerado automaticamente

Salve e reinicie:

```bash
docker compose restart
```

### 2. Configurar SSL (Let's Encrypt)

```bash
# Instalar Certbot
sudo apt install -y certbot

# Parar nginx
docker compose stop nginx

# Obter certificado
sudo certbot certonly --standalone -d seu-dominio.com

# Copiar certificados
sudo cp /etc/letsencrypt/live/seu-dominio.com/fullchain.pem nginx/ssl/cert.pem
sudo cp /etc/letsencrypt/live/seu-dominio.com/privkey.pem nginx/ssl/key.pem

# Reiniciar nginx
docker compose up -d nginx

# Configurar renovação automática
sudo certbot renew --dry-run
```

### 3. Criar Usuário Administrador

```bash
# Acessar shell do backend
docker compose exec backend /bin/bash

# Executar script de criação
python -m app.scripts.create_admin
```

### 4. Verificar Funcionamento

```bash
# Ver logs
docker compose logs -f

# Testar endpoints
curl http://localhost:8000/health
curl http://localhost:8000/docs
```

### 5. Configurar Backup Automático

O backup automático já está configurado! Verifique:

```bash
# Verificar cron job
crontab -l

# Executar backup manual
sudo /usr/local/bin/meeting-backup.sh
```

---

## 🔧 Solução de Problemas

### Container não inicia

```bash
# Ver logs detalhados
docker compose logs <nome-do-container>

# Recriar containers
docker compose down
docker compose up -d
```

### Erro de conexão com banco

```bash
# Verificar se PostgreSQL está rodando
docker compose ps postgres

# Reiniciar PostgreSQL
docker compose restart postgres

# Ver logs
docker compose logs postgres
```

### Porta já em uso

```bash
# Verificar o que está usando a porta
sudo lsof -i :8000

# Matar o processo
sudo kill -9 <PID>
```

### Problemas de memória

Se o sistema ficar lento, reduza a carga:

```bash
# Editar docker-compose.prod.yml
nano docker-compose.prod.yml

# Reduzir workers do Celery
# De: concurrency=4
# Para: concurrency=2
```

### Recriar tudo do zero

```bash
# Parar e remover tudo
docker compose down -v

# Remover imagens
docker rmi $(docker images -q)

# Rebuildar
docker compose build --no-cache
docker compose up -d
```

---

## 🔒 Segurança

### 1. Alterar Senha do Administrador

```bash
# Via interface web
# Acesse: http://seu-servidor:3000
# Login: admin@meetingai.com
# Senha padrão: admin123
# ✅ ALTERE IMEDIATAMENTE!
```

### 2. Configurar SSH

```bash
# Desabilitar login root via SSH
sudo nano /etc/ssh/sshd_config
# Alterar: PermitRootLogin no

# Reiniciar SSH
sudo systemctl restart ssh
```

### 3. Fail2Ban

Já configurado automaticamente pelo script!

### 4. Firewall

Já configurado! Verifique:

```bash
sudo ufw status verbose
```

### 5. Atualizações de Segurança

```bash
# Configurar atualizações automáticas
sudo dpkg-reconfigure -plow unattended-upgrades

# Atualizar manualmente
sudo apt update && sudo apt upgrade
```

### 6. Limitar Acesso ao Admin

Remova ou desabilite Adminer em produção:

```bash
# Comentar no docker-compose.yml
# adminer:
#   ...
```

---

## 💾 Backup e Restauração

### Backup Manual

```bash
# Executar backup
sudo /usr/local/bin/meeting-backup.sh

# Listar backups
ls -lh backups/
```

### Restauração do Banco

```bash
# Parar containers
docker compose stop

# Copiar backup para dentro do container
docker cp backups/db_backup_YYYYMMDD_HHMMSS.sql meeting-postgres:/tmp

# Restaurar
docker compose exec -T postgres psql -U meeting_user meeting_db < backups/db_backup_YYYYMMDD_HHMMSS.sql

# Reiniciar
docker compose start
```

### Backup Completo

```bash
# Fazer backup de tudo
tar -czf backup-completo.tar.gz \
    backups/ \
    backend/recordings \
    backend/transcriptions \
    nginx/ssl \
    .env
```

---

## 🔄 Atualização

### Atualizar do Repositório

```bash
cd /opt/meeting-ai-platform

# Fazer backup
sudo /usr/local/bin/meeting-backup.sh

# Pull de atualizações
git pull

# Rebuildar containers
docker compose build

# Reiniciar
docker compose down
docker compose up -d
```

### Atualizar Sistema Operacional

```bash
# Atualizar pacotes
sudo apt update && sudo apt upgrade -y

# Reboot (se necessário)
sudo reboot
```

---

## 📊 Monitoramento

### Logs em Tempo Real

```bash
# Todos os serviços
docker compose logs -f

# Serviço específico
docker compose logs -f backend

# Últimas 100 linhas
docker compose logs --tail=100 backend
```

### Estatísticas de Recursos

```bash
# Recursos dos containers
docker stats

# Uso de disco
df -h

# Memória
free -h
```

### Health Checks

```bash
# Verificar saúde dos serviços
curl http://localhost:8000/health
curl http://localhost:8000/docs

# Verificar containers
docker compose ps
docker compose top
```

---

## 🆘 Suporte

### Comandos Úteis

```bash
# Ver todos os logs
docker compose logs -f

# Reiniciar serviço específico
docker compose restart backend

# Acessar shell de um container
docker compose exec backend /bin/bash

# Ver configurações
docker compose config

# Limpar espaço (cuidado!)
docker system prune -a
```

### Recursos

- **Documentação**: [README.md](../README.md)
- **Quick Start**: [QUICKSTART.md](../QUICKSTART.md)
- **API Docs**: http://seu-servidor:8000/docs
- **Logs**: `docker compose logs -f`

---

## ✅ Checklist Pós-Instalação

- [ ] Docker instalado e funcionando
- [ ] Firewall configurado
- [ ] Fail2Ban configurado
- [ ] Arquivo .env configurado com API keys
- [ ] Containers iniciados e saudáveis
- [ ] Banco de dados inicializado
- [ ] SSL configurado (se aplicável)
- [ ] Backups automáticos configurados
- [ ] Senha do administrador alterada
- [ ] Acesso testado no navegador
- [ ] Logs verificados (sem erros)
- [ ] Monitoramento configurado

---

**✨ Pronto! Seu servidor está configurado e pronto para uso!**

Desenvolvido com ❤️ para reuniões inteligentes.

