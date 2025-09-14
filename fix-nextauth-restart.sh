#!/bin/bash

# Fix NEXTAUTH_SECRET and restart Cal.com

set -e

echo "🔧 Fixing NEXTAUTH_SECRET and restarting Cal.com..."

# Stop the web service
echo "🛑 Stopping web service..."
docker-compose -f docker-compose.full.yml stop web

# Remove the web container to force recreation
echo "🗑️ Removing web container..."
docker-compose -f docker-compose.full.yml rm -f web

# Start the web service with new environment variables
echo "🚀 Starting web service with fixed environment variables..."
docker-compose -f docker-compose.full.yml up -d web

echo "⏳ Waiting for web service to initialize..."
sleep 30

echo "📊 Checking service status..."
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📋 Environment variables now configured with defaults:"
echo "   • NEXTAUTH_SECRET: ✅ Set with 64-character default"
echo "   • ENCRYPTION_KEY: ✅ Set with 64-character default"
echo "   • JWT_SECRET: ✅ Set with 64-character default"
echo "   • CALENDSO_ENCRYPTION_KEY: ✅ Set with 64-character default"
echo "   • CRON_API_KEY: ✅ Set with 64-character default"
echo ""
echo "🌐 Cal.com should now be accessible at:"
echo "   • Web interface: http://localhost:3001"
echo ""
echo "📝 To check logs:"
echo "   docker-compose -f docker-compose.full.yml logs -f web"
echo ""
echo "✅ NEXTAUTH_SECRET issue should now be resolved!"
