# ============================================
# Multi-stage Dockerfile para Frontend React
# ============================================

FROM node:18-alpine as base

WORKDIR /app

# ============================================
# Stage de dependências
# ============================================
FROM base as dependencies

# Copiar package files
COPY package.json package-lock.json* ./

# Instalar dependências
RUN npm ci

# ============================================
# Stage de desenvolvimento
# ============================================
FROM dependencies as development

# Copiar código fonte
COPY . .

# Expor porta
EXPOSE 3000

# Comando de desenvolvimento com hot reload
CMD ["npm", "start"]

# ============================================
# Stage de build
# ============================================
FROM dependencies as builder

# Copiar código fonte
COPY . .

# Build da aplicação
RUN npm run build

# ============================================
# Stage de produção
# ============================================
FROM nginx:alpine as production

# Copiar build para nginx
COPY --from=builder /app/build /usr/share/nginx/html

# Copiar configuração customizada do nginx
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expor porta
EXPOSE 80

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://localhost/ || exit 1

# Comando padrão
CMD ["nginx", "-g", "daemon off;"]
