#!/bin/bash

# Cal.com Simple Docker Setup Script
# This script sets up Cal.com APIs using a development-friendly approach

set -e

echo "🚀 Cal.com Simple Docker Setup"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed."
    exit 1
fi

# Determine docker compose command
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

print_success "Docker and Docker Compose are available"

# Create environment file if it doesn't exist
if [ ! -f ".env.docker.local" ]; then
    print_status "Creating environment configuration..."
    
    # Generate secrets
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Use existing VAPID keys or defaults
    VAPID_PUBLIC="BFn7dzmtNqpquCwJBJZG7jX6k4dQCn3n4NVR5Irvn5KHi4V1bTVIRFm8udHRoUBXFpOKItfEjmzs1AsikMnKHL4"
    VAPID_PRIVATE="VK4RM4Ubj5oBxfV-4xMYzuGAlVSUYQe3-Z-nwxuXL5M"
    
    cat > .env.docker.local << EOF
# Cal.com Simple Docker Environment Configuration
POSTGRES_PASSWORD=calcom123
REDIS_PASSWORD=redis123
NEXTAUTH_SECRET=$NEXTAUTH_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY
JWT_SECRET=$JWT_SECRET
NEXT_PUBLIC_VAPID_PUBLIC_KEY=$VAPID_PUBLIC
VAPID_PRIVATE_KEY=$VAPID_PRIVATE
WEBAPP_URL=http://localhost:3000
EMAIL_FROM=noreply@yourdomain.com
TEAM_IMPERSONATION=false
SCHEDULE_INTERVAL=15
CRON_API_KEY=cron-api-key-$(openssl rand -hex 8)
CRON_ENABLE_APP_SYNC=false
LICENSE_CONSENT=agree
LOG_LEVEL=info
NODE_ENV=development
EOF

    print_success "Environment configuration created"
else
    print_status "Using existing .env.docker.local configuration"
fi

# Stop any existing containers
print_status "Stopping any existing containers..."
$DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local down 2>/dev/null || true

# Start infrastructure services first
print_status "Starting database and Redis..."
$DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local up -d postgres redis

# Wait for database to be ready
print_status "Waiting for database to be ready..."
sleep 10

# Run database setup
print_status "Setting up database and seeding data..."
$DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local --profile setup run --rm db-seed

print_success "Database setup completed"

# Start API services
print_status "Starting API services..."
print_status "This may take a few minutes for initial setup..."

$DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local up -d calcom-api-v1 calcom-api-v2

# Wait for APIs to build and start
print_status "Waiting for APIs to build and start (this may take 2-3 minutes)..."
sleep 30

# Start the proxy
print_status "Starting API proxy..."
$DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local up -d calcom-api-proxy

# Wait a bit more for everything to settle
sleep 20

# Test services
print_status "Testing services..."

test_service() {
    local name=$1
    local url=$2
    local max_attempts=10
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            print_success "$name is healthy"
            return 0
        fi
        echo -n "."
        sleep 3
        attempt=$((attempt + 1))
    done
    
    print_warning "$name is not responding yet (may still be starting)"
    return 1
}

echo -n "Testing API v1"
test_service "API v1" "http://localhost:3003"
echo

echo -n "Testing API v2"
test_service "API v2" "http://localhost:3004/health"
echo

echo -n "Testing API Proxy"
test_service "API Proxy" "http://localhost:3002"
echo

print_success "Setup completed!"

echo
echo "🎉 Cal.com Simple Docker Setup Complete!"
echo "========================================"
echo
echo "Services are available at:"
echo "  • API v1 (Legacy):     http://localhost:3003"
echo "  • API v2 (Platform):   http://localhost:3004"
echo "  • API Proxy:           http://localhost:3002"
echo "  • PostgreSQL:          localhost:5432"
echo "  • Redis:               localhost:6379"
echo
echo "Test the APIs:"
echo "  curl http://localhost:3002                    # API v1 through proxy"
echo "  curl http://localhost:3003                    # API v1 direct"
echo "  curl http://localhost:3004/health             # API v2 health"
echo "  curl http://localhost:3002/v2/health          # API v2 through proxy"
echo
echo "View logs:"
echo "  $DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local logs -f"
echo
echo "Stop services:"
echo "  $DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local down"
echo
echo "Start Prisma Studio (optional):"
echo "  $DOCKER_COMPOSE -f docker-compose.simple-api.yml --env-file .env.docker.local --profile tools up -d prisma-studio"
echo "  Then visit: http://localhost:5555"
echo
print_success "All done! 🚀"
