# EasyPanel Deployment Guide for Cal.com

This guide provides optimized deployment instructions for Cal.com on EasyPanel to prevent build failures and memory issues.

## 🚨 Memory Requirements

Cal.com is a large monorepo with 132+ packages. The build process requires significant memory:

- **Minimum RAM**: 8GB
- **Recommended RAM**: 12GB or more
- **Build-time memory**: Up to 6-8GB per service
- **Swap space**: 4GB+ recommended

## 🔧 EasyPanel Configuration

### 1. Server Resources
Ensure your EasyPanel server has adequate resources:
```
CPU: 4+ cores
RAM: 8GB minimum, 12GB+ recommended
Storage: 50GB+ SSD
Swap: 4GB+ configured
```

### 2. Docker Configuration
In EasyPanel, configure Docker with increased memory limits:
```json
{
  "default-ulimits": {
    "memlock": { "Hard": -1, "Soft": -1 }
  },
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "3"
  }
}
```

## 🚀 Deployment Methods

### Method 1: Sequential Build (Recommended for EasyPanel)

1. **Upload the optimized build script**:
   ```bash
   chmod +x easypanel-build.sh
   ./easypanel-build.sh
   ```

2. **Monitor the build process**:
   - Check EasyPanel logs for memory usage
   - Watch for OOM (Out of Memory) kills
   - Each service builds sequentially with cleanup

### Method 2: Manual Service Building

If the automated script fails, build services individually:

```bash
# 1. Clean up first
docker-compose -f docker-compose.full.yml down --remove-orphans
docker system prune -f

# 2. Build services one by one
docker-compose -f docker-compose.full.yml build api-proxy
docker system prune -f

docker-compose -f docker-compose.full.yml build api-v2
docker system prune -f

docker-compose -f docker-compose.full.yml build api-v1
docker system prune -f

docker-compose -f docker-compose.full.yml build web
docker system prune -f

# 3. Start services
docker-compose -f docker-compose.full.yml up -d
```

### Method 3: Pre-built Images (Fastest)

If building locally fails, consider using pre-built images:

1. Build on a more powerful machine
2. Push to Docker registry
3. Pull on EasyPanel

## 🛠️ Optimizations Applied

### Docker Optimizations
- ✅ Reduced Node.js memory allocation (4GB → 2-4GB per service)
- ✅ Disabled telemetry (Turbo, Next.js, Yarn)
- ✅ Optimized yarn configuration
- ✅ Split dependency installation from post-install scripts
- ✅ Added resource limits and reservations
- ✅ Improved build caching

### Yarn Optimizations
- ✅ Increased HTTP timeout to 30 minutes
- ✅ Disabled global cache and progress bars
- ✅ Filtered verbose log messages
- ✅ Used hardlinks for node_modules
- ✅ Skip-build mode for initial install

### Memory Management
- ✅ Separate post-install step with reduced memory
- ✅ Sequential builds instead of parallel
- ✅ Docker cleanup between builds
- ✅ Resource limits per service

## 🔍 Troubleshooting

### Build Killed During Yarn Install
**Symptoms**: Process killed at "Running post-install in 132 packages"
**Solutions**:
1. Increase server RAM to 12GB+
2. Add 4GB+ swap space
3. Use the sequential build script
4. Build services individually

### Out of Memory Errors
**Symptoms**: OOMKilled in Docker logs
**Solutions**:
1. Check available memory: `free -h`
2. Increase swap space
3. Reduce parallel builds
4. Use smaller memory limits per service

### Build Timeout
**Symptoms**: Build stops after 30+ minutes
**Solutions**:
1. Check network connectivity
2. Increase yarn HTTP timeout
3. Use local package cache
4. Build on faster network

### Container Fails to Start
**Symptoms**: Service exits immediately after build
**Solutions**:
1. Check environment variables in `.env`
2. Verify database connectivity
3. Check service logs: `docker-compose logs [service]`
4. Ensure all required secrets are set

## 📊 Monitoring Build Progress

### Memory Usage
```bash
# Monitor memory during build
watch -n 2 'free -h && docker stats --no-stream'
```

### Build Logs
```bash
# Follow build logs
docker-compose -f docker-compose.full.yml logs -f

# Check specific service
docker-compose -f docker-compose.full.yml logs -f web
```

### Service Health
```bash
# Check running services
docker-compose -f docker-compose.full.yml ps

# Check service health
docker-compose -f docker-compose.full.yml exec web curl http://localhost:3000/api/health
```

## 🎯 Success Indicators

✅ **Successful Build**: All services show "Successfully built" messages
✅ **Services Running**: All containers show "Up" status
✅ **Health Checks**: All health checks return 200 OK
✅ **Web Access**: http://localhost:3000 loads Cal.com interface
✅ **API Access**: APIs respond at their respective ports

## 🆘 Emergency Recovery

If deployment fails completely:

1. **Stop all services**:
   ```bash
   docker-compose -f docker-compose.full.yml down --volumes
   ```

2. **Clean everything**:
   ```bash
   docker system prune -a -f --volumes
   ```

3. **Restart with minimal setup**:
   ```bash
   # Start only database and one service
   docker-compose -f docker-compose.full.yml up -d postgres redis
   docker-compose -f docker-compose.full.yml up -d web
   ```

## 📞 Support

If you continue experiencing issues:
1. Check EasyPanel server resources
2. Verify Docker daemon configuration
3. Consider upgrading server specifications
4. Use external build server for images

---

**Note**: Cal.com is a resource-intensive application. The optimizations in this guide significantly reduce memory usage, but adequate server resources are still essential for successful deployment.
