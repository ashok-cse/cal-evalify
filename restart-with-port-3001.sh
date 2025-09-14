#!/bin/bash

# Quick restart script to apply port change from 3000 to 3001

set -e

echo "🔄 Restarting Cal.com with port 3001 (avoiding EasyPanel port conflict)..."

# Stop all services
echo "🛑 Stopping all services..."
docker-compose -f docker-compose.full.yml down

# Wait a moment for cleanup
sleep 5

# Start services with new port configuration
echo "🚀 Starting services with port 3001..."
docker-compose -f docker-compose.full.yml up -d

echo "⏳ Waiting for services to initialize..."
sleep 30

echo "🎉 Cal.com is now running on port 3001!"
echo ""
echo "📍 Services now available at:"
echo "   • Web interface: http://localhost:3001 (changed from 3000)"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "✅ Port conflict with EasyPanel resolved!"
echo "🌐 Access your Cal.com at: http://localhost:3001"
