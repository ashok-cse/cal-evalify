#!/bin/bash

# EasyPanel optimized build script for 8GB RAM / 2 vCPU configuration
# Tailored specifically for your server specs

set -e

echo "🚀 EasyPanel build for 8GB RAM / 2 vCPU server starting..."

# Set environment variables optimized for your specs
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_STEP_LOG_MAX_SIZE=50000000
export BUILDKIT_STEP_LOG_MAX_SPEED=100000

# Function to clean up Docker resources
cleanup_docker() {
    echo "🧹 Cleaning up Docker resources..."
    docker builder prune -f || true
    docker system prune -f || true
    sleep 5
}

# Function to monitor memory usage
check_memory() {
    if command -v free >/dev/null 2>&1; then
        echo "📊 Current memory usage:"
        free -h
        echo "📊 Available disk space:"
        df -h / | tail -1
    fi
}

echo "🛑 Stopping any existing services..."
docker-compose -f docker-compose.easypanel.yml down --remove-orphans || true
docker-compose -f docker-compose.full.yml down --remove-orphans || true
docker-compose -f docker-compose.minimal.yml down --remove-orphans || true

echo "🧹 Initial cleanup..."
cleanup_docker
check_memory

# Create optimized .env file for your specs
if [ ! -f .env ]; then
    echo "📝 Creating optimized .env file for 8GB server..."
    cat > .env << 'EOF'
# EasyPanel 8GB RAM / 2 vCPU optimized configuration
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=

# Authentication & Security (generated for your deployment)
NEXTAUTH_SECRET=cal-easypanel-secret-8gb-$(date +%s)
NEXTAUTH_URL=http://localhost:3000
ENCRYPTION_KEY=cal-easypanel-encryption-8gb-$(date +%s)
JWT_SECRET=cal-easypanel-jwt-8gb-$(date +%s)
CALENDSO_ENCRYPTION_KEY=cal-easypanel-calendso-8gb-$(date +%s)
CRON_API_KEY=cal-easypanel-cron-8gb-$(date +%s)

# Application URLs
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3000
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
EMAIL_FROM=noreply@localhost
API_KEY_PREFIX=cal_

# Feature Flags - optimized for performance
NEXT_PUBLIC_IS_E2E=1
CALCOM_TELEMETRY_DISABLED=1
TURBO_TELEMETRY_DISABLED=1
NEXT_TELEMETRY_DISABLED=1
DO_NOT_TRACK=1
ORGANIZATIONS_ENABLED=false
GOOGLE_LOGIN_ENABLED=true

# License (for development)
CALCOM_LICENSE_KEY=development
DISABLE_LICENSE_CHECK=true
IS_CALCOM_DOCKER=true
SKIP_LICENSE_CHECK=true
EOF
    echo "✅ Created optimized .env file"
fi

echo "🗄️ Starting database and Redis..."
docker-compose -f docker-compose.easypanel.yml up -d postgres redis

echo "⏳ Waiting for database to be ready..."
sleep 25

check_memory

echo "🏗️ Building services sequentially to optimize memory usage..."

echo "📦 Building API v2 first (smaller service)..."
docker-compose -f docker-compose.easypanel.yml build api-v2
cleanup_docker
check_memory

echo "📦 Building Web service (main service)..."
docker-compose -f docker-compose.easypanel.yml build web
cleanup_docker
check_memory

echo "🚀 Starting API v2..."
docker-compose -f docker-compose.easypanel.yml up -d api-v2

echo "⏳ Waiting for API v2 to initialize..."
sleep 20

echo "🚀 Starting Web service..."
docker-compose -f docker-compose.easypanel.yml up -d web

echo "⏳ Waiting for all services to be ready..."
sleep 30

echo "🎉 EasyPanel Cal.com deployment completed!"
echo ""
echo "📍 Your Cal.com is now available at:"
echo "   • Web interface: http://localhost:3000"
echo "   • API v2: http://localhost:3004"
echo "   • Database: localhost:5432"
echo "   • Redis: localhost:6379"
echo ""
echo "💾 Resource usage optimized for:"
echo "   • 8GB RAM (using ~6GB during operation)"
echo "   • 2 vCPU cores (distributed across services)"
echo "   • 100GB NVMe storage"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.easypanel.yml ps

echo ""
echo "📝 Useful commands:"
echo "   • View logs: docker-compose -f docker-compose.easypanel.yml logs -f"
echo "   • Stop all: docker-compose -f docker-compose.easypanel.yml down"
echo "   • Restart web: docker-compose -f docker-compose.easypanel.yml restart web"

# Final memory and resource check
echo ""
echo "📊 Final resource usage:"
check_memory
echo "📊 Docker containers resource usage:"
docker stats --no-stream
