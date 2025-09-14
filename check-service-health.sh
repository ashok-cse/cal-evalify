#!/bin/bash

# Check Cal.com service health and troubleshoot connectivity issues

echo "🔍 Checking Cal.com service health and connectivity..."

echo ""
echo "📊 Container Status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "🌐 Testing internal connectivity..."

# Test if the web service is responding internally
echo "Testing web service health endpoint..."
docker-compose -f docker-compose.full.yml exec web curl -f http://localhost:3000/api/health || echo "Health endpoint not responding"

echo ""
echo "Testing web service root endpoint..."
docker-compose -f docker-compose.full.yml exec web curl -I http://localhost:3000 || echo "Root endpoint not responding"

echo ""
echo "🔍 Checking container networking..."
docker-compose -f docker-compose.full.yml exec web netstat -tlnp || echo "Netstat not available"

echo ""
echo "📋 Recent web service logs:"
docker-compose -f docker-compose.full.yml logs --tail=20 web

echo ""
echo "🔍 Port mapping verification:"
docker port calcom-web || echo "Container not found"

echo ""
echo "🌐 Testing external connectivity from host..."
echo "Testing localhost:3001..."
curl -I http://localhost:3001 || echo "External port 3001 not responding"

echo ""
echo "📝 Troubleshooting Summary:"
echo "   • Internal service: $(docker-compose -f docker-compose.full.yml exec web curl -f http://localhost:3000/api/health >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not responding')"
echo "   • Port mapping: $(docker port calcom-web >/dev/null 2>&1 && echo '✅ Configured' || echo '❌ Missing')"
echo "   • External access: $(curl -f http://localhost:3001 >/dev/null 2>&1 && echo '✅ Working' || echo '❌ Not accessible')"

echo ""
echo "🎯 Next Steps:"
echo "   1. If internal service is working but external isn't, check EasyPanel proxy config"
echo "   2. If port mapping is missing, restart the container"
echo "   3. If service isn't responding, check logs for errors"
