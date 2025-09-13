#!/bin/bash

# Optimized Docker build script for Cal.com
# This script helps prevent build failures due to memory/resource constraints

set -e

echo "🚀 Starting optimized Cal.com Docker build..."

# Set Docker build arguments for memory optimization
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Clean up any existing containers and images to free up space
echo "🧹 Cleaning up existing containers and images..."
docker-compose -f docker-compose.full.yml down --remove-orphans || true
docker system prune -f || true

# Check if .env file exists, if not create one with basic settings
if [ ! -f .env ]; then
    echo "📝 Creating basic .env file..."
    cat > .env << 'EOF'
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=
NEXTAUTH_SECRET=cal-docker-secret-$(openssl rand -hex 32)
NEXTAUTH_URL=http://localhost:3000
ENCRYPTION_KEY=cal-docker-encryption-$(openssl rand -hex 32)
JWT_SECRET=cal-docker-jwt-$(openssl rand -hex 32)
CALENDSO_ENCRYPTION_KEY=cal-docker-calendso-$(openssl rand -hex 32)
CRON_API_KEY=cal-docker-cron-$(openssl rand -hex 32)
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3000
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
EMAIL_FROM=noreply@localhost
API_KEY_PREFIX=cal_
NEXT_PUBLIC_IS_E2E=1
CALCOM_TELEMETRY_DISABLED=1
ORGANIZATIONS_ENABLED=false
CALCOM_LICENSE_KEY=development
DISABLE_LICENSE_CHECK=true
IS_CALCOM_DOCKER=true
SKIP_LICENSE_CHECK=true
GOOGLE_LOGIN_ENABLED=true
EOF
    echo "✅ Created .env file with generated secrets"
fi

# Build with increased memory limits and timeouts
echo "🏗️ Building services with optimized settings..."

# Build services one by one to avoid overwhelming the system
echo "📦 Building web service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=6g web

echo "📦 Building api-v1 service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=3g api-v1

echo "📦 Building api-v2 service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=3g api-v2

echo "📦 Building api-proxy service..."
docker-compose -f docker-compose.full.yml build --no-cache api-proxy

echo "✅ Build completed successfully!"
echo "🚀 Starting services..."

# Start the services
docker-compose -f docker-compose.full.yml up -d

echo "🎉 Cal.com is now running!"
echo "📍 Web interface: http://localhost:3000"
echo "📍 API v1: http://localhost:3003"
echo "📍 API v2: http://localhost:3004"
echo "📍 API Proxy: http://localhost:3002"

# Show running containers
echo "📊 Running containers:"
docker-compose -f docker-compose.full.yml ps
