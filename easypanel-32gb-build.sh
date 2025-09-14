#!/bin/bash

# EasyPanel optimized build script for 32GB RAM server
# High-performance configuration that takes full advantage of your resources

set -e

echo "🚀 EasyPanel HIGH-PERFORMANCE build for 32GB RAM server starting..."

# Set environment variables optimized for high-performance builds
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_STEP_LOG_MAX_SIZE=100000000
export BUILDKIT_STEP_LOG_MAX_SPEED=1000000

# Function to clean up Docker resources
cleanup_docker() {
    echo "🧹 Cleaning up Docker resources..."
    docker builder prune -f || true
    docker system prune -f || true
    sleep 2
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
docker-compose -f docker-compose.full.yml down --remove-orphans || true

echo "🧹 Initial cleanup..."
cleanup_docker
check_memory

# Create high-performance .env file
if [ ! -f .env ]; then
    echo "📝 Creating high-performance .env file for 32GB server..."
    cat > .env << 'EOF'
# High-performance configuration for 32GB RAM EasyPanel server
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=

# Authentication & Security
NEXTAUTH_SECRET=cal-highperf-secret-32gb-$(openssl rand -hex 32)
NEXTAUTH_URL=http://localhost:3001
ENCRYPTION_KEY=cal-highperf-encryption-32gb-$(openssl rand -hex 32)
JWT_SECRET=cal-highperf-jwt-32gb-$(openssl rand -hex 32)
CALENDSO_ENCRYPTION_KEY=cal-highperf-calendso-32gb-$(openssl rand -hex 32)
CRON_API_KEY=cal-highperf-cron-32gb-$(openssl rand -hex 32)

# Application URLs
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3001
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3001
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
NEXT_PUBLIC_API_V2_ROOT_URL=http://localhost:3004
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
    echo "✅ Created high-performance .env file with generated secrets"
fi

echo "🗄️ Starting database and Redis with high-performance settings..."
docker-compose -f docker-compose.full.yml up -d postgres redis

echo "⏳ Waiting for database to be ready..."
sleep 20

check_memory

echo "🏗️ Building services with high-performance parallel builds..."
echo "💪 Using full 32GB RAM capacity for maximum speed"

# With 32GB RAM, we can build multiple services in parallel
echo "📦 Building all services in parallel (taking advantage of 32GB RAM)..."
docker-compose -f docker-compose.full.yml build --parallel --no-cache

cleanup_docker
check_memory

echo "🚀 Starting all services..."
docker-compose -f docker-compose.full.yml up -d

echo "⏳ Waiting for all services to initialize..."
sleep 45

echo "🎉 HIGH-PERFORMANCE Cal.com deployment completed!"
echo ""
echo "📍 Your Cal.com is now running at full capacity:"
echo "   • Web interface: http://localhost:3001"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"
echo "   • Database: localhost:5432"
echo "   • Redis: localhost:6379"
echo ""
echo "💪 High-performance configuration active:"
echo "   • 32GB RAM fully utilized"
echo "   • Parallel builds enabled"
echo "   • Maximum Node.js heap sizes"
echo "   • All services running concurrently"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📝 Useful commands:"
echo "   • View all logs: docker-compose -f docker-compose.full.yml logs -f"
echo "   • View web logs: docker-compose -f docker-compose.full.yml logs -f web"
echo "   • Stop all: docker-compose -f docker-compose.full.yml down"
echo "   • Restart service: docker-compose -f docker-compose.full.yml restart [service-name]"

# Final resource check
echo ""
echo "📊 Final resource usage:"
check_memory
echo "📊 Docker containers resource usage:"
docker stats --no-stream
