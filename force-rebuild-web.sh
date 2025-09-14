#!/bin/bash

# Force rebuild of web service with environment variables baked into the image

set -e

echo "🔧 Force rebuilding Cal.com web service with baked-in environment variables..."

# Stop and remove the web service
echo "🛑 Stopping and removing web service..."
docker-compose -f docker-compose.full.yml stop web
docker-compose -f docker-compose.full.yml rm -f web

# Remove the web image to force complete rebuild
echo "🗑️ Removing web image to force rebuild..."
docker rmi cal_cal-web || echo "Image not found, continuing..."

# Build the web service with no cache
echo "🏗️ Building web service with no cache..."
docker-compose -f docker-compose.full.yml build --no-cache web

# Start the web service
echo "🚀 Starting web service..."
docker-compose -f docker-compose.full.yml up -d web

echo "⏳ Waiting for web service to initialize..."
sleep 45

echo "📊 Checking service status..."
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📋 Environment variables now baked into Docker image:"
echo "   • NEXTAUTH_SECRET: ✅ Hardcoded in Dockerfile"
echo "   • CALENDSO_ENCRYPTION_KEY: ✅ Hardcoded in Dockerfile"
echo "   • ENCRYPTION_KEY: ✅ Hardcoded in Dockerfile"
echo "   • JWT_SECRET: ✅ Hardcoded in Dockerfile"
echo "   • CRON_API_KEY: ✅ Hardcoded in Dockerfile"
echo ""
echo "🌐 Cal.com should now be accessible at:"
echo "   • Web interface: http://localhost:3001"
echo "   • EasyPanel URL: https://cal.yapping.me"
echo ""
echo "📝 To check logs:"
echo "   docker-compose -f docker-compose.full.yml logs -f web"
echo ""
echo "✅ Environment variables are now permanently set in the Docker image!"
echo "🎯 This should resolve all NEXTAUTH_SECRET and CALENDSO_ENCRYPTION_KEY errors"
