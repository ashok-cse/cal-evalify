#!/bin/bash

# Optimized Docker build script for Cal.com
# This script helps prevent build failures due to memory/resource constraints

set -e

echo "🚀 Starting optimized Cal.com Docker build..."

# Set Docker build arguments for memory optimization
export DOCKER_BUILDKIT=1
export COMPOSE_DOCKER_CLI_BUILD=1

# Clean up any existing containers and images to free up space
echo "🧹 Cleaning up existing containers and images..."
docker-compose -f docker-compose.full.yml down --remove-orphans || true
docker system prune -f || true

# Build with increased memory limits and timeouts
echo "🏗️ Building services with optimized settings..."

# Build services one by one to avoid overwhelming the system
echo "📦 Building web service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=6g web

echo "📦 Building api-v1 service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=3g api-v1

echo "📦 Building api-v2 service..."
docker-compose -f docker-compose.full.yml build --no-cache --memory=3g api-v2

echo "📦 Building api-proxy service..."
docker-compose -f docker-compose.full.yml build --no-cache api-proxy

echo "✅ Build completed successfully!"
echo "🚀 Starting services..."

# Start the services
docker-compose -f docker-compose.full.yml up -d

echo "🎉 Cal.com is now running!"
echo "📍 Web interface: http://localhost:3000"
echo "📍 API v1: http://localhost:3003"
echo "📍 API v2: http://localhost:3004"
echo "📍 API Proxy: http://localhost:3002"

# Show running containers
echo "📊 Running containers:"
docker-compose -f docker-compose.full.yml ps
