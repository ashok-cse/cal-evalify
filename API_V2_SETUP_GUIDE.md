# Cal.com API v2 Setup Guide

This document provides a comprehensive guide for setting up and running Cal.com API v2 in a development environment.

## Table of Contents
- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Common Issues and Solutions](#common-issues-and-solutions)
- [Step-by-Step Setup](#step-by-step-setup)
- [Testing Your Setup](#testing-your-setup)
- [Troubleshooting](#troubleshooting)
- [Available Endpoints](#available-endpoints)

## Overview

Cal.com uses a multi-API architecture:
- **API v1** (port 3003): Legacy REST API
- **API v2** (port 3004): Modern NestJS-based Platform API
- **API Proxy** (port 3002): Routes requests to both APIs
- **Web App** (port 3000): Main Cal.com application

## Prerequisites

- Node.js (Version: >=18.x)
- Yarn 3.4.1 (specified in package.json)
- Docker and Docker Compose
- PostgreSQL database
- Redis instance

## Common Issues and Solutions

### Issue 1: `npm ERR! Unsupported URL Type "workspace:": workspace:*`

**Problem**: Trying to use npm with a Yarn workspace project.

**Solution**: 
```bash
# Use Yarn instead of npm
yarn install
```

### Issue 2: Port 3003 Not Loading

**Problem**: API services not running due to missing environment configuration.

**Solution**: Set up environment files and start services properly.

### Issue 3: `Error: listen EADDRINUSE: address already in use :::3002`

**Problem**: Port conflicts between services.

**Solution**: Stop conflicting processes before starting new ones.

### Issue 4: `NOAUTH Authentication required` (Redis)

**Problem**: Redis requires authentication but API v2 config is missing credentials.

**Solution**: Configure Redis URL with authentication.

### Issue 5: `No key set vapidDetails.publicKey`

**Problem**: Missing VAPID keys for web push notifications.

**Solution**: Generate and configure VAPID keys.

## Step-by-Step Setup

### 1. Install Dependencies

```bash
# Ensure you're using Yarn (not npm)
yarn --version  # Should show 3.4.1

# Install all dependencies
yarn install
```

### 2. Set Up Environment Files

```bash
# Copy environment examples
cp .env.example .env
cp apps/api/v1/.env.example apps/api/v1/.env
cp apps/api/v2/.env.example apps/api/v2/.env
```

### 3. Generate Required Secrets

```bash
# Generate NEXTAUTH_SECRET
openssl rand -base64 32

# Generate CALENDSO_ENCRYPTION_KEY
openssl rand -base64 32

# Generate VAPID keys for web push
npx web-push generate-vapid-keys
```

### 4. Configure Main .env File

Update `/Users/ashokcse/Downloads/cal.com-main/.env`:

```env
NEXTAUTH_SECRET=your_generated_secret_here
CALENDSO_ENCRYPTION_KEY=your_generated_encryption_key_here
NEXT_PUBLIC_VAPID_PUBLIC_KEY=your_vapid_public_key_here
VAPID_PRIVATE_KEY=your_vapid_private_key_here
DATABASE_URL="postgresql://postgres:@localhost:5450/calendso"
```

### 5. Configure API v2 Environment

Update `apps/api/v2/.env`:

```env
NODE_ENV=development
API_PORT=3004
DATABASE_URL="postgresql://postgres:@localhost:5450/calendso"
DATABASE_READ_URL="postgresql://postgres:@localhost:5450/calendso"
DATABASE_WRITE_URL="postgresql://postgres:@localhost:5450/calendso"
JWT_SECRET=your_jwt_secret_here
REDIS_URL=redis://:redis123@localhost:6379
NEXTAUTH_SECRET=your_nextauth_secret_here
NEXT_PUBLIC_VAPID_PUBLIC_KEY=your_vapid_public_key_here
VAPID_PRIVATE_KEY=your_vapid_private_key_here
```

### 6. Start Database and Redis Services

```bash
# Start development environment with Docker services
yarn dx
```

This will start:
- PostgreSQL on port 5450
- Redis on port 6379 (with password: redis123)
- Seed the database with test data

### 7. Start API Services

**Option A: Start All Services Together**
```bash
yarn dev:api
```

**Option B: Start Services Individually**
```bash
# Terminal 1: Start API v1
yarn workspace @calcom/api dev

# Terminal 2: Start API v2 (no-docker mode)
yarn workspace @calcom/api-v2 dev:no-docker

# Terminal 3: Start API proxy
cd apps/api && node index.js
```

### 8. Verify Services Are Running

```bash
# Check ports
lsof -i :3002  # API Proxy
lsof -i :3003  # API v1
lsof -i :3004  # API v2
lsof -i :5450  # PostgreSQL
lsof -i :6379  # Redis
```

## Testing Your Setup

### API v1 (Legacy API)
```bash
# Direct access
curl http://localhost:3003
# Expected: {"message":"Welcome to Cal.com API - docs are at https://developer.cal.com/api"}

# Through proxy
curl http://localhost:3002
# Expected: Same welcome message
```

### API v2 (Platform API)
```bash
# Health check
curl http://localhost:3004/health
# Expected: OK

# Through proxy
curl http://localhost:3002/v2/health
# Expected: OK
```

### Database Test Users

The database is seeded with test users:
- `admin@example.com` / `ADMINadmin2022!`
- `pro@example.com` / `pro`
- `free@example.com` / `free`
- `trial@example.com` / `trial`

## Troubleshooting

### Service Won't Start

1. **Check logs**:
   ```bash
   # For API v1
   tail -f api-v1.log
   
   # For API v2
   tail -f api-v2-final-attempt.log
   ```

2. **Verify environment variables**:
   ```bash
   # Check if all required vars are set
   grep -E "NEXTAUTH_SECRET|DATABASE_URL|REDIS_URL" apps/api/v2/.env
   ```

3. **Check port conflicts**:
   ```bash
   # Kill conflicting processes
   pkill -f "nest start"
   pkill -f "node.*index.js"
   ```

### Redis Connection Issues

1. **Test Redis connection**:
   ```bash
   docker exec calcom-redis redis-cli -a redis123 ping
   # Expected: PONG
   ```

2. **Check Redis URL format**:
   ```env
   # Correct format with authentication
   REDIS_URL=redis://:redis123@localhost:6379
   ```

### Database Connection Issues

1. **Verify database is running**:
   ```bash
   lsof -i :5450
   ```

2. **Check database URL**:
   ```env
   DATABASE_URL="postgresql://postgres:@localhost:5450/calendso"
   ```

### API v2 Compilation Issues

1. **Clear build cache**:
   ```bash
   yarn clean
   yarn install
   ```

2. **Rebuild platform packages**:
   ```bash
   yarn workspace @calcom/api-v2 dev:build
   ```

## Available Endpoints

### API v1 (Port 3003)
- `GET /` - Welcome message
- `GET /docs` - API documentation
- `GET /api-keys` - API key management
- `GET /bookings` - Booking management
- And more... (see API v1 documentation)

### API v2 (Port 3004)
- `GET /health` - Health check
- `GET /api/v2/...` - Platform API endpoints
- Authentication required for most endpoints

### API Proxy (Port 3002)
- `GET /` - Routes to API v1
- `GET /v2/*` - Routes to API v2
- Handles load balancing and routing

## Development Tips

1. **Use the no-docker mode** for API v2 development:
   ```bash
   yarn workspace @calcom/api-v2 dev:no-docker
   ```

2. **Monitor logs** in separate terminals for debugging.

3. **Use the proxy** (port 3002) for frontend integration.

4. **Test with curl** before integrating with frontend.

## Production Considerations

- Use proper environment variables for production
- Set up SSL/TLS certificates
- Configure proper database connection pooling
- Set up monitoring and logging
- Use Docker containers for deployment

## Support

For issues not covered in this guide:
1. Check the main Cal.com documentation
2. Review the API v2 specific documentation in `apps/api/v2/README.md`
3. Check GitHub issues for similar problems
4. Ensure all environment variables are properly configured

---

**Last Updated**: September 8, 2025
**Cal.com Version**: Latest main branch
**Node.js Version**: 20.10.0
**Yarn Version**: 3.4.1
