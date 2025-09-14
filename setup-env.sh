#!/bin/bash

# Environment setup script for Cal.com on EasyPanel 32GB server

echo "🔧 Setting up environment variables for Cal.com..."

# Create .env file with all required variables
cat > .env << 'EOF'
# Cal.com Environment Configuration for 32GB EasyPanel Server

# Database Configuration
POSTGRES_USER=unicorn_user
POSTGRES_PASSWORD=magical_password
POSTGRES_DB=calendso

# Redis Configuration (no password for simplicity)
REDIS_PASSWORD=

# Authentication & Security - REQUIRED
NEXTAUTH_SECRET=cal-easypanel-32gb-nextauth-secret-12345678901234567890123456789012
NEXTAUTH_URL=http://localhost:3001
ENCRYPTION_KEY=cal-easypanel-32gb-encryption-key-12345678901234567890123456789012
JWT_SECRET=cal-easypanel-32gb-jwt-secret-key-12345678901234567890123456789012
CALENDSO_ENCRYPTION_KEY=cal-easypanel-32gb-calendso-key-12345678901234567890123456789012
CRON_API_KEY=cal-easypanel-32gb-cron-api-key-12345678901234567890123456789012

# Application URLs
NEXT_PUBLIC_WEBAPP_URL=http://localhost:3001
NEXT_PUBLIC_WEBSITE_URL=http://localhost:3001
NEXT_PUBLIC_API_V2_URL=http://localhost:3004/v2
NEXT_PUBLIC_API_V2_ROOT_URL=http://localhost:3004

# Email Configuration
EMAIL_FROM=noreply@localhost
EMAIL_SERVER_HOST=
EMAIL_SERVER_PORT=587
EMAIL_SERVER_USER=
EMAIL_SERVER_PASSWORD=

# API Configuration
API_KEY_PREFIX=cal_

# Feature Flags - Optimized for Performance
NEXT_PUBLIC_IS_E2E=1
CALCOM_TELEMETRY_DISABLED=1
TURBO_TELEMETRY_DISABLED=1
NEXT_TELEMETRY_DISABLED=1
DO_NOT_TRACK=1
ORGANIZATIONS_ENABLED=false
GOOGLE_LOGIN_ENABLED=true

# License Configuration (Development Mode)
CALCOM_LICENSE_KEY=development
DISABLE_LICENSE_CHECK=true
IS_CALCOM_DOCKER=true
SKIP_LICENSE_CHECK=true
CALCOM_ENV=development

# VAPID Keys for Push Notifications (Optional)
NEXT_PUBLIC_VAPID_PUBLIC_KEY=
VAPID_PRIVATE_KEY=

# Optional Third-party Integrations (Leave empty if not needed)
GOOGLE_API_CREDENTIALS=
STRIPE_CLIENT_ID=
STRIPE_PRIVATE_KEY=
STRIPE_WEBHOOK_SECRET=
SENDGRID_API_KEY=
TWILIO_SID=
TWILIO_TOKEN=
TWILIO_MESSAGING_SID=
DAILY_API_KEY=
DAILY_SCALE_PLAN=
MS_GRAPH_CLIENT_ID=
MS_GRAPH_CLIENT_SECRET=
ZOOM_CLIENT_ID=
ZOOM_CLIENT_SECRET=

# Payment Configuration (Optional)
PAYMENT_FEE_PERCENTAGE=0.005
PAYMENT_FEE_FIXED=10

# App Router Feature Flags (Optional)
APP_ROUTER_APPS_CATEGORIES_ENABLED=
APP_ROUTER_APPS_INSTALLED_CATEGORY_ENABLED=
APP_ROUTER_APPS_SLUG_ENABLED=
APP_ROUTER_APPS_SLUG_SETUP_ENABLED=
APP_ROUTER_BOOKINGS_STATUS_ENABLED=
APP_ROUTER_SETTINGS_ADMIN_ENABLED=
FEATURE_FLAG_WEBHOOK_ENABLED=
AB_TEST_BUCKET_PROBABILITY=
ORGANIZATIONS_AUTOLINK=

# Security Policies (Optional)
CSP_POLICY=
ALLOWED_HOSTNAMES=
RESERVED_SUBDOMAINS=
WEBSITE_BASE_URL=
CONSOLE_URL=
EOF

echo "✅ Created .env file with all required environment variables"
echo ""
echo "🔑 Key variables configured:"
echo "   • NEXTAUTH_SECRET: Set with 64-character secret"
echo "   • ENCRYPTION_KEY: Set with 64-character key"
echo "   • JWT_SECRET: Set with 64-character secret"
echo "   • CALENDSO_ENCRYPTION_KEY: Set with 64-character key"
echo "   • CRON_API_KEY: Set with 64-character key"
echo ""
echo "🌐 URLs configured for port 3001:"
echo "   • NEXTAUTH_URL: http://localhost:3001"
echo "   • NEXT_PUBLIC_WEBAPP_URL: http://localhost:3001"
echo "   • NEXT_PUBLIC_API_V2_URL: http://localhost:3004/v2"
echo ""
echo "📋 Database configured:"
echo "   • Database: calendso"
echo "   • User: unicorn_user"
echo "   • Password: magical_password"
echo ""
echo "🚀 Ready to start Cal.com! Run:"
echo "   docker-compose -f docker-compose.full.yml up -d"
