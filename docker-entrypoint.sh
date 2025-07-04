#!/bin/bash
# File location: /docker-entrypoint.sh
# S.H.I.T. Bot Docker Entrypoint
# Handles initialization and startup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO:${NC} $1"
}

log_success() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] SUCCESS:${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

log_error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Function to check environment variables
check_environment() {
    log "Checking environment variables..."
    
    if [ -z "$BOT_TOKEN" ]; then
        log_error "BOT_TOKEN is not set!"
        log_error "Please set BOT_TOKEN in your .env file or docker-compose.yml"
        exit 1
    fi
    
    log_success "BOT_TOKEN is set"
    
    # Show optional warnings
    if [ -z "$SHIBARIUM_API_KEY" ]; then
        log_warning "SHIBARIUM_API_KEY is not set - tracker features may be limited"
    fi
    
    if [ -z "$OLLAMA_HOST" ]; then
        log_warning "OLLAMA_HOST is not set - AI chat features will be disabled"
    fi
}

# Function to create necessary directories
create_directories() {
    log "Creating necessary directories..."
    
    directories=(
        "/app/data/db"
        "/app/data/tokens"
        "/app/data/routers"
        "/app/data/bridges"
        "/app/data/prices"
        "/app/data/persistence"
        "/app/logs"
        "/app/temp"
        "/app/exports"
    )
    
    for dir in "${directories[@]}"; do
        if [ ! -d "$dir" ]; then
            mkdir -p "$dir"
            log_success "Created directory: $dir"
        fi
    done
}

# Function to initialize cache files
initialize_cache_files() {
    log "Initializing cache files..."
    
    cache_files=(
        "/app/data/tokens/token_cache.json"
        "/app/data/routers/router_cache.json"
        "/app/data/bridges/bridge_cache.json"
        "/app/data/prices/price_cache.json"
    )
    
    for file in "${cache_files[@]}"; do
        if [ ! -f "$file" ]; then
            echo '{}' > "$file"
            log_success "Created cache file: $file"
        fi
    done
}

# Function to wait for database
wait_for_db() {
    if [ -n "$DATABASE_URL" ] && [ "$USE_SQLITE" != "true" ]; then
        log "Waiting for PostgreSQL to be ready..."
        
        # Extract host and port from DATABASE_URL
        # Format: postgresql://user:pass@host:port/db
        DB_HOST=$(echo $DATABASE_URL | sed -E 's/.*@([^:]+):.*/\1/')
        DB_PORT=$(echo $DATABASE_URL | sed -E 's/.*:([0-9]+)\/.*/\1/')
        
        # Default port if not specified
        DB_PORT=${DB_PORT:-5432}
        
        # Wait for connection
        max_attempts=30
        attempt=0
        
        while ! nc -z $DB_HOST $DB_PORT 2>/dev/null; do
            attempt=$((attempt + 1))
            if [ $attempt -ge $max_attempts ]; then
                log_error "Database connection timeout after $max_attempts attempts"
                log_warning "Falling back to SQLite"
                export USE_SQLITE=true
                return
            fi
            log "Waiting for database... (attempt $attempt/$max_attempts)"
            sleep 2
        done
        
        log_success "Database is ready!"
    else
        log "Using SQLite database"
    fi
}

# Function to test Ollama connection
test_ollama() {
    if [ -n "$OLLAMA_HOST" ]; then
        log "Testing Ollama connection..."
        
        # Try to connect to Ollama
        if curl -s -f "http://${OLLAMA_HOST}:${OLLAMA_PORT:-11434}/api/tags" >/dev/null 2>&1; then
            log_success "Ollama is accessible"
        else
            log_warning "Ollama is not accessible - AI features will be limited"
        fi
    fi
}

# Main initialization
main() {
    log "Starting S.H.I.T. Bot initialization..."
    
    # Step 1: Check environment
    check_environment
    
    # Step 2: Create directories
    create_directories
    
    # Step 3: Initialize cache files
    initialize_cache_files
    
    # Step 4: Wait for database
    wait_for_db
    
    # Step 5: Test optional services
    test_ollama
    
    # Step 6: Show startup info
    log "=== S.H.I.T. Bot Startup Information ==="
    log "Python version: $(python --version 2>&1)"
    log "Working directory: $(pwd)"
    log "Current user: $(whoami)"
    
    # Show feature flags
    log "Feature flags:"
    log "  AI Chat: ${ENABLE_AI_CHAT:-true}"
    log "  Tracker: ${ENABLE_TRACKER:-true}"
    log "  Game: ${ENABLE_GAME:-true}"
    
    log_success "Initialization completed!"
    log "=== Starting S.H.I.T. Bot ==="
    
    # Execute the main command
    exec "$@"
}

# Handle signals gracefully
trap 'log "Received SIGTERM, shutting down..."; exit 0' SIGTERM
trap 'log "Received SIGINT, shutting down..."; exit 0' SIGINT

# Run main initialization
main "$@"