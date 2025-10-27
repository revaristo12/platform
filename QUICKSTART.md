# ⚡ Quick Start - Meeting AI Platform

Guia rápido para colocar o projeto funcionando em **5 minutos**.

---

## 🚀 Início Rápido

### 1️⃣ Pré-requisitos
```bash
# Verifique se tem Docker instalado
docker --version
docker-compose --version
```

Se não tiver, instale:
- Linux: `curl -fsSL https://get.docker.com | sh`
- Mac/Windows: https://www.docker.com/products/docker-desktop

---

### 2️⃣ Clone e Configure

```bash
# Clone o repositório
git clone <seu-repo>
cd meeting-ai-platform

# Setup automático
make setup
```

---

### 3️⃣ Configure APIs

Edite o arquivo `.env`:

```bash
nano .env
```

**Obrigatório configurar:**
```env
# APIs de IA
OPENAI_API_KEY=sk-...        # Obtenha em: https://platform.openai.com/api-keys
ANTHROPIC_API_KEY=sk-ant-... # Obtenha em: https://console.anthropic.com/

# Segurança
JWT_SECRET=qualquer-string-com-mais-de-32-caracteres-aqui
```

**Salve e feche** (Ctrl+X, depois Y, depois Enter)

---

### 4️⃣ Inicie os Serviços

```bash
make start
```

Aguarde ~1-2 minutos enquanto os containers sobem.

---

### 5️⃣ Acesse a Plataforma

Abra no navegador:

🌐 **Frontend:** http://localhost:3000  
📡 **API Docs:** http://localhost:8000/docs  
🗄️ **Database UI:** http://localhost:8080  

**Login inicial:**
- Email: `admin@meetingai.com`
- Senha: `admin123`

⚠️ **Altere a senha imediatamente!**

---

## 🎯 Comandos Úteis

```bash
make logs          # Ver logs de todos os serviços
make stop          # Parar serviços
make restart       # Reiniciar serviços
make shell         # Acessar terminal do backend
make db-migrate    # Rodar migrations do banco
make clean         # Limpar tudo e recomeçar
```

---

## 🆘 Problemas Comuns

### "Port already in use"
```bash
# Descubra o que está usando a porta
sudo lsof -i :8000
# Mate o processo
kill -9 <PID>
# Ou mude a porta no docker-compose.yml
```

### "Permission denied"
```bash
# Linux: adicione seu usuário ao grupo docker
sudo usermod -aG docker $USER
# Faça logout e login novamente
```

### "Cannot connect to database"
```bash
# Reinicie apenas o postgres
docker-compose restart postgres
# Aguarde 10 segundos
make logs-db
```

### Containers não iniciam
```bash
# Limpe tudo e reconstrua
make clean
make build-no-cache
make start
```

---

## 📝 Próximos Passos

Depois que estiver funcionando:

1. **Leia a documentação completa:** `README.md`
2. **Entenda os agentes de IA:** `docs/AI_AGENTS.md`
3. **Configure HTTPS:** Veja seção "Produção" no README
4. **Customize prompts:** Edite `backend/app/agents/analysis_agent.py`

---

## 🎥 Testando o Sistema

### Criar uma Sala
```bash
# Via API (curl)
curl -X POST http://localhost:8000/rooms \
  -H "Content-Type: application/json" \
  -d '{"name": "Reunião Teste", "max_participants": 5}'

# Ou use a interface web em http://localhost:3000
```

### Simular Transcrição
```bash
# Acesse o shell do backend
make shell

# Execute Python
python

# Simule uma transcrição
from app.agents.transcription_agent import TranscriptionAgent
agent = TranscriptionAgent()
# ... seu código de teste
```

---

## 📚 Documentação Completa

- **README.md** - Documentação completa do projeto
- **docs/AI_AGENTS.md** - Arquitetura dos agentes de IA
- **Makefile** - Todos os comandos disponíveis

---

## 🐛 Reportar Problemas

Encontrou um bug? Abra uma issue no GitHub com:
- Logs: `make logs`
- Versão: `docker --version`
- Sistema operacional

---

## 🎉 Pronto!

Seu ambiente está configurado! Agora você pode:

✅ Criar salas de reunião  
✅ Testar transcrição de áudio  
✅ Experimentar análise com IA  
✅ Desenvolver novas features  

**Boa codificação! 🚀**
