#!/bin/bash
# Development Docker Compose Helper Script
# Usage: ./dev.sh [command] [options]

set -e

COMPOSE_FILE="docker-compose.dev.yml"

show_help() {
    cat << EOF
Development Docker Compose Helper

Usage: $0 <command> [options]

Commands:
    start <profile>       Start services with specified profile
    stop                  Stop all services
    restart <profile>     Restart services with specified profile
    logs [service]        Show logs (optionally for specific service)
    ps                    Show running services
    down                  Stop and remove containers
    clean                 Stop and remove containers and volumes

Available Profiles:
    all                   All services
    database              PostgreSQL only
    messaging             NATS only
    sagittarius           Both Sagittarius services (includes postgres)
    sagittarius-web       Sagittarius web (includes postgres)
    sagittarius-grpc      Sagittarius gRPC (includes postgres)
    runtime               All runtime services: Aquila, Taurus, Draco (includes nats)
    aquila                Aquila service (includes nats)
    taurus                Taurus service (includes nats)
    draco                 Draco service (includes nats)
    sculptor              Sculptor service

Examples:
    $0 start all          # Start all services
    $0 start database     # Start only database
    $0 start runtime      # Start Aquila, Taurus, and Draco with NATS
    $0 start aquila       # Start Aquila with NATS
    $0 logs sagittarius-rails-web
    $0 ps
    $0 stop

EOF
}

case "${1:-}" in
    start)
        if [ -z "$2" ]; then
            echo "Error: Profile required"
            show_help
            exit 1
        fi
        echo "Starting services with profile: $2"
        docker compose -f "$COMPOSE_FILE" --profile "$2" up -d
        echo "Services started. Use '$0 logs' to view logs."
        ;;
    
    stop)
        echo "Stopping services..."
        docker compose -f "$COMPOSE_FILE" stop
        ;;
    
    restart)
        if [ -z "$2" ]; then
            echo "Error: Profile required"
            show_help
            exit 1
        fi
        echo "Restarting services with profile: $2"
        docker compose -f "$COMPOSE_FILE" --profile "$2" restart
        ;;
    
    logs)
        if [ -z "$2" ]; then
            docker compose -f "$COMPOSE_FILE" logs -f
        else
            docker compose -f "$COMPOSE_FILE" logs -f "$2"
        fi
        ;;
    
    ps)
        docker compose -f "$COMPOSE_FILE" ps
        ;;
    
    down)
        echo "Stopping and removing containers..."
        docker compose -f "$COMPOSE_FILE" down
        ;;
    
    clean)
        echo "Stopping and removing containers and volumes..."
        docker compose -f "$COMPOSE_FILE" down -v
        echo "Cleanup complete."
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        echo "Error: Unknown command '${1:-}'"
        echo ""
        show_help
        exit 1
        ;;
esac
