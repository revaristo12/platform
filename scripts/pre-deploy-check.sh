#!/bin/bash

# ============================================
# Meeting AI Platform - Pre-Deploy Check
# ============================================
# This script validates configuration and 
# security settings before deployment
# ============================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
ERRORS=0
WARNINGS=0
SUCCESS=0

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║     Meeting AI Platform - Pre-Deploy Check            ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# ============================================
# Helper Functions
# ============================================

check_pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((SUCCESS++))
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
    ((WARNINGS++))
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    ((ERRORS++))
}

# ============================================
# 1. Environment File Check
# ============================================

echo -e "\n${BLUE}[1/10] Checking Environment Configuration...${NC}"

if [ ! -f .env ]; then
    check_fail ".env file not found! Copy from .env.example"
else
    check_pass ".env file exists"
    
    # Check critical variables
    source .env
    
    if [ "$ENVIRONMENT" != "production" ]; then
        check_warn "ENVIRONMENT is not set to 'production'"
    else
        check_pass "ENVIRONMENT set to production"
    fi
    
    if [ "$DEBUG" = "True" ]; then
        check_fail "DEBUG is True - must be False in production!"
    else
        check_pass "DEBUG is False"
    fi
fi

# ============================================
# 2. Secrets Validation
# ============================================

echo -e "\n${BLUE}[2/10] Validating Secrets...${NC}"

source .env 2>/dev/null || true

# Check JWT Secret
if [ -z "$JWT_SECRET" ] || [ "$JWT_SECRET" = "your-secret-key-change-in-production" ]; then
    check_fail "JWT_SECRET not set or using default value!"
elif [ ${#JWT_SECRET} -lt 32 ]; then
    check_fail "JWT_SECRET too short (minimum 32 characters)"
else
    check_pass "JWT_SECRET is properly set"
fi

# Check API Keys
if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "sk-your-openai-api-key-here" ]; then
    check_warn "OPENAI_API_KEY not configured"
else
    check_pass "OPENAI_API_KEY is set"
fi

if [ -z "$ANTHROPIC_API_KEY" ] || [ "$ANTHROPIC_API_KEY" = "sk-ant-your-anthropic-api-key-here" ]; then
    check_warn "ANTHROPIC_API_KEY not configured"
else
    check_pass "ANTHROPIC_API_KEY is set"
fi

# Check Database Password
if [ -z "$POSTGRES_PASSWORD" ] || [ "$POSTGRES_PASSWORD" = "meeting_pass" ]; then
    check_fail "POSTGRES_PASSWORD using default value!"
else
    check_pass "POSTGRES_PASSWORD is customized"
fi

# Check TURN Server Password
if [ "$TURN_SERVER_PASSWORD" = "meeting123" ]; then
    check_fail "TURN_SERVER_PASSWORD using default value!"
else
    check_pass "TURN_SERVER_PASSWORD is customized"
fi

# ============================================
# 3. CORS Configuration
# ============================================

echo -e "\n${BLUE}[3/10] Checking CORS Configuration...${NC}"

if [[ "$CORS_ORIGINS" == *"localhost"* ]]; then
    check_warn "CORS_ORIGINS contains localhost - not recommended for production"
else
    check_pass "CORS_ORIGINS properly configured"
fi

if [[ "$CORS_ORIGINS" == *"*"* ]]; then
    check_fail "CORS_ORIGINS allows all origins (*) - security risk!"
fi

# ============================================
# 4. SSL/TLS Configuration
# ============================================

echo -e "\n${BLUE}[4/10] Checking SSL/TLS Configuration...${NC}"

if [ ! -f nginx/ssl/cert.pem ] || [ ! -f nginx/ssl/key.pem ]; then
    check_warn "SSL certificates not found in nginx/ssl/"
    check_warn "HTTPS will not be available"
else
    check_pass "SSL certificates found"
    
    # Check certificate expiration
    EXPIRY=$(openssl x509 -enddate -noout -in nginx/ssl/cert.pem | cut -d= -f2)
    EXPIRY_EPOCH=$(date -d "$EXPIRY" +%s)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( ($EXPIRY_EPOCH - $NOW_EPOCH) / 86400 ))
    
    if [ $DAYS_LEFT -lt 30 ]; then
        check_warn "SSL certificate expires in $DAYS_LEFT days"
    else
        check_pass "SSL certificate valid for $DAYS_LEFT days"
    fi
fi

# ============================================
# 5. Docker Configuration
# ============================================

echo -e "\n${BLUE}[5/10] Checking Docker Configuration...${NC}"

if ! command -v docker &> /dev/null; then
    check_fail "Docker is not installed"
else
    check_pass "Docker is installed"
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | sed 's/,//')
    echo "   Version: $DOCKER_VERSION"
fi

if ! command -v docker-compose &> /dev/null; then
    check_fail "Docker Compose is not installed"
else
    check_pass "Docker Compose is installed"
    COMPOSE_VERSION=$(docker-compose --version | awk '{print $4}')
    echo "   Version: $COMPOSE_VERSION"
fi

# ============================================
# 6. Required Files
# ============================================

echo -e "\n${BLUE}[6/10] Checking Required Files...${NC}"

REQUIRED_FILES=(
    "docker-compose.yml"
    "docker-compose.prod.yml"
    "backend/Dockerfile"
    "backend/requirements.txt"
    "frontend/Dockerfile"
    "nginx/nginx.conf"
    "coturn/turnserver.conf"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_pass "$file exists"
    else
        check_fail "$file not found"
    fi
done

# ============================================
# 7. Directory Structure
# ============================================

echo -e "\n${BLUE}[7/10] Checking Directory Structure...${NC}"

REQUIRED_DIRS=(
    "backend/recordings"
    "backend/transcriptions"
    "backend/logs"
    "nginx/ssl"
    "backups"
)

for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        check_pass "$dir exists"
    else
        check_warn "$dir not found - creating..."
        mkdir -p "$dir"
    fi
done

# ============================================
# 8. Database Initialization
# ============================================

echo -e "\n${BLUE}[8/10] Checking Database Configuration...${NC}"

if [ -f "backend/db/init.sql" ]; then
    check_pass "Database initialization script exists"
else
    check_fail "backend/db/init.sql not found"
fi

# ============================================
# 9. Security Checks
# ============================================

echo -e "\n${BLUE}[9/10] Running Security Checks...${NC}"

# Check for exposed secrets in files
if grep -r "sk-" --include="*.py" --include="*.js" --exclude-dir=node_modules backend/ frontend/ 2>/dev/null; then
    check_fail "Potential API keys found in code!"
else
    check_pass "No hardcoded API keys detected"
fi

# Check .gitignore
if [ -f ".gitignore" ]; then
    if grep -q ".env" .gitignore; then
        check_pass ".gitignore properly configured"
    else
        check_warn ".env not in .gitignore"
    fi
else
    check_warn ".gitignore not found"
fi

# ============================================
# 10. Port Availability
# ============================================

echo -e "\n${BLUE}[10/10] Checking Port Availability...${NC}"

PORTS=(80 443 3000 5432 6379 8000 8080)

for port in "${PORTS[@]}"; do
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1; then
        check_warn "Port $port is already in use"
    else
        check_pass "Port $port is available"
    fi
done

# ============================================
# Summary
# ============================================

echo -e "\n${BLUE}════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}                   SUMMARY REPORT                       ${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}✓ Passed:${NC}   $SUCCESS"
echo -e "${YELLOW}⚠ Warnings:${NC} $WARNINGS"
echo -e "${RED}✗ Errors:${NC}   $ERRORS"
echo ""

if [ $ERRORS -gt 0 ]; then
    echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║  ❌ DEPLOYMENT BLOCKED - Fix errors before deploying  ║${NC}"
    echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
    exit 1
elif [ $WARNINGS -gt 0 ]; then
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  ⚠️  WARNINGS DETECTED - Review before deploying      ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════╝${NC}"
    echo ""
    read -p "Continue with deployment? [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Deployment cancelled."
        exit 1
    fi
else
    echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║  ✅ ALL CHECKS PASSED - Ready for deployment!         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "  1. Review configuration one more time"
echo "  2. Create a backup: make db-backup"
echo "  3. Deploy: make prod"
echo "  4. Monitor: make prod-logs"
echo ""
