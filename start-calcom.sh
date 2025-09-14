#!/bin/bash

# Quick start script for Cal.com with proper environment setup

set -e

echo "🚀 Starting Cal.com with proper environment configuration..."

# Setup environment variables
echo "🔧 Setting up environment variables..."
chmod +x setup-env.sh
./setup-env.sh

# Stop any existing services
echo "🛑 Stopping existing services..."
docker-compose -f docker-compose.full.yml down

# Start services
echo "🚀 Starting all services..."
docker-compose -f docker-compose.full.yml up -d

echo "⏳ Waiting for services to initialize..."
sleep 30

echo "📊 Checking service status..."
docker-compose -f docker-compose.full.yml ps

echo ""
echo "🎉 Cal.com startup complete!"
echo ""
echo "📍 Services available at:"
echo "   • Web interface: http://localhost:3001"
echo "   • API v1: http://localhost:3003"
echo "   • API v2: http://localhost:3004"
echo "   • API Proxy: http://localhost:3002"
echo ""
echo "📝 To view logs:"
echo "   • All services: docker-compose -f docker-compose.full.yml logs -f"
echo "   • Web only: docker-compose -f docker-compose.full.yml logs -f web"
echo "   • Database: docker-compose -f docker-compose.full.yml logs -f postgres"
echo ""
echo "🛑 To stop all services:"
echo "   docker-compose -f docker-compose.full.yml down"
echo ""
echo "✅ Environment variables are now properly configured!"
echo "🔑 All required secrets have been set with secure values"
