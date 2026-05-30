# Cloudstore
An E-commerce microservice platform. 
## Services
- API Gateway (TypeScript/Fastify)
- Order Service (Go/gRPC)
- Product Catalog (Python/FastAPI)
## Tech Stack
AWS, Docker, Kubernetes, Terraform

## Architecture
Built with microservices running on AWS EKS.
Follows GitOps methodology with Argo CD.

## Getting Started
Run docker-compose up to start locally.


The DevOps Checklist — 7 Questions for Every Service
When a developer hands you a service, you need answers to these seven questions. If you can't find the answers by reading the code, you ask the developer.
QUESTION 1: How does it START?
QUESTION 2: How does it STOP?
QUESTION 3: How do I know it's HEALTHY?
QUESTION 4: How does it CONNECT to other services?
QUESTION 5: How is it CONFIGURED?
QUESTION 6: What does it LOG?
QUESTION 7: What can go WRONG?
Let me show you how to find each answer by reading the code — using our API Gateway as the example.

Question 1: How Does It START?
What you're looking for: the entry point and the start command.
How to find it:
bash# Step 1: Check package.json scripts (Node.js)
cat package.json | grep -A 5 '"scripts"'
# "start": "node dist/server.js"
# FOUND: the start command is "node dist/server.js"

# Step 2: Check the entry point file
cat src/server.ts | grep -i "listen"
# app.listen({ port: PORT, host: HOST })
# FOUND: it starts a web server

# For Python: check for uvicorn/gunicorn in requirements.txt or README
# For Go: check cmd/ folder for main.go
# For Java: check pom.xml for spring-boot-starter
Why this matters to you: this becomes your Dockerfile CMD and your Kubernetes container command.

Question 2: How Does It STOP?
What you're looking for: graceful shutdown handling.
How to find it:
bash# Search for signal handling in the code
grep -r "SIGTERM\|SIGINT\|shutdown\|graceful" src/
In our gateway, you'd find:
typescriptprocess.on("SIGTERM", () => shutdown("SIGTERM"));
process.on("SIGINT", () => shutdown("SIGINT"));

const shutdown = async (signal: string) => {
  app.log.info(`Received ${signal}. Shutting down gracefully...`);
  await app.close();    // stop accepting new requests, finish current ones
  process.exit(0);
};
If you DON'T find this:
NO graceful shutdown = BIG PROBLEM for Kubernetes

What happens without it:
  1. Kubernetes sends SIGTERM to the pod
  2. App doesn't handle it → ignores the signal
  3. Kubernetes waits 30 seconds
  4. Kubernetes sends SIGKILL → app dies immediately
  5. In-flight requests get dropped → users see errors

You MUST tell the developer:
  "Your service doesn't handle SIGTERM. In Kubernetes,
   this means users will see errors during every deployment.
   Please add a graceful shutdown handler."
How to find it in each language:
bash# Node.js
grep -r "SIGTERM\|SIGINT\|process.on" src/

# Python
grep -r "signal\|atexit\|shutdown" src/

# Go
grep -r "os.Signal\|syscall.SIGTERM\|signal.Notify" .

# Java (Spring Boot handles this automatically)
# But check for @PreDestroy annotations
grep -r "PreDestroy\|shutdown\|DisposableBean" src/

Question 3: How Do I Know It's HEALTHY?
What you're looking for: health check endpoints.
How to find it:
bash# Search for health endpoints
grep -r "health\|ready\|alive\|liveness\|readiness" src/
In our gateway:
typescriptapp.get("/health", ...)    // liveness — "is the process alive?"
app.get("/ready", ...)     // readiness — "can it handle traffic?"
You need TWO endpoints, not one:
/health (liveness):
  Returns 200 if the process is running.
  Simple check — just "am I alive?"
  
  If this fails → Kubernetes RESTARTS the pod
  (the process is stuck/deadlocked)

/ready (readiness):
  Returns 200 if the service can handle requests.
  Checks database connection, downstream services, etc.
  
  If this fails → Kubernetes STOPS SENDING TRAFFIC
  (but doesn't restart — the pod might recover)

COMMON MISTAKE:
  Developer creates only /health that checks the database.
  Database goes down → health fails → Kubernetes restarts all pods.
  Pods restart → still can't reach database → restart again.
  Infinite restart loop!
  
  The fix: /health should be simple (process alive?).
  /ready should check dependencies (database connected?).
If you DON'T find health endpoints:
Tell the developer:
  "I need a /health endpoint that returns 200 when the process
   is alive, and a /ready endpoint that returns 200 when the
   service can handle requests. Without these, Kubernetes can't
   manage your service properly."

Question 4: How Does It CONNECT to Other Services?
What you're looking for: URLs, connection strings, client configurations.
How to find it:
bash# Search for URLs, hosts, connection strings
grep -r "process.env\|os.environ\|os.Getenv" src/ | grep -i "url\|host\|endpoint\|conn"
In our gateway:
typescriptconst CATALOG_URL = process.env.PRODUCT_CATALOG_URL || "http://localhost:8000";
const ORDER_SERVICE_URL = process.env.ORDER_SERVICE_URL || "http://localhost:50051";
What this tells you:
The gateway connects to TWO downstream services.
Both URLs are configured via environment variables.
Both have localhost defaults (for local development).

YOUR JOB is to set these correctly for each environment:

  Docker Compose:
    PRODUCT_CATALOG_URL: http://product-catalog:8000
    ORDER_SERVICE_URL: http://order-service:50051

  Kubernetes:
    PRODUCT_CATALOG_URL: http://product-catalog.default.svc:8000
    ORDER_SERVICE_URL: http://order-service.default.svc:50051
Also search for database connections:
bash# Database connection strings
grep -r "DATABASE_URL\|REDIS_URL\|MONGO\|DYNAMODB" src/

# Connection timeouts and pool sizes
grep -r "timeout\|pool\|retry\|max_conn" src/
If you find hardcoded URLs:
typescript// BAD — developer hardcoded the URL
const response = await fetch("http://10.0.1.50:8000/products");

// Tell the developer:
// "This URL is hardcoded. It works on your machine but will
//  break in Docker, staging, and production. Please use an
//  environment variable instead."

Question 5: How Is It CONFIGURED?
What you're looking for: every environment variable the service reads.
How to find it:
bash# Find ALL environment variables the app reads
grep -r "process.env" src/            # Node.js
grep -r "os.environ\|os.getenv" src/  # Python
grep -r "os.Getenv" .                 # Go
In our gateway, this gives you:
process.env.PORT                    → 3000
process.env.HOST                    → 0.0.0.0
process.env.LOG_LEVEL               → info
process.env.PRODUCT_CATALOG_URL     → http://localhost:8000
process.env.ORDER_SERVICE_URL       → http://localhost:50051
process.env.JWT_SECRET              → (no default — REQUIRED)
process.env.APP_VERSION             → 1.0.0
Now you can create the .env.example file:
bash# .env.example (committed to Git — shows required vars without real values)
PORT=3000
HOST=0.0.0.0
LOG_LEVEL=info
PRODUCT_CATALOG_URL=http://product-catalog:8000
ORDER_SERVICE_URL=http://order-service:50051
JWT_SECRET=change-me-in-production
APP_VERSION=1.0.0
And the Docker Compose environment section:
yamlapi-gateway:
  environment:
    PORT: 3000
    PRODUCT_CATALOG_URL: http://product-catalog:8000
    ORDER_SERVICE_URL: http://order-service:50051
    JWT_SECRET: dev-secret-key
    LOG_LEVEL: debug
And later, the Kubernetes ConfigMap and Secrets.
Watch for secrets vs non-secrets:
NON-SECRETS (go in ConfigMap):        SECRETS (go in Secrets Manager):
  PORT=3000                             JWT_SECRET=actual-key
  LOG_LEVEL=info                        DATABASE_PASSWORD=actual-pass
  PRODUCT_CATALOG_URL=http://...        STRIPE_SECRET_KEY=sk_live_...
  APP_VERSION=1.0.0                     AWS_SECRET_ACCESS_KEY=...

Question 6: What Does It LOG?
What you're looking for: log format, log level, what gets logged.
How to find it:
bash# Check what logging library is used
grep -r "pino\|winston\|bunyan\|console.log\|logging" src/

# Check log format
grep -r "log.info\|log.error\|log.warn" src/
In our gateway:
typescript// Structured JSON logging with Pino
app.log.error({ err, productId: id }, "Failed to reach product catalog");
What this tells you:
LOG FORMAT: JSON (structured)
  {"level":"error","productId":"abc-123","msg":"Failed to reach product catalog"}
  
  This is what you WANT. Fluent Bit/CloudWatch can parse JSON logs.
  You can search by productId, filter by level, etc.

BAD FORMAT: Plain text
  console.log("Error: something went wrong with product abc-123")
  
  This is hard to parse, search, and alert on.
  If you see console.log everywhere, tell the developer:
  "Please use a structured logger like Pino or Winston.
   Our logging pipeline needs JSON format."
Check the log level configuration:
LOG_LEVEL=debug  → logs EVERYTHING (noisy, for development)
LOG_LEVEL=info   → logs normal operations (good for production)
LOG_LEVEL=warn   → logs only warnings and errors
LOG_LEVEL=error  → logs only errors (too quiet for production)

Production should use "info" — enough to debug issues
without drowning in noise.

Question 7: What Can Go WRONG?
What you're looking for: error handling, timeouts, fallback behavior.
How to find it:
bash# Search for error handling
grep -r "catch\|error\|throw\|panic\|fatal" src/

# Search for timeouts
grep -r "timeout\|deadline\|retry" src/

# Search for status codes
grep -r "500\|503\|502\|429" src/
In our gateway:
typescript} catch (err) {
  app.log.error({ err }, "Failed to reach order service");
  reply.code(503);
  return { error: "Order service unavailable" };
}
What this tells you:
GOOD: The gateway catches errors and returns 503
  → Your monitoring should alert on 503 rates
  → Istio circuit breaker should trigger on repeated 503s

CHECK FOR:
  ✓ Does it handle downstream service failures? (YES — returns 503)
  ✓ Does it have timeouts? (NOT YET — should add)
  ✓ Does it retry? (NO — should use Istio for this)
  ✓ Does it log errors with context? (YES — logs err + productId)

MISSING (tell the developer):
  "There's no request timeout. If the order service hangs,
   the gateway hangs forever. Add a timeout:
   
   const controller = new AbortController();
   setTimeout(() => controller.abort(), 5000);
   fetch(url, { signal: controller.signal })"

The One-Page Cheat Sheet
Print this and use it for every service:
SERVICE NAME: ________________

1. START
   Command: ________________
   Port: ________________
   Host binding: ________________ (must be 0.0.0.0 for Docker)

2. STOP
   Handles SIGTERM? □ YES  □ NO (if no → tell developer)
   Graceful shutdown? □ YES  □ NO

3. HEALTH
   Liveness endpoint: ________________ (e.g., /health)
   Readiness endpoint: ________________ (e.g., /ready)
   Missing? → tell developer

4. CONNECTIONS
   Downstream services: ________________
   Databases: ________________
   Caches: ________________
   All configurable via env vars? □ YES  □ NO (if no → tell developer)

5. CONFIGURATION
   Required env vars: ________________
   Secrets (need Secrets Manager): ________________
   Non-secrets (go in ConfigMap): ________________

6. LOGGING
   Format: □ JSON  □ Plain text (if plain → tell developer)
   Library: ________________
   Log level configurable? □ YES  □ NO

7. FAILURE MODES
   Handles downstream failures? □ YES  □ NO
   Has timeouts? □ YES  □ NO
   Returns proper error codes? □ YES  □ NO

How to Investigate ANY Unknown Service
bash# Run these commands in order on any project:

# 1. What language/framework?
ls *.json *.txt *.mod *.toml *.xml *.csproj *.gradle 2>/dev/null

# 2. What's the start command?
cat README.md | grep -i "run\|start\|usage"
cat package.json | grep -A2 '"start"'    # Node
cat Makefile | grep "run"                 # Go/general
cat Procfile                              # if exists

# 3. What env vars does it need?
grep -r "process.env\|os.environ\|os.Getenv\|Environment" src/ --include="*.ts" --include="*.py" --include="*.go" --include="*.cs"

# 4. What port?
grep -r "listen\|port\|PORT\|:3000\|:8000\|:8080" src/

# 5. Health endpoints?
grep -r "health\|ready\|alive" src/

# 6. Graceful shutdown?
grep -r "SIGTERM\|shutdown\|graceful\|signal" src/

# 7. What does it connect to?
grep -r "URL\|HOST\|ENDPOINT\|connection\|client" src/ | grep -i "env\|config"

# 8. Logging?
grep -r "log\|logger\|logging\|winston\|pino\|zerolog\|slog" src/ | head -5
This investigation takes 10-15 minutes and gives you everything you need to write the Dockerfile, Docker Compose config, Kubernetes manifests, and monitoring setup.
