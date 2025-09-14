#!/bin/bash

# Clean rebuild script for Cal.com with robust Dockerfile

set -e

echo "🧹 Clean rebuild of Cal.com starting..."

# Stop and remove all containers
echo "🛑 Stopping and removing all containers..."
docker-compose -f docker-compose.full.yml down --volumes --remove-orphans

# Clean up Docker build cache and images
echo "🧹 Cleaning Docker build cache and images..."
docker builder prune -a -f
docker system prune -a -f --volumes

# Wait for cleanup
sleep 5

echo "📊 Available disk space after cleanup:"
df -h / | tail -1

echo "📊 Available memory:"
free -h || echo "Memory info not available"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << 'EOF'
# Cal.com configuration for 32GB server
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=

# Authentication & Security
NEXTAUTH_SECRET=cal-robust-secret-$(openssl rand -hex 32)
NEXTAUTH_URL=http://localhost:3001
ENCRYPTION_KEY=cal-robust-encryption-$(openssl rand -hex 32)
JWT_SECRET=cal-robust-jwt-$(openssl rand -hex 32)
CALENDSO_ENCRYPTION_KEY=cal-robust-calendso-$(openssl rand -hex 32)
CRON_API_KEY=cal-robust-cron-$(openssl rand -hex 32)

# Application URLs
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3001
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3001
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
NEXT_PUBLIC_API_V2_ROOT_URL=http://localhost:3004
EMAIL_FROM=noreply@localhost
API_KEY_PREFIX=cal_

# Feature Flags
NEXT_PUBLIC_IS_E2E=1
CALCOM_TELEMETRY_DISABLED=1
TURBO_TELEMETRY_DISABLED=1
NEXT_TELEMETRY_DISABLED=1
DO_NOT_TRACK=1
ORGANIZATIONS_ENABLED=false
GOOGLE_LOGIN_ENABLED=true

# License
CALCOM_LICENSE_KEY=development
DISABLE_LICENSE_CHECK=true
IS_CALCOM_DOCKER=true
SKIP_LICENSE_CHECK=true
EOF
    echo "✅ Created .env file with generated secrets"
fi

# Start database and Redis first
echo "🗄️ Starting database and Redis..."
docker-compose -f docker-compose.full.yml up -d postgres redis

echo "⏳ Waiting for database and Redis to be ready..."
sleep 30

# Build and start all services
echo "🏗️ Building and starting all services with robust configuration..."
docker-compose -f docker-compose.full.yml up --build -d

echo "⏳ Waiting for all services to initialize..."
sleep 60

echo "🎉 Clean rebuild completed!"
echo ""
echo "📍 Cal.com is now available at:"
echo "   • Web interface: http://localhost:3001"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📝 To view logs: docker-compose -f docker-compose.full.yml logs -f"
echo "🛑 To stop: docker-compose -f docker-compose.full.yml down"
