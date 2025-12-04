# Development Docker Compose Setup

This repository includes a `docker-compose.dev.yml` file for local development. Each service is associated with one or more profiles, allowing you to run only the services you need.

## Quick Start

### Using the Helper Script (Recommended)

A convenience script `dev.sh` is provided for easier management:

```bash
# Make the script executable (first time only)
chmod +x dev.sh

# Start all services
./dev.sh start all

# Start specific profile
./dev.sh start database

# View logs
./dev.sh logs [service-name]

# Stop services
./dev.sh stop

# See all available commands
./dev.sh help
```

### Running All Services

To run all services:

```bash
docker compose -f docker-compose.dev.yml --profile all up
```

### Running Specific Services

Each service is assigned to specific profiles. You can start services by their profile:

#### Infrastructure Services

**Database (PostgreSQL):**
```bash
docker compose -f docker-compose.dev.yml --profile database up
```

**Message Broker (NATS):**
```bash
docker compose -f docker-compose.dev.yml --profile messaging up
```

**Database + Messaging:**
```bash
docker compose -f docker-compose.dev.yml --profile database --profile messaging up
```

#### Application Services

**Sagittarius (Rails) - Web Interface:**
```bash
docker compose -f docker-compose.dev.yml --profile sagittarius-web up
```

**Sagittarius (Rails) - gRPC Server:**
```bash
docker compose -f docker-compose.dev.yml --profile sagittarius-grpc up
```

**Both Sagittarius Services:**
```bash
docker compose -f docker-compose.dev.yml --profile sagittarius up
```

**Aquila:**
```bash
docker compose -f docker-compose.dev.yml --profile aquila up
```

**Taurus:**
```bash
docker compose -f docker-compose.dev.yml --profile taurus up
```

**Draco:**
```bash
docker compose -f docker-compose.dev.yml --profile draco up
```

**Sculptor:**
```bash
docker compose -f docker-compose.dev.yml --profile sculptor up
```

## Available Profiles

| Profile | Services | Dependencies | Purpose |
|---------|----------|--------------|---------|
| `all` | All services | - | Run entire stack |
| `database` | postgres | - | Database infrastructure only |
| `messaging` | nats | - | Message broker infrastructure only |
| `sagittarius` | sagittarius-rails-web, sagittarius-grpc, postgres | postgres | Both Sagittarius services with database |
| `sagittarius-web` | sagittarius-rails-web, postgres | postgres | Sagittarius web interface with database |
| `sagittarius-grpc` | sagittarius-grpc, postgres | postgres | Sagittarius gRPC server with database |
| `aquila` | aquila, nats | nats | Aquila service with NATS |
| `taurus` | taurus, nats | nats | Taurus service with NATS |
| `draco` | draco, nats | nats | Draco service with NATS |
| `sculptor` | sculptor | - | Sculptor service |

**Note:** When you start a service with a specific profile, Docker Compose automatically includes the required infrastructure services (postgres for Sagittarius services, nats for Aquila/Taurus/Draco). You don't need to specify both profiles explicitly.

## Common Development Scenarios

### Scenario 1: Developing Aquila locally, run everything else in Docker

```bash
# Start all services except Aquila (database, messaging, and other services)
docker compose -f docker-compose.dev.yml \
  --profile database \
  --profile messaging \
  --profile sagittarius \
  --profile taurus \
  --profile draco \
  --profile sculptor \
  up
```

Then run Aquila locally from its repository. Since Aquila needs NATS, the messaging profile ensures NATS is available.

### Scenario 2: Only need database and messaging for local development

```bash
# Just infrastructure - useful when running all application services locally
docker compose -f docker-compose.dev.yml \
  --profile database \
  --profile messaging \
  up -d
```

### Scenario 3: Testing Sagittarius integration

```bash
# Sagittarius profile automatically includes the database
docker compose -f docker-compose.dev.yml \
  --profile sagittarius \
  up
```

### Scenario 4: Run Taurus and Draco only

```bash
# Both services automatically include NATS
docker compose -f docker-compose.dev.yml \
  --profile taurus \
  --profile draco \
  up
```

## Service Ports

Services expose the following ports on localhost:

| Service | Port | Protocol |
|---------|------|----------|
| postgres | 5432 | PostgreSQL |
| nats | 4222 | NATS Client |
| nats | 8222 | NATS HTTP Monitoring |
| sagittarius-rails-web | 3000 | HTTP |
| sagittarius-grpc | 50051 | gRPC |
| aquila | 8081 | gRPC |
| taurus | 8082 | gRPC |
| draco | 8083 | gRPC |
| sculptor | 3001 | HTTP |

## Environment Variables

Copy `.env.example` to `.env` to customize configuration:

```bash
cp .env.example .env
```

Edit `.env` to change ports, credentials, or other settings.

## Useful Commands

### Start services in detached mode
```bash
docker compose -f docker-compose.dev.yml --profile <profile-name> up -d
```

### View logs
```bash
docker compose -f docker-compose.dev.yml logs -f [service-name]
```

### Stop services
```bash
docker compose -f docker-compose.dev.yml down
```

### Stop and remove volumes
```bash
docker compose -f docker-compose.dev.yml down -v
```

### Rebuild a service
```bash
docker compose -f docker-compose.dev.yml build <service-name>
```

### Check service health
```bash
docker compose -f docker-compose.dev.yml ps
```

## Notes

- Services include health checks for better dependency management
- The postgres data is persisted in a Docker volume named `postgres_data`
- All services are connected via the `reticulum_dev` network
- Services use `latest` image tags by default (can be overridden in `.env`)

## Troubleshooting

### Services won't start
- Check if ports are already in use: `netstat -tuln | grep <port>`
- Check logs: `docker compose -f docker-compose.dev.yml logs <service-name>`

### Database connection issues
- Ensure postgres is healthy: `docker compose -f docker-compose.dev.yml ps`
- Check postgres logs: `docker compose -f docker-compose.dev.yml logs postgres`

### Image pull issues
- Ensure you have access to the ghcr.io registry
- Login if needed: `docker login ghcr.io`
