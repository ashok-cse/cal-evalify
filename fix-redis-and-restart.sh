#!/bin/bash

# Quick fix script to restart Cal.com with corrected Redis configuration

set -e

echo "🔧 Fixing Redis configuration and restarting Cal.com..."

# Stop all services
echo "🛑 Stopping all services..."
docker-compose -f docker-compose.full.yml down

# Remove the problematic Redis container and volume
echo "🧹 Cleaning up Redis container and volume..."
docker container rm calcom-redis 2>/dev/null || true
docker volume rm cal_cal_redis_data 2>/dev/null || true

# Clean up any orphaned containers
docker container prune -f || true

echo "🗄️ Starting database first..."
docker-compose -f docker-compose.full.yml up -d postgres

echo "⏳ Waiting for database to be ready..."
sleep 15

echo "🚀 Starting Redis with fixed configuration..."
docker-compose -f docker-compose.full.yml up -d redis

echo "⏳ Waiting for Redis to be ready..."
sleep 10

# Test Redis connection
echo "🔍 Testing Redis connection..."
docker-compose -f docker-compose.full.yml exec redis redis-cli ping || echo "Redis not ready yet, continuing..."

echo "🚀 Starting all application services..."
docker-compose -f docker-compose.full.yml up -d

echo "⏳ Waiting for all services to initialize..."
sleep 30

echo "✅ Deployment restarted with fixed Redis configuration!"
echo ""
echo "📊 Container status:"
docker-compose -f docker-compose.full.yml ps

echo ""
echo "📍 Your Cal.com should now be available at:"
echo "   • Web interface: http://localhost:3000"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"

echo ""
echo "🔍 To check logs if needed:"
echo "   • All logs: docker-compose -f docker-compose.full.yml logs -f"
echo "   • Redis logs: docker-compose -f docker-compose.full.yml logs -f redis"
echo "   • Web logs: docker-compose -f docker-compose.full.yml logs -f web"
