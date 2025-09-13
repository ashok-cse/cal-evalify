# Cal.com Docker Setup Guide - API v1 & v2

This guide provides comprehensive instructions for running Cal.com API v1 and API v2 in Docker containers locally.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Manual Setup](#manual-setup)
- [Service Architecture](#service-architecture)
- [Configuration](#configuration)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)
- [Production Considerations](#production-considerations)

## Overview

This Docker setup provides:
- **API v1 (Legacy)**: Port 3003 - Original Cal.com REST API
- **API v2 (Platform)**: Port 3004 - Modern NestJS-based Platform API  
- **API Proxy**: Port 3002 - Routes requests to both APIs
- **PostgreSQL**: Port 5432 - Database with seeded data
- **Redis**: Port 6379 - Caching and session storage
- **Prisma Studio**: Port 5555 - Database administration (optional)

## Prerequisites

- Docker Desktop or Docker Engine (20.10+)
- Docker Compose (2.0+)
- At least 4GB RAM available for containers
- Ports 3002, 3003, 3004, 5432, 6379, 5555 available

### Installation Check
```bash
docker --version          # Should show 20.10+
docker compose version    # Should show 2.0+
```

## Quick Start

### 1. Automated Setup (Recommended)

```bash
# Make setup script executable
chmod +x docker-setup.sh

# Run the setup script
./docker-setup.sh
```

The script will:
- Generate secure secrets automatically
- Create environment configuration
- Build and start all services
- Verify service health
- Provide testing instructions

### 2. Verify Services

After setup completes, test the APIs:

```bash
# Test API v1 through proxy
curl http://localhost:3002
# Expected: {"message":"Welcome to Cal.com API - docs are at https://developer.cal.com/api"}

# Test API v2 health
curl http://localhost:3002/v2/health
# Expected: OK

# Test API v2 directly
curl http://localhost:3004/health
# Expected: OK
```

## Manual Setup

If you prefer manual setup or need customization:

### 1. Environment Configuration

```bash
# Copy and customize environment file
cp .env.docker .env.docker.local

# Generate secrets
openssl rand -base64 32  # For NEXTAUTH_SECRET
openssl rand -base64 32  # For ENCRYPTION_KEY  
openssl rand -base64 32  # For JWT_SECRET

# Generate VAPID keys
npx web-push generate-vapid-keys
```

Update `.env.docker.local` with your generated secrets.

### 2. Build and Start Services

```bash
# Build and start all services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local up --build -d

# Check service status
docker-compose -f docker-compose.api.yml --env-file .env.docker.local ps

# View logs
docker-compose -f docker-compose.api.yml --env-file .env.docker.local logs -f
```

### 3. Database Seeding

The database will be automatically seeded with test data on first startup.

## Service Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   API Proxy     │    │     API v1      │    │     API v2      │
│   Port: 3002    │────│   Port: 3003    │    │   Port: 3004    │
│                 │    │   (Legacy API)  │    │ (Platform API)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         └───────────────────────┼───────────────────────┘
                                 │
    ┌─────────────────┐    ┌─────────────────┐
    │   PostgreSQL    │    │      Redis      │
    │   Port: 5432    │    │   Port: 6379    │
    │   (Database)    │    │   (Cache)       │
    └─────────────────┘    └─────────────────┘
```

### Request Routing

- `http://localhost:3002/*` → API v1 (Legacy endpoints)
- `http://localhost:3002/v2/*` → API v2 (Platform endpoints)
- Direct access also available on ports 3003 and 3004

## Configuration

### Environment Variables

Key configuration options in `.env.docker.local`:

```env
# Database
POSTGRES_PASSWORD=calcom123

# Redis
REDIS_PASSWORD=redis123

# Security (Generate unique values)
NEXTAUTH_SECRET=your-generated-secret
ENCRYPTION_KEY=your-generated-key
JWT_SECRET=your-generated-jwt-secret

# Web Push Notifications
NEXT_PUBLIC_VAPID_PUBLIC_KEY=your-vapid-public-key
VAPID_PRIVATE_KEY=your-vapid-private-key

# Email (Optional)
EMAIL_SERVER_USER=your-email@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
```

### Service Configuration

Each service can be configured via environment variables:

- **API v1**: Traditional Next.js configuration
- **API v2**: NestJS with additional platform-specific settings
- **Proxy**: Routes and error handling
- **Database**: Connection pooling and performance settings
- **Redis**: Memory limits and persistence

## Testing

### API Endpoints

#### API v1 (Legacy)
```bash
# Welcome message
curl http://localhost:3003
curl http://localhost:3002

# API documentation
curl http://localhost:3003/docs

# Health check (if available)
curl http://localhost:3003/health
```

#### API v2 (Platform)
```bash
# Health check
curl http://localhost:3004/health
curl http://localhost:3002/v2/health

# API status
curl http://localhost:3004/api/v2/status

# Platform endpoints (require authentication)
curl http://localhost:3004/api/v2/bookings
```

### Database Access

#### Using Prisma Studio
```bash
# Start Prisma Studio (optional service)
docker-compose -f docker-compose.api.yml --env-file .env.docker.local --profile tools up prisma-studio -d

# Access at http://localhost:5555
```

#### Direct Database Access
```bash
# Connect to PostgreSQL
docker exec -it calcom-postgres psql -U calcom -d calcom

# List tables
\dt

# Check users
SELECT email FROM users LIMIT 5;
```

### Test Users

The database is seeded with test users:
- `admin@example.com` / `ADMINadmin2022!`
- `pro@example.com` / `pro`
- `free@example.com` / `free`
- `trial@example.com` / `trial`

## Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using ports
lsof -i :3002 -i :3003 -i :3004 -i :5432 -i :6379

# Stop conflicting services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local down
```

#### Service Health Issues
```bash
# Check service status
docker-compose -f docker-compose.api.yml --env-file .env.docker.local ps

# View service logs
docker-compose -f docker-compose.api.yml --env-file .env.docker.local logs [service-name]

# Restart specific service
docker-compose -f docker-compose.api.yml --env-file .env.docker.local restart [service-name]
```

#### Database Connection Issues
```bash
# Check database logs
docker-compose -f docker-compose.api.yml --env-file .env.docker.local logs postgres

# Verify database is accessible
docker exec calcom-postgres pg_isready -U calcom -d calcom
```

#### API Build Issues
```bash
# Rebuild services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local build --no-cache

# Clean up and restart
docker-compose -f docker-compose.api.yml --env-file .env.docker.local down -v
docker-compose -f docker-compose.api.yml --env-file .env.docker.local up --build -d
```

### Debug Mode

Enable debug logging:
```bash
# Update .env.docker.local
LOG_LEVEL=debug
NODE_ENV=development

# Restart services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local restart
```

### Performance Issues

If containers are slow:
```bash
# Check resource usage
docker stats

# Increase memory limits in docker-compose.api.yml
deploy:
  resources:
    limits:
      memory: 2G
    reservations:
      memory: 1G
```

## Production Considerations

### Security
1. **Generate unique secrets** for all environment variables
2. **Use Docker secrets** for sensitive data
3. **Enable SSL/TLS** with reverse proxy
4. **Restrict network access** to necessary ports only
5. **Regular security updates** for base images

### Performance
1. **Resource limits** for each container
2. **Database connection pooling**
3. **Redis memory optimization**
4. **Load balancing** for multiple API instances
5. **Monitoring and logging**

### Deployment
1. **Use docker-compose.override.yml** for environment-specific settings
2. **Container orchestration** (Kubernetes, Docker Swarm)
3. **Automated deployments** with CI/CD
4. **Backup strategies** for database and Redis
5. **Health monitoring** and alerting

## Management Commands

### Start/Stop Services
```bash
# Start all services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local up -d

# Stop all services
docker-compose -f docker-compose.api.yml --env-file .env.docker.local down

# Stop and remove volumes (cleans database)
docker-compose -f docker-compose.api.yml --env-file .env.docker.local down -v
```

### Logs and Monitoring
```bash
# View all logs
docker-compose -f docker-compose.api.yml --env-file .env.docker.local logs -f

# View specific service logs
docker-compose -f docker-compose.api.yml --env-file .env.docker.local logs -f calcom-api-v2

# Check service status
docker-compose -f docker-compose.api.yml --env-file .env.docker.local ps
```

### Updates and Maintenance
```bash
# Pull latest images
docker-compose -f docker-compose.api.yml --env-file .env.docker.local pull

# Rebuild and restart
docker-compose -f docker-compose.api.yml --env-file .env.docker.local up --build -d

# Clean up unused images
docker image prune -f
```

## Support

For issues not covered in this guide:
1. Check service logs for specific error messages
2. Verify all environment variables are correctly set
3. Ensure Docker has sufficient resources allocated
4. Review the main Cal.com documentation
5. Check GitHub issues for similar Docker-related problems

---

**Last Updated**: September 8, 2025  
**Docker Compose Version**: 3.8  
**Node.js Version**: 20.7.0  
**Services**: API v1, API v2, PostgreSQL, Redis, API Proxy
