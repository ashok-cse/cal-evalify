#!/bin/bash

# Test Cal.com endpoints to verify the service is working

echo "🧪 Testing Cal.com endpoints..."

echo ""
echo "1️⃣ Testing health endpoint (should return 200 OK):"
docker-compose -f docker-compose.full.yml exec web curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:3000/api/health

echo ""
echo "2️⃣ Testing root endpoint (should return HTML):"
docker-compose -f docker-compose.full.yml exec web curl -s -I http://localhost:3000 | head -5

echo ""
echo "3️⃣ Testing API status:"
docker-compose -f docker-compose.full.yml exec web curl -s http://localhost:3000/api/health | head -3

echo ""
echo "4️⃣ Testing from host machine (external access):"
echo "Port 3001 response:"
curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:3001 || echo "Connection failed"

echo ""
echo "5️⃣ Checking if Next.js is serving content:"
docker-compose -f docker-compose.full.yml exec web curl -s http://localhost:3000 | grep -i "cal.com\|calendar\|nextjs" | head -3

echo ""
echo "📊 Service Summary:"
WEB_INTERNAL=$(docker-compose -f docker-compose.full.yml exec web curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 2>/dev/null || echo "000")
HEALTH_INTERNAL=$(docker-compose -f docker-compose.full.yml exec web curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health 2>/dev/null || echo "000")
EXTERNAL=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001 2>/dev/null || echo "000")

echo "   • Internal web (port 3000): HTTP $WEB_INTERNAL $([ "$WEB_INTERNAL" = "200" ] && echo '✅' || echo '❌')"
echo "   • Internal health endpoint: HTTP $HEALTH_INTERNAL $([ "$HEALTH_INTERNAL" = "200" ] && echo '✅' || echo '❌')"
echo "   • External access (port 3001): HTTP $EXTERNAL $([ "$EXTERNAL" = "200" ] && echo '✅' || echo '❌')"

if [ "$WEB_INTERNAL" = "200" ] && [ "$EXTERNAL" != "200" ]; then
    echo ""
    echo "🔍 Diagnosis: Service is running internally but not accessible externally"
    echo "   This suggests an EasyPanel proxy configuration issue"
    echo ""
    echo "💡 EasyPanel Configuration Check:"
    echo "   1. Verify the service is set to port 3001 in EasyPanel"
    echo "   2. Check if health check endpoint is configured correctly"
    echo "   3. Ensure the domain (cal.yapping.me) points to the right service"
    echo "   4. Check EasyPanel logs for proxy errors"
elif [ "$WEB_INTERNAL" != "200" ]; then
    echo ""
    echo "🔍 Diagnosis: Service is not responding internally"
    echo "   Check the application logs for startup errors"
else
    echo ""
    echo "🎉 Service appears to be working correctly!"
fi
