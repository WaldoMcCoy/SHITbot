#!/bin/bash
# File location: /setup.sh
# S.H.I.T. Bot Interactive Setup Script

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Banner
echo -e "${BLUE}"
echo "================================================"
echo "   S.H.I.T. Bot - Setup Script"
echo "   Shibarium Historical Income Tracker"
echo "================================================"
echo -e "${NC}"

# Check for required commands
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    else
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    fi
}

echo "Checking dependencies..."
echo ""

# Check Docker
if ! check_command docker; then
    echo -e "${YELLOW}Docker is required. Install from: https://docs.docker.com/get-docker/${NC}"
    exit 1
fi

# Check Docker Compose
if ! check_command docker-compose; then
    # Try docker compose (v2)
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✅ docker compose (v2) is installed${NC}"
        alias docker-compose='docker compose'
    else
        echo -e "${YELLOW}Docker Compose is required. Install from: https://docs.docker.com/compose/install/${NC}"
        exit 1
    fi
fi

# Check Git
check_command git || echo -e "${YELLOW}Warning: Git not found. You may have issues with updates.${NC}"

# Check Make
check_command make || echo -e "${YELLOW}Warning: Make not found. Install with: sudo apt-get install make${NC}"

echo ""
echo "Creating directory structure..."

# Create necessary directories
directories=(
    "data/db"
    "data/tokens"
    "data/routers"
    "data/bridges"
    "data/prices"
    "logs"
    "exports"
    "backups"
)

for dir in "${directories[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo -e "${GREEN}✅ Created $dir${NC}"
    else
        echo -e "${BLUE}📁 $dir already exists${NC}"
    fi
done

# Check for .env file
echo ""
if [ ! -f .env ]; then
    echo "Setting up environment configuration..."
    
    if [ -f .env.example ]; then
        cp .env.example .env
        echo -e "${GREEN}✅ Created .env from template${NC}"
    else
        echo -e "${RED}❌ .env.example not found!${NC}"
        exit 1
    fi
    
    echo ""
    echo -e "${YELLOW}Please configure your .env file:${NC}"
    echo ""
    
    # Get Bot Token
    read -p "Enter your Telegram Bot Token (from @BotFather): " bot_token
    if [ ! -z "$bot_token" ]; then
        sed -i.bak "s/BOT_TOKEN=.*/BOT_TOKEN=$bot_token/" .env
        echo -e "${GREEN}✅ Bot token configured${NC}"
    else
        echo -e "${RED}⚠️  Bot token is required!${NC}"
    fi
    
    # Get Shibarium API Key
    echo ""
    read -p "Enter your Shibarium API Key (from shibariumscan.io): " api_key
    if [ ! -z "$api_key" ]; then
        sed -i.bak "s/SHIBARIUM_API_KEY=.*/SHIBARIUM_API_KEY=$api_key/" .env
        echo -e "${GREEN}✅ API key configured${NC}"
    else
        echo -e "${YELLOW}⚠️  API key not set - tracker features will be limited${NC}"
    fi
    
    # Get Admin User ID
    echo ""
    echo "To get your Telegram User ID:"
    echo "1. Start a chat with @userinfobot"
    echo "2. It will reply with your user ID"
    echo ""
    read -p "Enter your Telegram User ID (for admin access): " admin_id
    if [ ! -z "$admin_id" ]; then
        sed -i.bak "s/ADMIN_USERS=.*/ADMIN_USERS=$admin_id/" .env
        echo -e "${GREEN}✅ Admin user configured${NC}"
    fi
    
    # Ollama configuration
    echo ""
    read -p "Do you have Ollama installed for AI features? (y/n): " has_ollama
    if [[ $has_ollama =~ ^[Yy]$ ]]; then
        read -p "Enter Ollama host (default: host.docker.internal): " ollama_host
        ollama_host=${ollama_host:-host.docker.internal}
        sed -i.bak "s/OLLAMA_HOST=.*/OLLAMA_HOST=$ollama_host/" .env
        echo -e "${GREEN}✅ Ollama configured${NC}"
    else
        echo -e "${YELLOW}ℹ️  AI features will be disabled${NC}"
        sed -i.bak "s/ENABLE_AI_CHAT=.*/ENABLE_AI_CHAT=false/" .env
    fi
    
    # Database password
    echo ""
    echo -e "${YELLOW}⚠️  Using default database password (change for production!)${NC}"
    
    # Clean up backup files
    rm -f .env.bak
    
else
    echo -e "${BLUE}📁 .env file already exists${NC}"
    echo ""
    read -p "Do you want to reconfigure? (y/n): " reconfigure
    if [[ $reconfigure =~ ^[Yy]$ ]]; then
        cp .env .env.backup
        echo -e "${GREEN}✅ Backed up existing .env to .env.backup${NC}"
        rm .env
        exec "$0"
    fi
fi

# Check for game config
echo ""
if [ ! -f data/game_config.json ]; then
    echo "Creating default game configuration..."
    cat > data/game_config.json << 'EOF'
{
  "version": "1.0",
  "drugs": {
    "btc": {"name": "Bitcoin", "emoji": "₿", "min_price": 15000, "max_price": 65000},
    "eth": {"name": "Ethereum", "emoji": "Ξ", "min_price": 800, "max_price": 4500},
    "shib": {"name": "SHIB", "emoji": "🐕", "min_price": 1, "max_price": 100},
    "doge": {"name": "DOGE", "emoji": "Ð", "min_price": 50, "max_price": 500},
    "bone": {"name": "BONE", "emoji": "🦴", "min_price": 200, "max_price": 2000},
    "leash": {"name": "LEASH", "emoji": "🦴", "min_price": 300, "max_price": 3000}
  },
  "locations": [
    "🏙️ Crypto City",
    "🌃 DeFi District",
    "🏦 Exchange Square",
    "⛓️ Blockchain Bay",
    "💰 Wallet Way",
    "🚀 Moon Base"
  ]
}
EOF
    echo -e "${GREEN}✅ Created default game configuration${NC}"
fi

# Docker check
echo ""
echo "Checking Docker service..."
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Docker is not running!${NC}"
    echo "Please start Docker and run this script again."
    exit 1
fi

# Build confirmation
echo ""
echo -e "${BLUE}Ready to build and start the bot!${NC}"
echo ""
echo "This will:"
echo "  1. Build the Docker containers"
echo "  2. Start PostgreSQL database"
echo "  3. Start the S.H.I.T. Bot"
echo ""
read -p "Continue? (y/n): " confirm

if [[ $confirm =~ ^[Yy]$ ]]; then
    echo ""
    echo "Building containers..."
    docker-compose build
    
    echo ""
    echo "Starting services..."
    docker-compose up -d
    
    # Wait for services
    echo ""
    echo "Waiting for services to start..."
    sleep 5
    
    # Check status
    if docker-compose ps | grep -q "Up"; then
        echo ""
        echo -e "${GREEN}✅ Bot is running!${NC}"
        echo ""
        echo "Next steps:"
        echo "  1. Check logs: make logs"
        echo "  2. Open Telegram and start your bot"
        echo "  3. Send /shit_start to begin"
        echo ""
        echo "Useful commands:"
        echo "  make logs      - View bot logs"
        echo "  make restart   - Restart bot"
        echo "  make down      - Stop bot"
        echo "  make help      - Show all commands"
        echo ""
        
        # Show bot info if available
        if [ ! -z "$bot_token" ]; then
            bot_username=$(echo $bot_token | cut -d: -f1)
            echo -e "${BLUE}Your bot token starts with: $bot_username...${NC}"
        fi
        
        echo ""
        echo -e "${GREEN}🎉 Setup complete! Enjoy using S.H.I.T. Bot!${NC}"
    else
        echo -e "${RED}❌ Something went wrong. Check logs with: docker-compose logs${NC}"
        exit 1
    fi
else
    echo ""
    echo "Setup cancelled. Run this script again when ready."
    echo ""
    echo "You can also set up manually:"
    echo "  1. Edit .env file"
    echo "  2. Run: docker-compose up -d"
fi

echo ""
echo -e "${BLUE}================================================${NC}"