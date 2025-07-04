# S.H.I.T. Bot - Shibarium Historical Income Tracker

![S.H.I.T. Bot Logo](https://img.shields.io/badge/S.H.I.T.-Bot-orange?style=for-the-badge&logo=telegram)

A comprehensive Telegram bot for Shibarium users featuring:
- 🤖 **ShitAI**: AI-powered chat with multiple models via Ollama
- 📊 **S.H.I.T. Tracker**: Advanced transaction tracking & tax reporting
- 🎮 **DopeWars**: Crypto trading game with leaderboards

## 🚀 Features

### 🤖 ShitAI Chat
- **Multi-Model Support**: Dynamic model selection from Ollama
- **Two Response Modes**: Unlimited (detailed) and Limited (fast, 500 chars)
- **Conversation Memory**: Persistent chat history per user
- **Real-time Model Switching**: Change AI models mid-conversation

### 📊 S.H.I.T. Tracker
- **Full Transaction History**: Complete Shibarium transaction scanning
- **Multiple Export Formats**: Excel, Koinly CSV, and text summaries
- **Real-time Token Discovery**: Automatic token/router detection and caching
- **Advanced Features**: NFT support, DeFi transactions, bridge tracking
- **Tax Reporting**: Koinly-compatible exports for tax preparation
- **Smart Caching**: JSON-based token/router caching for efficiency

### 🎮 DopeWars - Crypto Edition
- **Classic Gameplay**: Based on the original 80s DOS game
- **Crypto Theme**: Trade Bitcoin, Ethereum, SHIB, DOGE, BONE, and LEASH
- **Random Events**: SEC raids, whale offers, market pumps/crashes
- **Combat System**: Buy guns to fight back against authorities
- **Leaderboards**: All-time scores and contest competitions
- **Persistent Progress**: Save/continue games anytime
- **Multi-player Support**: Isolated game sessions per user

## 📋 Prerequisites

### Required
- **Docker & Docker Compose**
- **Telegram Bot Token** (from @BotFather)
- **Shibarium API Keys** (from ShibariumScan or similar)

### Optional (for AI features)
- **Ollama** with loaded AI models (for ShitAI)
- **PostgreSQL** (SQLite fallback included)

## 🛠️ Installation

### 1. Clone Repository
```bash
git clone https://github.com/your-repo/shit-telegram-bot.git
cd shit-telegram-bot
```

### 2. Environment Configuration
```bash
# Copy environment template
cp .env.example .env

# Edit with your values
nano .env
```

### 3. Required Environment Variables
```bash
# Telegram Bot (Required)
BOT_TOKEN=your_telegram_bot_token_here

# S.H.I.T. Tracker (Required)
SHIBARIUM_API_KEY=your_shibarium_api_key_here
SHIBARIUM_API_KEY2=your_backup_api_key_here

# Ollama AI (Optional - for ShitAI)
OLLAMA_HOST=host.docker.internal
OLLAMA_PORT=11434
```

### 4. Quick Start
```bash
# Start with PostgreSQL (recommended)
docker-compose up -d

# Or start with SQLite only
docker-compose up -d shit-bot

# View logs
docker-compose logs -f shit-bot
```

## 🔧 Configuration

### Ollama Setup (for AI features)
```bash
# Install Ollama on host machine
curl -fsSL https://ollama.ai/install.sh | sh

# Download AI models
ollama pull llama2
ollama pull codellama
ollama pull mistral

# Verify models are available
ollama list
```

### Database Options

#### PostgreSQL (Recommended)
- Automatic setup via Docker Compose
- Better performance for multiple users
- Built-in connection pooling

#### SQLite (Fallback)
- No additional setup required
- Good for development/testing
- Automatic fallback if PostgreSQL unavailable

### API Keys Setup

#### ShibariumScan API
1. Visit [ShibariumScan.io](https://shibariumscan.io)
2. Create account and generate API key
3. Add to `.env` file

#### Backup API Services
- Configure multiple API keys for redundancy
- Automatic failover between API providers

## 🎮 Game Configuration

### Admin Controls
```python
# Add admin users to control game settings
ADMIN_USERS=123456789,987654321

# Modify drug/crypto names and prices
/shit_admin drugs              # View current drugs
/shit_admin update_drug btc "💎 Diamond"  # Change names
/shit_admin add_location "FTX Ruins"      # Add locations
```

### Customizable Elements
- **Cryptocurrencies**: Names, price ranges, icons
- **Locations**: Trading locations and names
- **Game Mechanics**: Starting cash, debt, duration
- **Events**: Probabilities and outcomes

## 🐳 Docker Deployment

### Development
```bash
# Start with live code reloading
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up -d
```

### Production
```bash
# Start with monitoring and nginx
docker-compose --profile production up -d

# With monitoring stack
docker-compose --profile monitoring up -d
```

### Scaling
```bash
# Scale bot instances
docker-compose up -d --scale shit-bot=3
```

## 📊 Monitoring

### Health Checks
- **Endpoint**: `http://localhost:8000/health`
- **Automatic**: Built-in Docker health checks
- **Alerts**: Configure monitoring for production

### Logs
```bash
# View real-time logs
docker-compose logs -f shit-bot

# View specific service logs
docker-compose logs -f bot-db

# Filter by log level
docker-compose logs shit-bot | grep ERROR
```

### Metrics (Optional)
- **Prometheus**: Metrics collection
- **Grafana**: Visual dashboards
- **Alerts**: Custom alert rules

## 🔒 Security

### Bot Security
- **Rate Limiting**: Per-user request limits
- **Input Validation**: Sanitized user inputs
- **Error Handling**: No sensitive data in error messages
- **API Key Rotation**: Support for multiple API keys

### Data Protection
- **Local Processing**: Sensitive data stays local
- **Auto-cleanup**: Temporary files automatically deleted
- **Encryption**: Optional data encryption at rest
- **Access Control**: Admin-only configuration commands

## 🧪 Testing

### Unit Tests
```bash
# Run all tests
docker-compose exec shit-bot python -m pytest

# Run specific test suite
docker-compose exec shit-bot python -m pytest tests/test_game.py

# Run with coverage
docker-compose exec shit-bot python -m pytest --cov=apps
```

### Integration Tests
```bash
# Test bot functionality
docker-compose exec shit-bot python tests/test_integration.py

# Test database connections
docker-compose exec shit-bot python tests/test_database.py
```

## 🤝 Contributing

### Development Setup
```bash
# Clone and setup
git clone https://github.com/your-repo/shit-telegram-bot.git
cd shit-telegram-bot

# Install dependencies for local development
pip install -r requirements.txt

# Setup pre-commit hooks
pre-commit install
```

### Code Style
- **Black**: Code formatting
- **isort**: Import sorting
- **flake8**: Linting
- **mypy**: Type checking

### Pull Request Process
1. Fork the repository
2. Create feature branch (`git checkout -b feature/amazing-feature`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing-feature`)
5. Open Pull Request

## 📝 Usage Examples

### Tracker Commands
```
/shit_track                    # Start wallet scanning
/shit_menu → 📊 SHIT Tracker  # Menu navigation
```

### AI Chat Commands
```
/shit_ai                       # Start AI chat
/shit_model                    # Change AI model (during chat)
/shit_mode                     # Toggle response mode
/shit_clear                    # Clear chat history
```

### Game Commands
```
/shit_game                     # Start DopeWars
/shit_menu → 🎮 DopeWars      # Menu navigation
```

### Admin Commands
```
/shit_admin drugs              # Manage game currencies
/shit_admin locations          # Manage trading locations
/shit_admin reset              # Reset game configuration
```

## 🐛 Troubleshooting

### Common Issues

#### "Message to be replied not found"
- **Cause**: Telegram message handling conflict
- **Fix**: Restart bot container
```bash
docker-compose restart shit-bot
```

#### "Could not connect to Ollama"
- **Cause**: Ollama not running or models not loaded
- **Fix**: Start Ollama and load models
```bash
ollama serve
ollama pull llama2
```

#### Database Connection Errors
- **Cause**: PostgreSQL not ready or connection issues
- **Fix**: Check database health
```bash
docker-compose logs bot-db
docker-compose exec bot-db pg_isready -U shitbot
```

#### API Rate Limiting
- **Cause**: Too many API requests
- **Fix**: Configure multiple API keys or reduce scan frequency

### Debug Mode
```bash
# Enable debug logging
echo "LOG_LEVEL=DEBUG" >> .env
docker-compose restart shit-bot

# View detailed logs
docker-compose logs -f shit-bot
```

### Reset Everything
```bash
# Stop all services
docker-compose down

# Remove all data (⚠️ This deletes everything!)
docker-compose down -v

# Start fresh
docker-compose up -d
```

## 📚 API Documentation

### Health Check Endpoint
```http
GET /health
```
Response:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "database": "connected",
  "ollama": "available"
}
```

### Webhook Support
```bash
# Configure webhook mode
WEBHOOK_URL=https://your-domain.com/webhook
WEBHOOK_SECRET=your_webhook_secret
```

## 🔄 Updates

### Bot Updates
```bash
# Pull latest changes
git pull origin main

# Rebuild and restart
docker-compose build shit-bot
docker-compose up -d shit-bot
```

### Database Migrations
```bash
# Run database migrations
docker-compose exec shit-bot python manage.py migrate

# Or apply SQL schema directly
docker-compose exec bot-db psql -U shitbot -f /app/schema_fixed.sql
```

## 📞 Support

### Community
- **GitHub Issues**: Bug reports and feature requests
- **Telegram Group**: Community support and discussion
- **Documentation**: Comprehensive guides and examples

### Professional Support
- **Custom Development**: Feature customization
- **Deployment Services**: Production setup assistance
- **Training**: Team training and consultation

## 📄 License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Original DopeWars**: Classic 80s DOS game inspiration
- **Shibarium Community**: Network support and testing
- **Ollama Project**: AI model serving infrastructure
- **Python-Telegram-Bot**: Excellent Telegram bot framework

## 🔗 Links

- **GitHub Repository**: [https://github.com/your-repo/shit-telegram-bot](https://github.com/your-repo/shit-telegram-bot)
- **Docker Hub**: [https://hub.docker.com/r/your-repo/shit-bot](https://hub.docker.com/r/your-repo/shit-bot)
- **Documentation**: [https://your-docs-site.com](https://your-docs-site.com)
- **Telegram Bot**: [@your_shit_bot](https://t.me/your_shit_bot)

---

**Made with ❤️ for the Shib Army**

*S.H.I.T. Bot - Because tracking your Shibarium transactions shouldn't be a pain in the ass!*