#!/bin/bash

# EasyPanel-optimized build script for Cal.com
# This script builds services sequentially to avoid memory exhaustion

set -e

echo "🚀 EasyPanel optimized Cal.com build starting..."

# Set environment variables for reduced memory usage
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_STEP_LOG_MAX_SIZE=50000000
export BUILDKIT_STEP_LOG_MAX_SPEED=100000

# Function to clean up Docker resources
cleanup_docker() {
    echo "🧹 Cleaning up Docker resources..."
    docker builder prune -f || true
    docker system prune -f || true
    # Wait a moment for cleanup to complete
    sleep 5
}

# Function to monitor memory usage
check_memory() {
    if command -v free >/dev/null 2>&1; then
        echo "📊 Current memory usage:"
        free -h
    fi
}

echo "🛑 Stopping any existing services..."
docker-compose -f docker-compose.full.yml down --remove-orphans || true

echo "🧹 Initial cleanup..."
cleanup_docker
check_memory

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file with generated secrets..."
    cat > .env << 'EOF'
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=
NEXTAUTH_SECRET=cal-docker-secret-generated
NEXTAUTH_URL=http://localhost:3000
ENCRYPTION_KEY=cal-docker-encryption-key-generated
JWT_SECRET=cal-docker-jwt-secret-generated
CALENDSO_ENCRYPTION_KEY=cal-docker-calendso-key-generated
CRON_API_KEY=cal-docker-cron-key-generated
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3000
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
NEXT_PUBLIC_API_V2_ROOT_URL=http://localhost:3004
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
TURBO_TELEMETRY_DISABLED=1
NEXT_TELEMETRY_DISABLED=1
DO_NOT_TRACK=1
EOF
    echo "✅ Created .env file"
fi

# Build services one by one with cleanup between each
echo "🏗️ Building API Proxy (lightweight service first)..."
docker-compose -f docker-compose.full.yml build api-proxy
cleanup_docker
check_memory

echo "🏗️ Building API v2..."
docker-compose -f docker-compose.full.yml build api-v2
cleanup_docker
check_memory

echo "🏗️ Building API v1..."
docker-compose -f docker-compose.full.yml build api-v1
cleanup_docker
check_memory

echo "🏗️ Building Web (largest service last)..."
docker-compose -f docker-compose.full.yml build web
cleanup_docker
check_memory

echo "✅ All services built successfully!"

# Start the database and Redis first
echo "🗄️ Starting database and Redis..."
docker-compose -f docker-compose.full.yml up -d postgres redis

# Wait for database to be ready
echo "⏳ Waiting for database to be ready..."
sleep 30

# Start API services
echo "🚀 Starting API services..."
docker-compose -f docker-compose.full.yml up -d api-v1 api-v2 api-proxy

# Wait a moment before starting web
echo "⏳ Waiting for APIs to initialize..."
sleep 15

# Start web service
echo "🌐 Starting web service..."
docker-compose -f docker-compose.full.yml up -d web

echo "🎉 Cal.com deployment completed!"
echo ""
echo "📍 Services available at:"
echo "   • Web interface: http://localhost:3000"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📝 To view logs: docker-compose -f docker-compose.full.yml logs -f [service-name]"
echo "🛑 To stop: docker-compose -f docker-compose.full.yml down"
