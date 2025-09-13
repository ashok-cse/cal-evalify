#!/bin/bash

# Cal.com Docker Setup Script
# This script sets up Cal.com with both API v1 and API v2 in Docker

set -e

echo "🚀 Cal.com Docker Setup Script"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is available
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Determine which docker compose command to use
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE="docker-compose"
else
    DOCKER_COMPOSE="docker compose"
fi

print_success "Docker and Docker Compose are available"

# Generate secrets if .env.docker.local doesn't exist
if [ ! -f ".env.docker.local" ]; then
    print_status "Creating environment configuration..."
    
    # Generate secrets
    NEXTAUTH_SECRET=$(openssl rand -base64 32)
    ENCRYPTION_KEY=$(openssl rand -base64 32)
    JWT_SECRET=$(openssl rand -base64 32)
    
    # Generate VAPID keys
    print_status "Generating VAPID keys for web push notifications..."
    VAPID_OUTPUT=$(npx web-push generate-vapid-keys 2>/dev/null || echo "")
    
    if [ -n "$VAPID_OUTPUT" ]; then
        VAPID_PUBLIC=$(echo "$VAPID_OUTPUT" | grep "Public Key:" | cut -d' ' -f3)
        VAPID_PRIVATE=$(echo "$VAPID_OUTPUT" | grep "Private Key:" | cut -d' ' -f3)
    else
        print_warning "Could not generate VAPID keys. Using defaults."
        VAPID_PUBLIC="BFn7dzmtNqpquCwJBJZG7jX6k4dQCn3n4NVR5Irvn5KHi4V1bTVIRFm8udHRoUBXFpOKItfEjmzs1AsikMnKHL4"
        VAPID_PRIVATE="VK4RM4Ubj5oBxfV-4xMYzuGAlVSUYQe3-Z-nwxuXL5M"
    fi
    
    # Create .env.docker.local with generated secrets
    cat > .env.docker.local << EOF
# Cal.com Docker Environment Configuration
# Generated on $(date)

# Database Configuration
POSTGRES_PASSWORD=calcom123

# Redis Configuration  
REDIS_PASSWORD=redis123

# Application Secrets (Generated)
NEXTAUTH_SECRET=$NEXTAUTH_SECRET
ENCRYPTION_KEY=$ENCRYPTION_KEY
JWT_SECRET=$JWT_SECRET

# VAPID Keys for Web Push Notifications
NEXT_PUBLIC_VAPID_PUBLIC_KEY=$VAPID_PUBLIC
VAPID_PRIVATE_KEY=$VAPID_PRIVATE

# Application URLs
WEBAPP_URL=http://localhost:3000

# Email Configuration (Optional - Configure for production)
EMAIL_FROM=noreply@yourdomain.com
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=465
# EMAIL_SERVER_USER=your-gmail@gmail.com
# EMAIL_SERVER_PASSWORD=your-app-password

# Application Settings
TEAM_IMPERSONATION=false
SCHEDULE_INTERVAL=15

# Cron Configuration
CRON_API_KEY=cron-api-key-$(openssl rand -hex 8)
CRON_ENABLE_APP_SYNC=false

# License Consent
LICENSE_CONSENT=agree

# Development/Debug Settings
LOG_LEVEL=info
NODE_ENV=production
EOF

    print_success "Environment configuration created at .env.docker.local"
else
    print_status "Using existing .env.docker.local configuration"
fi

# Function to check if a command succeeded
check_command() {
    if [ $? -eq 0 ]; then
        print_success "$1"
    else
        print_error "$2"
        exit 1
    fi
}

# Stop any existing containers
print_status "Stopping any existing containers..."
$DOCKER_COMPOSE -f docker-compose.api.yml --env-file .env.docker.local down 2>/dev/null || true

# Build and start services
print_status "Building and starting Cal.com services..."
print_status "This may take several minutes on first run..."

$DOCKER_COMPOSE -f docker-compose.api.yml --env-file .env.docker.local up --build -d
check_command "Services started successfully" "Failed to start services"

# Wait for services to be healthy
print_status "Waiting for services to become healthy..."
sleep 10

# Check service health
print_status "Checking service health..."

# Function to check if a service is healthy
check_service() {
    local service_name=$1
    local url=$2
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url" > /dev/null 2>&1; then
            print_success "$service_name is healthy"
            return 0
        fi
        
        echo -n "."
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "$service_name failed to become healthy"
    return 1
}

# Check all services
echo -n "Checking PostgreSQL"
check_service "PostgreSQL" "http://localhost:5432" || true
echo

echo -n "Checking Redis"
check_service "Redis" "http://localhost:6379" || true
echo

echo -n "Checking API v1"
check_service "API v1" "http://localhost:3003"
echo

echo -n "Checking API v2"  
check_service "API v2" "http://localhost:3004/health"
echo

echo -n "Checking API Proxy"
check_service "API Proxy" "http://localhost:3002"
echo

print_success "All services are running!"

echo
echo "🎉 Cal.com Docker Setup Complete!"
echo "=================================="
echo
echo "Services are now available at:"
echo "  • API v1 (Legacy):     http://localhost:3003"
echo "  • API v2 (Platform):   http://localhost:3004"
echo "  • API Proxy:           http://localhost:3002"
echo "  • PostgreSQL:          localhost:5432"
echo "  • Redis:               localhost:6379"
echo
echo "API Proxy routes:"
echo "  • http://localhost:3002/*     → API v1"
echo "  • http://localhost:3002/v2/*  → API v2"
echo
echo "Test the APIs:"
echo "  curl http://localhost:3002                    # API v1 welcome"
echo "  curl http://localhost:3002/v2/health          # API v2 health"
echo "  curl http://localhost:3004/health             # API v2 direct"
echo
echo "To view logs: $DOCKER_COMPOSE -f docker-compose.api.yml --env-file .env.docker.local logs -f"
echo "To stop:      $DOCKER_COMPOSE -f docker-compose.api.yml --env-file .env.docker.local down"
echo
print_success "Setup complete! 🚀"
