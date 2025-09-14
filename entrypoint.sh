#!/bin/bash

# Entrypoint script to ensure required environment variables are set

# Set default values for required environment variables if not already set
export NEXTAUTH_SECRET="${NEXTAUTH_SECRET:-cal-easypanel-32gb-nextauth-secret-12345678901234567890123456789012}"
export CALENDSO_ENCRYPTION_KEY="${CALENDSO_ENCRYPTION_KEY:-cal-easypanel-32gb-calendso-key-12345678901234567890123456789012}"
export ENCRYPTION_KEY="${ENCRYPTION_KEY:-cal-easypanel-32gb-encryption-key-12345678901234567890123456789012}"
export JWT_SECRET="${JWT_SECRET:-cal-easypanel-32gb-jwt-secret-key-12345678901234567890123456789012}"
export CRON_API_KEY="${CRON_API_KEY:-cal-easypanel-32gb-cron-api-key-12345678901234567890123456789012}"
export NEXTAUTH_URL="${NEXTAUTH_URL:-http://localhost:3001}"
export NEXT_PUBLIC_WEBAPP_URL="${NEXT_PUBLIC_WEBAPP_URL:-http://localhost:3001}"
export NEXT_PUBLIC_WEBSITE_URL="${NEXT_PUBLIC_WEBSITE_URL:-http://localhost:3001}"
export DATABASE_URL="${DATABASE_URL:-postgresql://unicorn_user:magical_password@postgres:5432/calendso}"
export REDIS_URL="${REDIS_URL:-redis://redis:6379}"
export EMAIL_FROM="${EMAIL_FROM:-noreply@localhost}"
export CALCOM_TELEMETRY_DISABLED="${CALCOM_TELEMETRY_DISABLED:-1}"
export TURBO_TELEMETRY_DISABLED="${TURBO_TELEMETRY_DISABLED:-1}"
export NEXT_TELEMETRY_DISABLED="${NEXT_TELEMETRY_DISABLED:-1}"
export DO_NOT_TRACK="${DO_NOT_TRACK:-1}"
export ORGANIZATIONS_ENABLED="${ORGANIZATIONS_ENABLED:-false}"
export GOOGLE_LOGIN_ENABLED="${GOOGLE_LOGIN_ENABLED:-true}"
export CALCOM_LICENSE_KEY="${CALCOM_LICENSE_KEY:-development}"
export DISABLE_LICENSE_CHECK="${DISABLE_LICENSE_CHECK:-true}"
export IS_CALCOM_DOCKER="${IS_CALCOM_DOCKER:-true}"
export SKIP_LICENSE_CHECK="${SKIP_LICENSE_CHECK:-true}"

echo "🔑 Environment variables configured:"
echo "   • NEXTAUTH_SECRET: ${NEXTAUTH_SECRET:0:20}..."
echo "   • CALENDSO_ENCRYPTION_KEY: ${CALENDSO_ENCRYPTION_KEY:0:20}..."
echo "   • DATABASE_URL: ${DATABASE_URL}"
echo "   • NEXTAUTH_URL: ${NEXTAUTH_URL}"

# Execute the original command
exec "$@"
