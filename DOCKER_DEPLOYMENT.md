# Cal.com Docker Deployment Guide

This guide will help you deploy Cal.com using Docker Compose with all necessary services including PostgreSQL database, Redis caching, and optional Nginx reverse proxy.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- At least 4GB RAM available
- Port 3000 available (or configure different ports)

### 1. Environment Setup

1. Copy the example environment file:
   ```bash
   cp docker.env.example .env
   ```

2. Edit `.env` and configure the required variables:
   ```bash
   # Required: Generate secure secrets
   NEXTAUTH_SECRET=$(openssl rand -base64 32)
   ENCRYPTION_KEY=$(openssl rand -hex 16)
   
   # Required: Configure email settings
   EMAIL_FROM=noreply@yourdomain.com
   EMAIL_SERVER_USER=your-gmail@gmail.com
   EMAIL_SERVER_PASSWORD=your-app-password
   
   # Optional: Change default passwords
   POSTGRES_PASSWORD=your-secure-postgres-password
   REDIS_PASSWORD=your-secure-redis-password
   ```

### 2. Deploy

1. Build and start all services:
   ```bash
   docker compose up -d
   ```

2. Wait for services to be healthy:
   ```bash
   docker compose logs -f calcom-web
   ```

3. Run database migrations:
   ```bash
   docker compose exec calcom-web yarn prisma migrate deploy
   ```

4. Create your first user (optional, using Prisma Studio):
   ```bash
   docker compose --profile tools up prisma-studio -d
   ```
   Then visit http://localhost:5555 to create a user record.

### 3. Access Your Application

- **Cal.com Web App**: http://localhost:3000
- **Prisma Studio** (if enabled): http://localhost:5555

## 📋 Services Overview

| Service | Description | Port | Health Check |
|---------|-------------|------|--------------|
| `calcom-web` | Main Cal.com application | 3000 | ✅ |
| `postgres` | PostgreSQL database | 5432 | ✅ |
| `redis` | Redis for caching | 6379 | ✅ |
| `prisma-studio` | Database admin (optional) | 5555 | - |
| `nginx` | Reverse proxy (optional) | 80, 443 | - |

## 🔧 Configuration Options

### Profiles

Use Docker Compose profiles to enable optional services:

```bash
# Enable Prisma Studio for database management
docker compose --profile tools up -d

# Enable Nginx reverse proxy
docker compose --profile proxy up -d

# Enable both
docker compose --profile tools --profile proxy up -d
```

### Environment Variables

#### Required Variables

| Variable | Description | Example |
|----------|-------------|---------|
| `NEXTAUTH_SECRET` | JWT signing secret | Generate with `openssl rand -base64 32` |
| `ENCRYPTION_KEY` | AES256 encryption key | Generate with `openssl rand -hex 16` |
| `EMAIL_SERVER_USER` | SMTP username | `your-email@gmail.com` |
| `EMAIL_SERVER_PASSWORD` | SMTP password | `your-app-password` |

#### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `WEBAPP_URL` | Application URL | `http://localhost:3000` |
| `POSTGRES_PASSWORD` | Database password | `calcom123` |
| `REDIS_PASSWORD` | Redis password | `redis123` |
| `TEAM_IMPERSONATION` | Enable team impersonation | `false` |
| `SCHEDULE_INTERVAL` | Schedule interval in minutes | `15` |

### Email Configuration

Cal.com requires email configuration for user registration and notifications. Configure one of:

#### Gmail SMTP
```env
EMAIL_SERVER_HOST=smtp.gmail.com
EMAIL_SERVER_PORT=465
EMAIL_SERVER_USER=your-gmail@gmail.com
EMAIL_SERVER_PASSWORD=your-app-password
```

#### SendGrid
```env
SENDGRID_API_KEY=your-sendgrid-api-key
SENDGRID_EMAIL=your-sender@yourdomain.com
```

## 🔒 Production Deployment

### Security Considerations

1. **Generate Secure Secrets**:
   ```bash
   # Generate NextAuth secret
   openssl rand -base64 32
   
   # Generate encryption key
   openssl rand -hex 16
   ```

2. **Use Docker Secrets** (recommended for production):
   ```yaml
   services:
     calcom-web:
       secrets:
         - nextauth_secret
         - encryption_key
   ```

3. **Configure SSL/TLS**:
   - Uncomment HTTPS server block in `nginx.conf`
   - Add SSL certificates to `./ssl/` directory
   - Enable nginx profile: `docker compose --profile proxy up -d`

### Domain Configuration

1. Update environment variables:
   ```env
   WEBAPP_URL=https://cal.yourdomain.com
   ```

2. Configure DNS to point to your server

3. Enable SSL with Let's Encrypt:
   ```bash
   # Add certbot service to docker-compose.yml or use external tool
   ```

### Performance Optimization

1. **Resource Limits**:
   ```yaml
   services:
     calcom-web:
       deploy:
         resources:
           limits:
             memory: 2G
             cpus: '1.0'
   ```

2. **Database Optimization**:
   ```yaml
   postgres:
     command: >
       postgres
       -c shared_preload_libraries=pg_stat_statements
       -c max_connections=200
       -c shared_buffers=256MB
   ```

3. **Redis Configuration**:
   ```yaml
   redis:
     command: >
       redis-server
       --maxmemory 256mb
       --maxmemory-policy allkeys-lru
   ```

## 🛠️ Management Commands

### Database Management

```bash
# Run migrations
docker compose exec calcom-web yarn prisma migrate deploy

# Reset database (⚠️ DANGER: This will delete all data)
docker compose exec calcom-web yarn prisma migrate reset

# Backup database
docker compose exec postgres pg_dump -U calcom calcom > backup.sql

# Restore database
docker compose exec -T postgres psql -U calcom calcom < backup.sql
```

### Application Management

```bash
# View logs
docker compose logs -f calcom-web

# Restart application
docker compose restart calcom-web

# Update application
docker compose pull
docker compose up -d --build

# Scale application (if using load balancer)
docker compose up -d --scale calcom-web=3
```

### Health Checks

```bash
# Check service health
docker compose ps

# Test application health
curl -f http://localhost:3000/api/health

# Check database connection
docker compose exec postgres psql -U calcom -d calcom -c "SELECT 1;"
```

## 🔍 Troubleshooting

### Common Issues

1. **Application won't start**:
   - Check logs: `docker compose logs calcom-web`
   - Verify environment variables are set
   - Ensure database is healthy: `docker compose ps postgres`

2. **Database connection errors**:
   - Wait for postgres health check to pass
   - Verify DATABASE_URL format
   - Check network connectivity: `docker compose exec calcom-web ping postgres`

3. **Email not working**:
   - Verify SMTP credentials
   - Check firewall rules for SMTP ports
   - Test with a simple email service first

4. **Build failures**:
   - Increase Docker memory limit
   - Clear build cache: `docker compose build --no-cache`
   - Check disk space

### Performance Issues

1. **Slow database queries**:
   - Enable Prisma Studio to analyze queries
   - Consider adding database indexes
   - Monitor with `docker stats`

2. **High memory usage**:
   - Reduce NODE_OPTIONS max memory
   - Scale horizontally instead of vertically
   - Monitor with `docker stats`

### Log Analysis

```bash
# View all logs
docker compose logs

# View specific service logs
docker compose logs calcom-web
docker compose logs postgres

# Follow logs in real-time
docker compose logs -f --tail 100 calcom-web

# Search logs
docker compose logs calcom-web 2>&1 | grep ERROR
```

## 📱 Integration with Supabase

Based on your requirements for Supabase integration:

1. **Update environment variables**:
   ```env
   # Replace PostgreSQL with Supabase
   DATABASE_URL=postgresql://postgres:[password]@[host]:5432/postgres
   DATABASE_DIRECT_URL=postgresql://postgres:[password]@[host]:5432/postgres
   ```

2. **Configure Edge Functions**:
   - Deploy your edge functions to Supabase
   - Update API endpoints in Cal.com configuration
   - Ensure proper CORS settings

3. **Authentication Integration**:
   - Configure Supabase Auth as an authentication provider
   - Update NextAuth configuration if needed

## 🆘 Support

If you encounter issues:

1. Check the [official Cal.com documentation](https://cal.com/docs)
2. Review Docker logs for error messages
3. Ensure all required environment variables are set
4. Verify your system meets the minimum requirements

## 📄 License

This deployment configuration is provided under the same license as Cal.com. Please review the main LICENSE file for details.
