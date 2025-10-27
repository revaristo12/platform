# 📦 Guia de Instalação - Meeting AI Platform

## 📋 O Que Foi Criado

Criei um sistema completo de instalação para VPS Ubuntu 20.04 com Docker:

### ✅ Arquivos Criados

1. **`scripts/install-vps.sh`** - Script de instalação automatizada
2. **`docs/VPS_INSTALLATION.md`** - Documentação completa de instalação
3. **`scripts/README.md`** - Guia de uso dos scripts

## 🚀 Instalação Rápida

### Opção 1: Instalação Automática (Recomendada)

```bash
# No servidor VPS Ubuntu 20.04
wget https://seu-repo/scripts/install-vps.sh
chmod +x install-vps.sh
sudo ./install-vps.sh
```

O script irá:
- ✅ Instalar Docker e Docker Compose automaticamente
- ✅ Configurar firewall (UFW)
- ✅ Configurar Fail2Ban (proteção contra ataques)
- ✅ Criar arquivo .env com secrets seguros gerados automaticamente
- ✅ Buildar todos os containers Docker
- ✅ Iniciar todos os serviços
- ✅ Configurar backup automático (diário às 2:00 AM)
- ✅ Opcionalmente configurar SSL com Let's Encrypt

### Opção 2: Instalação Manual

Siga o guia completo em: **`docs/VPS_INSTALLATION.md`**

## ⚙️ Configuração Necessária

Após a instalação, você DEVE configurar as API Keys:

```bash
nano /opt/meeting-ai-platform/.env
```

Configure:
- `OPENAI_API_KEY=sk-sua-chave-aqui` (obrigatório)
- `ANTHROPIC_API_KEY=sk-ant-sua-chave-aqui` (obrigatório)
- Outras configurações conforme necessário

## 📊 O Que o Sistema Inclui

### Serviços (Containers Docker)

1. **Backend** (FastAPI) - Porta 8000
2. **Frontend** (React) - Porta 3000
3. **PostgreSQL** - Banco de dados
4. **Redis** - Cache e sessões
5. **Celery Worker** - Processamento assíncrono
6. **Celery Beat** - Agendamento de tarefas
7. **Nginx** - Reverse proxy
8. **Coturn** - Servidor TURN para WebRTC
9. **Adminer** - Interface web do DB (apenas dev)

### Recursos de Segurança

- ✅ Firewall (UFW) configurado
- ✅ Fail2Ban contra ataques
- ✅ SSL/TLS suportado
- ✅ Secrets gerados automaticamente
- ✅ Containers rodando como usuário não-root
- ✅ Logs rotacionados automaticamente
- ✅ Backup automático configurado

### Funcionalidades

- 🎥 Reuniões virtuais com WebRTC
- 🗣️ Transcrição em tempo real (Whisper)
- 🤖 Análise com IA (GPT + Claude)
- 📊 Dashboard de análise
- 👥 Gestão de participantes
- 💾 Armazenamento de gravações
- 🔄 Processamento assíncrono com Celery
- 📡 API REST completa
- 📚 Documentação Swagger automática

## 🎯 Comandos Úteis

```bash
# Ver logs em tempo real
cd /opt/meeting-ai-platform
docker compose logs -f

# Reiniciar todos os serviços
docker compose restart

# Ver status dos containers
docker compose ps

# Parar todos os serviços
docker compose stop

# Iniciar em modo produção
make prod

# Backup manual
sudo /usr/local/bin/meeting-backup.sh

# Acessar shell do backend
docker compose exec backend /bin/bash
```

## 📚 Documentação

- **Instalação VPS**: `docs/VPS_INSTALLATION.md`
- **README Principal**: `README.md`
- **Quick Start**: `QUICKSTART.md`
- **Scripts**: `scripts/README.md`

## ⚠️ Checklist Pós-Instalação

- [ ] Executar script de instalação
- [ ] Configurar OPENAI_API_KEY no .env
- [ ] Configurar ANTHROPIC_API_KEY no .env
- [ ] Reiniciar containers após configurar APIs
- [ ] Acessar http://seu-servidor:3000
- [ ] Alterar senha do admin (padrão: admin123)
- [ ] Configurar SSL se tiver domínio
- [ ] Testar todas as funcionalidades
- [ ] Verificar logs (sem erros)

## 🔒 Segurança

### Antes de Colocar em Produção:

1. ✅ Alterar senha do administrador padrão
2. ✅ Configurar SSL/TLS
3. ✅ Remover usuário admin padrão
4. ✅ Configurar CORS adequadamente
5. ✅ Revisar configurações de firewall
6. ✅ Habilitar backups automáticos (já configurado)
7. ✅ Configurar monitoramento (opcional)

## 🆘 Troubleshooting

### Container não inicia
```bash
docker compose logs <nome-do-container>
```

### Erro de conexão com banco
```bash
docker compose restart postgres
docker compose logs postgres
```

### Recriar tudo do zero
```bash
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

## 📞 Suporte

Para ajuda adicional:
- Leia a documentação completa em `docs/VPS_INSTALLATION.md`
- Verifique os logs: `docker compose logs -f`
- API Docs: http://seu-servidor:8000/docs

---

**Desenvolvido com ❤️ para reuniões inteligentes!**

