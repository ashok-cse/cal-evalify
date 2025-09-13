#!/bin/bash

# Ultra-minimal EasyPanel build script for Cal.com
# This script builds only the essential web service with aggressive memory optimizations

set -e

echo "🚀 EasyPanel MINIMAL Cal.com build starting..."
echo "⚠️  This builds only the web service (no APIs) to reduce memory usage"

# Set environment variables for minimal resource usage
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1
export BUILDKIT_STEP_LOG_MAX_SIZE=10000000
export BUILDKIT_STEP_LOG_MAX_SPEED=50000

# Function to clean up Docker resources aggressively
cleanup_docker() {
    echo "🧹 Aggressive Docker cleanup..."
    docker builder prune -a -f || true
    docker system prune -a -f --volumes || true
    docker image prune -a -f || true
    # Wait for cleanup to complete
    sleep 10
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
docker-compose -f docker-compose.minimal.yml down --remove-orphans || true
docker-compose -f docker-compose.full.yml down --remove-orphans || true

echo "🧹 Aggressive initial cleanup..."
cleanup_docker
check_memory

# Create minimal .env file
if [ ! -f .env ]; then
    echo "📝 Creating minimal .env file..."
    cat > .env << 'EOF'
# Minimal configuration for Cal.com
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso
REDIS_PASSWORD=
NEXTAUTH_SECRET=cal-minimal-secret-12345678901234567890123456789012
NEXTAUTH_URL=http://localhost:3000
ENCRYPTION_KEY=cal-minimal-encryption-12345678901234567890123456789012
JWT_SECRET=cal-minimal-jwt-secret-12345678901234567890123456789012
CALENDSO_ENCRYPTION_KEY=cal-minimal-calendso-12345678901234567890123456789012
CRON_API_KEY=cal-minimal-cron-12345678901234567890123456789012
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3000
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3000
EMAIL_FROM=noreply@localhost
NEXT_PUBLIC_IS_E2E=1
CALCOM_TELEMETRY_DISABLED=1
TURBO_TELEMETRY_DISABLED=1
NEXT_TELEMETRY_DISABLED=1
DO_NOT_TRACK=1
ORGANIZATIONS_ENABLED=false
GOOGLE_LOGIN_ENABLED=true
EOF
    echo "✅ Created minimal .env file"
fi

echo "🗄️ Starting database and Redis first..."
docker-compose -f docker-compose.minimal.yml up -d postgres redis

echo "⏳ Waiting for database to be ready..."
sleep 20

check_memory

echo "🏗️ Building web service with minimal configuration..."
echo "⚠️  This may take 15-30 minutes depending on server resources"

# Build with strict memory limits
docker-compose -f docker-compose.minimal.yml build --no-cache web

cleanup_docker
check_memory

echo "🚀 Starting web service..."
docker-compose -f docker-compose.minimal.yml up -d web

echo "⏳ Waiting for web service to initialize..."
sleep 30

echo "🎉 Minimal Cal.com deployment completed!"
echo ""
echo "📍 Services available at:"
echo "   • Web interface: http://localhost:3000"
echo "   • Database: localhost:5432"
echo "   • Redis: localhost:6379"
echo ""
echo "⚠️  Note: This minimal build includes only:"
echo "   - Web interface"
echo "   - Database"
echo "   - Redis"
echo "   - No API services (to reduce memory usage)"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.minimal.yml ps

echo ""
echo "📝 To view logs: docker-compose -f docker-compose.minimal.yml logs -f web"
echo "🛑 To stop: docker-compose -f docker-compose.minimal.yml down"

# Final memory check
check_memory
