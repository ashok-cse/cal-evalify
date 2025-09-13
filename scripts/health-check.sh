#!/bin/bash

# Health check script for Cal.com Docker deployment
# This script checks if all services are running and healthy

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    local status=$1
    local message=$2
    case $status in
        "OK")
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

# Check if Docker Compose is available
check_docker_compose() {
    if command -v docker-compose &> /dev/null; then
        DOCKER_COMPOSE="docker-compose"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        DOCKER_COMPOSE="docker compose"
    else
        print_status "ERROR" "Docker Compose not found"
        exit 1
    fi
    print_status "OK" "Docker Compose available: $DOCKER_COMPOSE"
}

# Check if services are running
check_services() {
    echo -e "\n${YELLOW}Checking Docker services...${NC}"
    
    # Check each service
    services=("calcom-web" "calcom-postgres" "calcom-redis")
    
    for service in "${services[@]}"; do
        if docker ps --format "table {{.Names}}" | grep -q "$service"; then
            print_status "OK" "$service is running"
        else
            print_status "ERROR" "$service is not running"
            return 1
        fi
    done
}

# Check service health
check_health() {
    echo -e "\n${YELLOW}Checking service health...${NC}"
    
    # Check Cal.com web app
    if curl -f -s http://localhost:3000/api/health > /dev/null 2>&1; then
        print_status "OK" "Cal.com web application is healthy"
    else
        print_status "WARN" "Cal.com web application health check failed (might still be starting)"
    fi
    
    # Check PostgreSQL
    if docker exec calcom-postgres pg_isready -U calcom -d calcom > /dev/null 2>&1; then
        print_status "OK" "PostgreSQL database is healthy"
    else
        print_status "ERROR" "PostgreSQL database is not healthy"
    fi
    
    # Check Redis
    if docker exec calcom-redis redis-cli ping | grep -q "PONG"; then
        print_status "OK" "Redis is healthy"
    else
        print_status "ERROR" "Redis is not healthy"
    fi
}

# Check environment configuration
check_environment() {
    echo -e "\n${YELLOW}Checking environment configuration...${NC}"
    
    if [ -f ".env" ]; then
        print_status "OK" "Environment file found"
        
        # Check for required variables
        required_vars=("NEXTAUTH_SECRET" "ENCRYPTION_KEY" "EMAIL_SERVER_USER")
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env && ! grep -q "^${var}=your-" .env; then
                print_status "OK" "$var is configured"
            else
                print_status "WARN" "$var needs to be configured in .env"
            fi
        done
    else
        print_status "WARN" "No .env file found. Copy docker.env.example to .env"
    fi
}

# Check ports
check_ports() {
    echo -e "\n${YELLOW}Checking port availability...${NC}"
    
    ports=(3000 5432 6379)
    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_status "OK" "Port $port is in use"
        else
            print_status "WARN" "Port $port is not in use"
        fi
    done
}

# Main function
main() {
    echo -e "${GREEN}Cal.com Docker Health Check${NC}"
    echo "==============================="
    
    check_docker_compose
    check_services
    check_health
    check_environment
    check_ports
    
    echo -e "\n${GREEN}Health check completed!${NC}"
    echo "If you see any errors, check the deployment guide in DOCKER_DEPLOYMENT.md"
}

# Run the health check
main
