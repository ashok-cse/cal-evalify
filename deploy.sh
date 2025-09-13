#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "INFO")
            echo -e "${BLUE}ℹ${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}✓${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}⚠${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}✗${NC} $message"
            ;;
    esac
}

# Function to generate secure secrets
generate_secrets() {
    print_status "INFO" "Generating secure secrets..."
    
    # Generate NextAuth secret
    NEXTAUTH_SECRET=$(openssl rand -base64 32 2>/dev/null || dd if=/dev/urandom bs=32 count=1 2>/dev/null | base64)
    
    # Generate encryption key
    ENCRYPTION_KEY=$(openssl rand -hex 16 2>/dev/null || dd if=/dev/urandom bs=16 count=1 2>/dev/null | xxd -p -c 16)
    
    # Generate database password
    POSTGRES_PASSWORD=$(openssl rand -base64 16 2>/dev/null || dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | tr -d '=+/' | cut -c1-16)
    
    # Generate redis password
    REDIS_PASSWORD=$(openssl rand -base64 16 2>/dev/null || dd if=/dev/urandom bs=16 count=1 2>/dev/null | base64 | tr -d '=+/' | cut -c1-16)
    
    print_status "SUCCESS" "Secrets generated successfully"
}

# Function to create environment file
create_env_file() {
    print_status "INFO" "Creating environment file..."
    
    if [ -f ".env" ]; then
        print_status "WARN" ".env file already exists. Creating backup..."
        cp .env .env.backup.$(date +%Y%m%d_%H%M%S)
    fi
    
    cat > .env << EOF
# Database Configuration
POSTGRES_PASSWORD=$POSTGRES_PASSWORD

# Redis Configuration  
REDIS_PASSWORD=$REDIS_PASSWORD

# Application URL (Change this to your domain in production)
WEBAPP_URL=http://localhost:3000

# NextAuth Configuration (Auto-generated)
NEXTAUTH_SECRET=$NEXTAUTH_SECRET

# Encryption Key (Auto-generated)
ENCRYPTION_KEY=$ENCRYPTION_KEY

# Email Configuration (REQUIRED - Please configure)
EMAIL_FROM=noreply@yourdomain.com
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=465
EMAIL_SERVER_USER=your-gmail@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password

# Application Settings
TEAM_IMPERSONATION=false
SCHEDULE_INTERVAL=15

# Cron Configuration
CRON_API_KEY=cron-$(openssl rand -hex 8 2>/dev/null || dd if=/dev/urandom bs=8 count=1 2>/dev/null | xxd -p -c 8)
CRON_ENABLE_APP_SYNC=false

# License Consent
LICENSE_CONSENT=agree
EOF
    
    print_status "SUCCESS" "Environment file created at .env"
}

# Function to check prerequisites
check_prerequisites() {
    print_status "INFO" "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_status "ERROR" "Docker is not installed. Please install Docker first."
        exit 1
    fi
    
    # Check Docker Compose
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        print_status "ERROR" "Docker Compose is not installed. Please install Docker Compose first."
        exit 1
    fi
    
    print_status "SUCCESS" "Prerequisites check passed"
}

# Function to deploy application
deploy_application() {
    print_status "INFO" "Starting Cal.com deployment..."
    
    # Use simple compose file for better compatibility
    if [ "$1" = "--simple" ] || [ "$1" = "-s" ]; then
        COMPOSE_FILE="docker-compose.simple.yml"
        print_status "INFO" "Using simple deployment configuration"
    else
        COMPOSE_FILE="docker-compose.yml"
        print_status "INFO" "Using full deployment configuration"
    fi
    
    # Start services
    print_status "INFO" "Building and starting services..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE up -d --build
    
    # Wait for database to be ready
    print_status "INFO" "Waiting for database to be ready..."
    timeout 120 bash -c 'until docker exec calcom-postgres pg_isready -U calcom -d calcom; do sleep 2; done' || {
        print_status "ERROR" "Database failed to start within 120 seconds"
        $DOCKER_COMPOSE -f $COMPOSE_FILE logs postgres
        exit 1
    }
    
    print_status "SUCCESS" "Database is ready"
    
    # Run database migrations
    print_status "INFO" "Running database migrations..."
    $DOCKER_COMPOSE -f $COMPOSE_FILE exec calcom-web yarn prisma migrate deploy || {
        print_status "WARN" "Migration failed, trying alternative approach..."
        sleep 10
        $DOCKER_COMPOSE -f $COMPOSE_FILE exec calcom-web yarn workspace @calcom/prisma prisma migrate deploy || {
            print_status "ERROR" "Database migration failed"
            $DOCKER_COMPOSE -f $COMPOSE_FILE logs calcom-web
            exit 1
        }
    }
    
    print_status "SUCCESS" "Database migrations completed"
    
    # Wait for application to be ready
    print_status "INFO" "Waiting for application to be ready..."
    timeout 120 bash -c 'until curl -f -s http://localhost:3000/api/health > /dev/null 2>&1; do sleep 3; done' || {
        print_status "WARN" "Application health check failed, but it might still be starting..."
    }
    
    print_status "SUCCESS" "Cal.com deployment completed!"
}

# Function to show post-deployment instructions
show_instructions() {
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    print_status "SUCCESS" "Cal.com has been deployed successfully!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo
    print_status "INFO" "Access your Cal.com instance:"
    echo "  🌐 Web Application: http://localhost:3000"
    echo "  📊 Database Admin: http://localhost:5555 (run: $DOCKER_COMPOSE --profile tools up prisma-studio -d)"
    echo
    print_status "WARN" "IMPORTANT: Before using your instance:"
    echo "  1. Edit .env file and configure EMAIL_SERVER_USER and EMAIL_SERVER_PASSWORD"
    echo "  2. For production, change WEBAPP_URL to your domain"
    echo "  3. Create your first user account through the web interface"
    echo
    print_status "INFO" "Useful commands:"
    echo "  📋 View logs: $DOCKER_COMPOSE logs -f calcom-web"
    echo "  🔍 Health check: ./scripts/health-check.sh"
    echo "  🛑 Stop services: $DOCKER_COMPOSE down"
    echo "  🔄 Restart: $DOCKER_COMPOSE restart calcom-web"
    echo
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# Main function
main() {
    echo -e "${GREEN}"
    echo "╔═══════════════════════════════════════════════════════════╗"
    echo "║                    Cal.com Deployer                      ║"
    echo "║                   Docker Deployment                      ║"
    echo "╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Parse arguments
    if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
        echo "Usage: $0 [OPTIONS]"
        echo
        echo "Options:"
        echo "  -s, --simple    Use simple deployment (existing API Docker config)"
        echo "  -h, --help      Show this help message"
        echo
        echo "This script will:"
        echo "  1. Check prerequisites (Docker, Docker Compose)"
        echo "  2. Generate secure secrets automatically"
        echo "  3. Create environment configuration"
        echo "  4. Deploy Cal.com with PostgreSQL and Redis"
        echo "  5. Run database migrations"
        echo
        exit 0
    fi
    
    check_prerequisites
    generate_secrets
    create_env_file
    deploy_application "$1"
    show_instructions
}

# Run the deployment
main "$@"
