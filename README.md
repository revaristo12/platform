# 🎥 Meeting AI Platform - Docker Setup

Plataforma de reuniões virtuais com transcrição em tempo real e análise de IA para governança corporativa e gestão de crises.

## 📋 Índice

- [Pré-requisitos](#pré-requisitos)
- [Instalação Rápida](#instalação-rápida)
- [Arquitetura](#arquitetura)
- [Serviços](#serviços)
- [Comandos Disponíveis](#comandos-disponíveis)
- [Configuração](#configuração)
- [Desenvolvimento](#desenvolvimento)
- [Produção](#produção)
- [Troubleshooting](#troubleshooting)
- [Segurança](#segurança)

---

## 🔧 Pré-requisitos

- **Docker**: >= 20.10
- **Docker Compose**: >= 2.0
- **Make**: Opcional, mas recomendado
- **API Keys**:
  - OpenAI (para Whisper e GPT)
  - Anthropic (para Claude)

### Instalação do Docker

**Linux:**
```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

**macOS/Windows:**
- Download Docker Desktop: https://www.docker.com/products/docker-desktop

---

## 🚀 Instalação Rápida

### 1. Clone o Repositório
```bash
git clone <seu-repositorio>
cd meeting-ai-platform
```

### 2. Setup Inicial
```bash
make setup
```

Este comando:
- Cria o arquivo `.env` a partir do `.env.example`
- Cria diretórios necessários
- Faz o build dos containers

### 3. Configure as API Keys

Edite o arquivo `.env`:
```bash
nano .env
```

Configure no mínimo:
```env
OPENAI_API_KEY=sk-your-key-here
ANTHROPIC_API_KEY=sk-ant-your-key-here
JWT_SECRET=your-secure-secret-min-32-chars
```

### 4. Inicie os Serviços
```bash
make start
```

### 5. Acesse a Plataforma

- **Frontend**: http://localhost:3000
- **Backend API**: http://localhost:8000
- **API Docs**: http://localhost:8000/docs
- **Adminer (DB)**: http://localhost:8080

**Credenciais iniciais:**
- Email: `admin@meetingai.com`
- Senha: `admin123` (⚠️ **ALTERAR EM PRODUÇÃO!**)

---

## 🏗️ Arquitetura

```
┌──────────────┐
│   Usuário    │
└──────┬───────┘
       │
┌──────▼────────┐
│  Nginx:80/443 │ (Reverse Proxy)
└──────┬────────┘
       │
       ├──► Frontend:3000 (React)
       │
       └──► Backend:8000 (FastAPI)
              │
              ├──► PostgreSQL:5432 (Database)
              ├──► Redis:6379 (Cache/Queue)
              ├──► Celery Workers (AI Processing)
              └──► Coturn:3478 (WebRTC TURN)
```

---

## 🐳 Serviços

| Serviço | Porta | Descrição |
|---------|-------|-----------|
| **backend** | 8000 | API FastAPI com WebSocket |
| **frontend** | 3000 | Interface React |
| **postgres** | 5432 | Banco de dados PostgreSQL |
| **redis** | 6379 | Cache e fila de mensagens |
| **celery-worker** | - | Processamento assíncrono |
| **celery-beat** | - | Agendamento de tarefas |
| **nginx** | 80, 443 | Reverse proxy |
| **coturn** | 3478, 5349 | TURN server para WebRTC |
| **adminer** | 8080 | Interface web para DB (dev) |

---

## 🎮 Comandos Disponíveis

### Setup & Build
```bash
make setup          # Setup inicial completo
make build          # Build dos containers
make build-no-cache # Build sem cache
```

### Gerenciamento de Containers
```bash
make start    # Inicia todos os serviços
make stop     # Para todos os serviços
make restart  # Reinicia todos os serviços
make down     # Para e remove containers
make status   # Status dos containers
```

### Logs & Monitoring
```bash
make logs           # Logs de todos os serviços
make logs-backend   # Logs apenas do backend
make logs-frontend  # Logs apenas do frontend
make logs-celery    # Logs do Celery worker
make stats          # Estatísticas dos containers
make health         # Verifica saúde dos serviços
```

### Desenvolvimento
```bash
make shell          # Acessa shell do backend
make shell-db       # Acessa PostgreSQL CLI
make shell-redis    # Acessa Redis CLI
make test           # Executa testes
make test-coverage  # Testes com cobertura
make lint           # Executa linters
make format         # Formata código
```

### Database
```bash
make db-migrate   # Executa migrations
make db-rollback  # Reverte última migration
make db-reset     # Reset completo (⚠️ apaga dados)
make db-backup    # Backup do banco
```

### Limpeza
```bash
make clean      # Remove containers e volumes
make clean-all  # Remove tudo (incluindo imagens)
make clean-logs # Limpa arquivos de log
```

### Produção
```bash
make prod       # Inicia em modo produção
make prod-logs  # Logs do ambiente de produção
make prod-down  # Para produção
```

---

## ⚙️ Configuração

### Variáveis de Ambiente Principais

#### Aplicação
```env
ENVIRONMENT=development          # development | production
DEBUG=True                       # True | False
JWT_SECRET=<32+ caracteres>      # OBRIGATÓRIO
```

#### Database
```env
DATABASE_URL=postgresql://user:pass@postgres:5432/db
```

#### APIs de IA
```env
OPENAI_API_KEY=sk-...           # Para Whisper e GPT
ANTHROPIC_API_KEY=sk-ant-...    # Para Claude
WHISPER_MODEL=base              # tiny|base|small|medium|large
CLAUDE_MODEL=claude-3-opus-20240229
```

#### WebRTC
```env
TURN_SERVER_URL=turn:localhost:3478
TURN_SERVER_USERNAME=meeting
TURN_SERVER_PASSWORD=meeting123
```

#### Transcrição
```env
TRANSCRIPTION_LANGUAGE=pt       # Idioma padrão
ENABLE_SPEAKER_DIARIZATION=True # Identificar falantes
```

#### Análise de IA
```env
AI_ANALYSIS_ENABLED=True
AI_ANALYSIS_INTERVAL=300        # Segundos (5 min)
AI_ANALYSIS_MIN_WORDS=100       # Mínimo de palavras
```

---

## 💻 Desenvolvimento

### 1. Modo de Desenvolvimento
```bash
make start
```

Recursos habilitados:
- **Hot reload** no backend e frontend
- **Debug mode** ativado
- **Adminer** para gerenciar DB
- **Logs detalhados**

### 2. Estrutura de Código

```
backend/
├── app/
│   ├── api/              # Endpoints da API
│   ├── agents/           # Agentes de IA
│   ├── models/           # Modelos SQLAlchemy
│   ├── services/         # Lógica de negócio
│   ├── utils/            # Utilitários
│   └── main.py           # Entry point
├── db/
│   └── init.sql          # SQL de inicialização
├── Dockerfile
└── requirements.txt

frontend/
├── src/
│   ├── components/       # Componentes React
│   ├── pages/            # Páginas
│   ├── services/         # Serviços/API
│   └── utils/            # Utilitários
├── Dockerfile
└── package.json
```

### 3. Adicionando Dependências

**Backend (Python):**
```bash
# Edite requirements.txt
make build
make restart
```

**Frontend (Node):**
```bash
docker-compose exec frontend npm install <package>
```

### 4. Rodando Testes
```bash
make test              # Todos os testes
make test-coverage     # Com relatório de cobertura
```

### 5. Database Migrations
```bash
# Criar nova migration
docker-compose exec backend alembic revision --autogenerate -m "description"

# Aplicar migrations
make db-migrate
```

---

## 🚀 Produção

### 1. Preparação

**a) Configure variáveis de produção no `.env`:**
```env
ENVIRONMENT=production
DEBUG=False
JWT_SECRET=<secret-forte-64-chars>
CORS_ORIGINS=["https://seu-dominio.com"]
```

**b) Configure SSL no Nginx:**
- Coloque certificados em `nginx/ssl/`
- Descomente configuração HTTPS em `nginx/nginx.conf`

**c) Atualize secrets do TURN server:**
```env
TURN_SERVER_PASSWORD=<password-forte>
```

### 2. Deploy

```bash
make prod
```

### 3. Monitoramento

```bash
make prod-logs   # Ver logs
make stats       # Estatísticas
make health      # Health check
```

### 4. Backup Automático

Configure cron job:
```bash
0 2 * * * cd /path/to/project && make db-backup
```

---

## 🔍 Troubleshooting

### Container não inicia
```bash
# Verifique logs
make logs

# Recrie containers
make down
make build-no-cache
make start
```

### Erro de conexão com Database
```bash
# Verifique se PostgreSQL está rodando
docker-compose ps postgres

# Reinicie o serviço
docker-compose restart postgres

# Verifique logs
make logs-db
```

### Erro de permissão em volumes
```bash
# Linux: ajuste permissões
sudo chown -R $USER:$USER backend/recordings backend/transcriptions

# Recrie volumes
make down
docker volume prune
make start
```

### Porta já em uso
```bash
# Descubra processo usando a porta
sudo lsof -i :8000

# Mate o processo
kill -9 <PID>

# Ou mude a porta no docker-compose.yml
```

### Whisper Out of Memory
```bash
# Use modelo menor no .env
WHISPER_MODEL=tiny  # ou base
```

### WebRTC não conecta
```bash
# Verifique se TURN server está rodando
docker-compose logs coturn

# Teste conectividade
telnet localhost 3478
```

---

## 🔒 Segurança

### ⚠️ ANTES DE IR PARA PRODUÇÃO:

1. **Altere TODOS os secrets:**
   ```env
   JWT_SECRET=<gere com: openssl rand -hex 32>
   POSTGRES_PASSWORD=<senha forte>
   TURN_SERVER_PASSWORD=<senha forte>
   ```

2. **Configure SSL/TLS:**
   - Use Let's Encrypt ou certificado válido
   - Descomente configuração HTTPS no nginx

3. **Remova credenciais padrão:**
   ```sql
   -- Remova ou altere usuário admin padrão
   DELETE FROM users WHERE email = 'admin@meetingai.com';
   ```

4. **Configure firewall:**
   ```bash
   # Exemplo UFW (Ubuntu)
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw allow 3478/tcp  # TURN
   sudo ufw enable
   ```

5. **Atualize CORS:**
   ```env
   CORS_ORIGINS=["https://seu-dominio.com"]
   ```

6. **Configure rate limiting:**
   - Já configurado no Nginx
   - Ajuste valores em `nginx/nginx.conf`

7. **Backups regulares:**
   ```bash
   # Configure backup automático
   make db-backup
   ```

---

## 📊 Monitoramento

### Logs em tempo real
```bash
# Todos os serviços
make logs

# Serviço específico
docker-compose logs -f backend
```

### Estatísticas de recursos
```bash
make stats
```

### Health checks
```bash
make health
```

---

## 🤝 Contribuindo

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/MinhaFeature`)
3. Commit suas mudanças (`git commit -m 'Add: Minha feature'`)
4. Push para a branch (`git push origin feature/MinhaFeature`)
5. Abra um Pull Request

---

## 📝 Licença

Este projeto está sob a licença MIT.

---

## 🆘 Suporte

- **Documentação**: Leia este README
- **Issues**: Abra uma issue no GitHub
- **Discord**: [Link do servidor]

---

## 🎯 Próximos Passos

Após o setup do Docker estar funcionando:

1. **[Frontend]** Implementar interface React
2. **[Backend]** Desenvolver API endpoints
3. **[WebRTC]** Integrar comunicação de vídeo
4. **[IA]** Implementar agentes de transcrição e análise
5. **[Testes]** Escrever testes automatizados

---

**Feito com ❤️ para análise inteligente de reuniões**
