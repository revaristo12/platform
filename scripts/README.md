# 📦 Scripts de Instalação

Este diretório contém scripts utilitários para instalação e manutenção do Meeting AI Platform.

## 📄 Scripts Disponíveis

### install-vps.sh

Script de instalação automatizada para VPS Ubuntu 20.04.

**Recursos:**
- ✅ Instala Docker e Docker Compose
- ✅ Configura firewall (UFW)
- ✅ Configura Fail2Ban
- ✅ Cria arquivo .env automaticamente
- ✅ Gera secrets seguros
- ✅ Faz build dos containers
- ✅ Inicia serviços
- ✅ Configura backup automático
- ✅ Configura SSL opcional (Let's Encrypt)

**Uso:**

```bash
# Tornar executável
chmod +x scripts/install-vps.sh

# Executar como root
sudo ./scripts/install-vps.sh
```

**Opções interativas:**
- Tipo de instalação (production/development)
- Configuração SSL com Let's Encrypt
- Diretório de instalação

### pre-deploy-check.sh

Script de validação pré-deploy que verifica:
- ✅ Arquivo .env configurado
- ✅ Secrets não estão usando valores padrão
- ✅ SSL certificados válidos
- ✅ Docker instalado
- ✅ Arquivos necessários presentes
- ✅ Diretórios criados
- ✅ Configurações de segurança
- ✅ Portas disponíveis

**Uso:**

```bash
# Tornar executável
chmod +x scripts/pre-deploy-check.sh

# Executar antes do deploy
./scripts/pre-deploy-check.sh
```

## 🚀 Instalação Completa em VPS

### Pré-requisitos

- Servidor Ubuntu 20.04 LTS
- Acesso root
- Mínimo 4GB RAM
- Mínimo 20GB disco

### Passo a Passo

1. **Preparar servidor:**
   ```bash
   ssh root@seu-servidor
   ```

2. **Executar script de instalação:**
   ```bash
   curl -fsSL https://raw.githubusercontent.com/seu-repo/scripts/install-vps.sh | bash
   ```
   
   Ou baixe e execute localmente:
   ```bash
   wget https://raw.githubusercontent.com/seu-repo/scripts/install-vps.sh
   chmod +x install-vps.sh
   sudo ./install-vps.sh
   ```

3. **Configurar API Keys:**
   ```bash
   nano /opt/meeting-ai-platform/.env
   ```
   
   Configure:
   - `OPENAI_API_KEY`
   - `ANTHROPIC_API_KEY`
   - Ajuste outras configurações conforme necessário

4. **Reiniciar serviços:**
   ```bash
   cd /opt/meeting-ai-platform
   docker compose restart
   ```

5. **Acessar plataforma:**
   - Frontend: http://seu-servidor:3000
   - API: http://seu-servidor:8000
   - Docs: http://seu-servidor:8000/docs

## 📚 Documentação Adicional

- Guia completo de instalação: [docs/VPS_INSTALLATION.md](../docs/VPS_INSTALLATION.md)
- README principal: [README.md](../README.md)
- Quick Start: [QUICKSTART.md](../QUICKSTART.md]

## 🔧 Comandos Úteis Pós-Instalação

```bash
# Ver logs
cd /opt/meeting-ai-platform
docker compose logs -f

# Reiniciar
docker compose restart

# Status
docker compose ps

# Backup manual
sudo /usr/local/bin/meeting-backup.sh

# Acessar shell do backend
docker compose exec backend /bin/bash

# Shell do banco
docker compose exec postgres psql -U meeting_user -d meeting_db
```

## 🆘 Solução de Problemas

### Ver logs de erro
```bash
docker compose logs backend | grep -i error
```

### Recriar containers
```bash
docker compose down -v
docker compose up -d
```

### Verificar saúde dos serviços
```bash
curl http://localhost:8000/health
docker compose ps
```

## 📞 Suporte

Para mais informações, consulte a documentação completa em [docs/VPS_INSTALLATION.md](../docs/VPS_INSTALLATION.md).

