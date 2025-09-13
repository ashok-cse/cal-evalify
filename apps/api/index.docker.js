const http = require("http");
const connect = require("connect");
const { createProxyMiddleware } = require("http-proxy-middleware");

// Get URLs from environment variables or use defaults
const API_V1_URL = process.env.API_V1_URL || "http://localhost:3003";
const API_V2_URL = process.env.API_V2_URL || "http://localhost:3004";

console.log(`Setting up API proxy:`);
console.log(`API v1 URL: ${API_V1_URL}`);
console.log(`API v2 URL: ${API_V2_URL}`);

const apiProxyV1 = createProxyMiddleware({
  target: API_V1_URL,
  changeOrigin: true,
  logLevel: 'info',
  onError: (err, req, res) => {
    console.error('Proxy error for API v1:', err.message);
    res.writeHead(500, {
      'Content-Type': 'application/json',
    });
    res.end(JSON.stringify({
      error: 'API v1 service unavailable',
      message: err.message
    }));
  }
});

const apiProxyV2 = createProxyMiddleware({
  target: API_V2_URL,
  changeOrigin: true,
  logLevel: 'info',
  onError: (err, req, res) => {
    console.error('Proxy error for API v2:', err.message);
    res.writeHead(500, {
      'Content-Type': 'application/json',
    });
    res.end(JSON.stringify({
      error: 'API v2 service unavailable',
      message: err.message
    }));
  }
});

const app = connect();

// Health check endpoint
app.use('/health', (req, res) => {
  res.writeHead(200, { 'Content-Type': 'application/json' });
  res.end(JSON.stringify({ status: 'OK', timestamp: new Date().toISOString() }));
});

// Route /v2 paths to API v2
app.use("/v2", apiProxyV2);

// Route everything else to API v1
app.use("/", apiProxyV1);

const PORT = process.env.PORT || 3002;

const server = http.createServer(app);

server.listen(PORT, () => {
  console.log(`API Proxy server running on port ${PORT}`);
  console.log(`Health check: http://localhost:${PORT}/health`);
  console.log(`API v1 routes: http://localhost:${PORT}/*`);
  console.log(`API v2 routes: http://localhost:${PORT}/v2/*`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});

process.on('SIGINT', () => {
  console.log('SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('Process terminated');
  });
});
