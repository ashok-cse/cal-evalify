# Cal.com Local Development Setup Guide

This guide documents the steps taken to successfully run Cal.com locally from the downloaded source code.

## Prerequisites

- Node.js (v20.10.0 used)
- Yarn package manager
- Docker (for database services)
- Git

## Issues Encountered and Solutions

### 1. i18n.json Path Resolution Error

**Problem**: 
```
Error: Cannot find module '../../i18n.json'
Module not found: Can't resolve './ROOT/i18n.json'
```

**Root Cause**: The `packages/config/next-i18next.config.js` file was using a simple relative path that didn't work properly in the Next.js build environment.

**Solution**: Updated the file to use robust path resolution with fallback configuration:

```javascript
// packages/config/next-i18next.config.js
const path = require("path");
const fs = require("fs");

// Try multiple possible paths to find i18n.json
let i18n;
const possiblePaths = [
  path.resolve(__dirname, "../../i18n.json"),
  path.resolve(process.cwd(), "i18n.json"),
  path.resolve(process.cwd(), "../../i18n.json"),
  path.join(__dirname, "..", "..", "i18n.json")
];

for (const i18nPath of possiblePaths) {
  try {
    if (fs.existsSync(i18nPath)) {
      i18n = JSON.parse(fs.readFileSync(i18nPath, 'utf8'));
      break;
    }
  } catch (error) {
    // Continue to next path
  }
}

// Fallback configuration if file is not found
if (!i18n) {
  i18n = {
    locale: {
      source: "en",
      targets: [
        "ar", "az", "bg", "bn", "ca", "cs", "da", "de", "el", "es", "es-419", 
        "eu", "et", "fi", "fr", "he", "hu", "it", "ja", "km", "ko", "nl", 
        "no", "pl", "pt-BR", "pt", "ro", "ru", "sk-SK", "sr", "sv", "tr", 
        "uk", "vi", "zh-CN", "zh-TW"
      ]
    }
  };
}
```

### 2. Missing Environment Variables

**Problem**: 
```
Error: Please set NEXTAUTH_SECRET
Error: Please set CALENDSO_ENCRYPTION_KEY
```

**Solution**: Set required environment variables for the application to run.

### 3. Database Configuration Issues

**Problem**: The application was configured for PostgreSQL but no database was running.

**Solution**: Set up PostgreSQL and Redis using Docker Compose and ran database migrations.

## Step-by-Step Setup Instructions

### 1. Install Dependencies

```bash
cd /path/to/cal.com-main
yarn install
```

This installs all required packages for the monorepo workspace.

### 2. Start Database Services

Using Docker Compose to start PostgreSQL and Redis:

```bash
docker compose -f docker-compose.simple.yml up -d postgres redis
```

This starts:
- PostgreSQL database on port 5432
- Redis for caching on port 6379

### 3. Set Environment Variables

The following environment variables are required:

```bash
export NEXTAUTH_SECRET="your-super-secret-nextauth-key-change-this-in-production"
export CALENDSO_ENCRYPTION_KEY="your-32-character-encryption-key12"
export NEXT_PUBLIC_WEBAPP_URL="http://localhost:3000"
export NEXTAUTH_URL="http://localhost:3000/api/auth"
export DATABASE_URL="postgresql://calcom:calcom123@localhost:5432/calcom"
export DATABASE_DIRECT_URL="postgresql://calcom:calcom123@localhost:5432/calcom"
export LICENSE_CONSENT="agree"
export CALCOM_TELEMETRY_DISABLED="1"
```

### 4. Run Database Migrations

```bash
yarn workspace @calcom/prisma db-migrate
```

This applies all necessary database schema migrations.

### 5. Start the Development Server

```bash
cd apps/web
yarn dev
```

Or with environment variables in one command:

```bash
cd apps/web && \
export NEXTAUTH_SECRET="your-super-secret-nextauth-key-change-this-in-production" && \
export CALENDSO_ENCRYPTION_KEY="your-32-character-encryption-key12" && \
export NEXT_PUBLIC_WEBAPP_URL="http://localhost:3000" && \
export NEXTAUTH_URL="http://localhost:3000/api/auth" && \
export DATABASE_URL="postgresql://calcom:calcom123@localhost:5432/calcom" && \
export DATABASE_DIRECT_URL="postgresql://calcom:calcom123@localhost:5432/calcom" && \
export LICENSE_CONSENT="agree" && \
export CALCOM_TELEMETRY_DISABLED="1" && \
yarn dev
```

## Verification

1. **Server Status**: The server should start and be accessible at `http://localhost:3000`
2. **Database Connection**: The application should successfully connect to PostgreSQL
3. **Setup Wizard**: The app should redirect to `http://localhost:3000/auth/setup?step=1` for initial setup

## Expected Warnings (Can be Ignored)

The following warnings are normal and don't affect functionality:

- Prisma client ESM export warnings
- Sentry package version mismatches
- Organization domain warnings for localhost
- PostCSS version mismatches

## Database Configuration Details

### Default Database Credentials (from docker-compose.simple.yml)
- **Database**: calcom
- **Username**: calcom
- **Password**: calcom123
- **Host**: localhost
- **Port**: 5432

### Redis Configuration
- **Host**: localhost
- **Port**: 6379
- **Password**: redis123

## File Structure

Key files modified/created during setup:

```
cal.com-main/
├── packages/config/next-i18next.config.js  # Fixed i18n path resolution
├── docker-compose.simple.yml               # Database services
├── i18n.json                              # Internationalization config
└── LOCAL_SETUP_GUIDE.md                   # This guide
```

## Troubleshooting

### If the server fails to start:
1. Check that all environment variables are set
2. Verify Docker containers are running: `docker ps`
3. Check database connectivity: `docker logs calcom-postgres`
4. Ensure ports 3000, 5432, and 6379 are not in use by other applications

### If database migrations fail:
1. Ensure PostgreSQL container is running and healthy
2. Check database credentials match the connection string
3. Verify the database user has proper permissions

### If i18n errors persist:
1. Verify the `i18n.json` file exists in the project root
2. Check that the modified `next-i18next.config.js` file is properly saved
3. Restart the development server

## Next Steps

After successful setup:
1. Open `http://localhost:3000` in your browser
2. Complete the initial setup wizard
3. Create your first admin user
4. Configure your calendar integrations

## Production Considerations

For production deployment:
1. Use strong, unique values for `NEXTAUTH_SECRET` and `CALENDSO_ENCRYPTION_KEY`
2. Set up proper SSL/TLS certificates
3. Use a managed PostgreSQL service
4. Configure proper email settings
5. Set up monitoring and logging
6. Review and configure all environment variables in `docker.env.example`

---

**Setup completed successfully!** ✅  
Cal.com is now running at: http://localhost:3000
