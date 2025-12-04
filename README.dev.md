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

**Runtime Services (Aquila + Taurus + Draco):**
```bash
docker compose -f docker-compose.dev.yml --profile runtime up
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
| `runtime` | aquila, taurus, draco, nats | nats | All runtime services (Aquila, Taurus, Draco) with NATS |
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

### Service Image Tags

All service images use CI pipeline builds from `ghcr.io/code0-tech/reticulum/ci-builds/`. You **must** specify image tags as pipeline IDs in your `.env` file:

```bash
# In your .env file
# Tags are pipeline IDs from CI builds
SAGITTARIUS_TAG=12345-ruby    # Format: PIPELINE_ID-VARIANT
AQUILA_TAG=12345              # Format: PIPELINE_ID
TAURUS_TAG=12345              # Format: PIPELINE_ID
DRACO_TAG=12345-go            # Format: PIPELINE_ID-VARIANT
SCULPTOR_TAG=12345-node       # Format: PIPELINE_ID-VARIANT
```

**Important Notes:**
- Image tags are **required** - there are no default values
- Tags are CI pipeline IDs, not git tags or version numbers
- Some services require a variant suffix (e.g., `-ruby`, `-go`, `-node`)
- All images come from the `ci-builds` repository path

This allows you to:
- Test specific CI pipeline builds
- Use consistent versions across all services
- Ensure reproducible development environments

**Security Note:** The default configuration uses weak passwords that are suitable for local development only. If you're running services in any environment that is accessible from outside your local machine, make sure to:
- Change all default passwords in your `.env` file
- Use strong, unique passwords for database credentials
- Change the default runtime tokens
- Consider using secrets management for sensitive configuration

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
- Service images require pipeline ID tags to be specified in `.env` file (no defaults)

## Troubleshooting

### Missing environment variables
If you see an error about missing required environment variables:
```
Error: Required environment variables are not set:
  - SAGITTARIUS_TAG
  ...
```
Create and configure your `.env` file:
```bash
cp .env.example .env
# Edit .env to set pipeline IDs for all image tags
```

### Services won't start
- Check if ports are already in use: `netstat -tuln | grep <port>`
- Check logs: `docker compose -f docker-compose.dev.yml logs <service-name>`

### Database connection issues
- Ensure postgres is healthy: `docker compose -f docker-compose.dev.yml ps`
- Check postgres logs: `docker compose -f docker-compose.dev.yml logs postgres`

### Image pull issues
- Ensure you have access to the ghcr.io registry
- Login if needed: `docker login ghcr.io`
- Verify your pipeline IDs are correct in `.env`
