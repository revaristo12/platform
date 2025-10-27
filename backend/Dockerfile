# ============================================
# Multi-stage Dockerfile para Backend Python
# ============================================

FROM python:3.11-slim as base

# Variáveis de ambiente
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    ffmpeg \
    libsndfile1 \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ============================================
# Stage de dependências
# ============================================
FROM base as dependencies

# Copiar arquivos de requisitos
COPY requirements.txt .

# Instalar dependências Python
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# ============================================
# Stage de desenvolvimento
# ============================================
FROM dependencies as development

# Copiar código da aplicação
COPY . .

# Criar diretórios necessários
RUN mkdir -p /app/recordings /app/transcriptions /app/logs

# Expor porta
EXPOSE 8000

# Comando padrão (pode ser sobrescrito no docker-compose)
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000", "--reload"]

# ============================================
# Stage de produção
# ============================================
FROM dependencies as production

# Copiar apenas o necessário
COPY ./app /app/app
COPY ./alembic /app/alembic
COPY alembic.ini /app/

# Usuário não-root para segurança
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app
USER appuser

# Criar diretórios com permissões corretas
RUN mkdir -p /app/recordings /app/transcriptions /app/logs

EXPOSE 8000

# Comando de produção com múltiplos workers
CMD ["gunicorn", "app.main:app", \
     "--workers", "4", \
     "--worker-class", "uvicorn.workers.UvicornWorker", \
     "--bind", "0.0.0.0:8000", \
     "--access-logfile", "-", \
     "--error-logfile", "-"]
