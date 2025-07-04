#!/usr/bin/env python3
"""
# File location: /main.py
S.H.I.T. Bot - Shibarium Historical Income Tracker Bot
Main entry point combining ShitAI, SHIT Tracker, and DopeWars
"""

import asyncio
import logging
import os
import sys
import signal
from pathlib import Path
from contextlib import asynccontextmanager

from telegram import Update, BotCommand
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    MessageHandler,
    ConversationHandler,
    ContextTypes,
    filters
)
from telegram.constants import ParseMode

# Add app directory to Python path
sys.path.insert(0, str(Path(__file__).parent))

# Import handlers
from bot.handlers.menu_handler import MenuHandler
from bot.handlers.chat_handler import ChatHandler
from bot.handlers.tracker_handler import TrackerHandler
from bot.handlers.game_handler import GameHandler
from bot.utils.database import Database
from bot.utils.helpers import setup_logging, check_environment, is_admin_user

# Import health check server
from aiohttp import web

# Configure logging
logger = setup_logging()

# Global variables
db = None
app = None
health_runner = None


async def start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /shit_start command"""
    user = update.effective_user
    logger.info(f"User {user.id} ({user.username}) started the bot")
    
    # Register user if new
    await db.register_user(user.id, user.username)
    
    # Show main menu
    menu_handler = context.bot_data.get('menu_handler')
    if menu_handler:
        await menu_handler.show_main_menu(update, context)
    else:
        await update.message.reply_text(
            "⚠️ Bot is still initializing. Please try again in a moment.",
            parse_mode=ParseMode.MARKDOWN
        )


async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle /shit_help command"""
    help_text = """
📚 **S.H.I.T. Bot Commands**

**🎮 Game Commands:**
`/shit_game` - Open game menu
`/shit_play` - Start new game
`/shit_resume` - Resume saved game
`/shit_scores` - View leaderboard

**🤖 AI Commands:**
`/shit_ai` - Start AI chat
`/shit_models` - View available models
`/shit_model` - Change current model
`/shit_mode` - Toggle response mode
`/shit_clear` - Clear chat history

**📊 Tracker Commands:**
`/shit_track` - Start wallet tracking
`/shit_scan` - Quick wallet scan
`/shit_history` - View scan history

**⚙️ General Commands:**
`/shit_start` - Start the bot
`/shit_help` - Show this help
`/shit_cancel` - Cancel current operation

**ℹ️ Bot Info:**
• Version: 1.0.0
• All commands start with `/shit_` to avoid conflicts
• Support: @YourSupportGroup

_Choose wisely, trade smartly!_ 💎
    """
    
    await update.message.reply_text(help_text, parse_mode=ParseMode.MARKDOWN)


async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE) -> int:
    """Handle /shit_cancel command"""
    await update.message.reply_text(
        "❌ Operation cancelled. Use /shit_start to return to main menu.",
        parse_mode=ParseMode.MARKDOWN
    )
    return ConversationHandler.END


async def post_init(application: Application) -> None:
    """Initialize bot after start"""
    global db, health_runner
    
    logger.info("Initializing S.H.I.T. Bot...")
    
    # Initialize database
    db = Database()
    await db.initialize()
    
    # Store database in bot data for handlers
    application.bot_data['db'] = db
    
    # Initialize handlers
    menu_handler = MenuHandler(db)
    chat_handler = ChatHandler(db)
    tracker_handler = TrackerHandler(db)
    game_handler = GameHandler(db)
    
    # Store handlers in bot data
    application.bot_data['menu_handler'] = menu_handler
    application.bot_data['chat_handler'] = chat_handler
    application.bot_data['tracker_handler'] = tracker_handler
    application.bot_data['game_handler'] = game_handler
    
    # Set bot commands
    commands = [
        BotCommand("shit_start", "Start the bot"),
        BotCommand("shit_help", "Show help message"),
        BotCommand("shit_ai", "Start AI chat"),
        BotCommand("shit_models", "View AI models"),
        BotCommand("shit_model", "Change AI model"),
        BotCommand("shit_mode", "Toggle response mode"),
        BotCommand("shit_clear", "Clear chat history"),
        BotCommand("shit_track", "Start wallet tracking"),
        BotCommand("shit_scan", "Quick wallet scan"),
        BotCommand("shit_history", "View scan history"),
        BotCommand("shit_game", "Game menu"),
        BotCommand("shit_play", "Start new game"),
        BotCommand("shit_resume", "Resume saved game"),
        BotCommand("shit_scores", "View leaderboard"),
    ]
    
    # Add admin commands for admin users
    admin_users = os.getenv('ADMIN_USERS', '').split(',')
    if admin_users and admin_users[0]:
        admin_commands = commands + [
            BotCommand("shit_admin", "Admin menu"),
            BotCommand("shit_stats", "Bot statistics"),
        ]
        
        for admin_id in admin_users:
            try:
                await application.bot.set_my_commands(
                    admin_commands,
                    scope={'type': 'chat', 'chat_id': int(admin_id)}
                )
            except:
                pass
    
    # Set regular commands for all users
    await application.bot.set_my_commands(commands)
    
    # Start health check server
    health_app = web.Application()
    health_app.router.add_get('/health', health_check)
    health_runner = web.AppRunner(health_app)
    await health_runner.setup()
    site = web.TCPSite(health_runner, '0.0.0.0', 8000)
    await site.start()
    
    logger.info("Bot initialization complete!")
    logger.info(f"Health check available at http://0.0.0.0:8000/health")


async def shutdown(application: Application) -> None:
    """Cleanup on shutdown"""
    global db, health_runner
    
    logger.info("Shutting down S.H.I.T. Bot...")
    
    # Stop health check server
    if health_runner:
        await health_runner.cleanup()
    
    # Close database connection
    if db:
        await db.close()
    
    logger.info("Shutdown complete")


async def health_check(request):
    """Health check endpoint"""
    global db
    
    health_status = {
        "status": "healthy",
        "version": "1.0.0",
        "services": {
            "database": "unknown",
            "ollama": "unknown",
            "shibarium_api": "unknown"
        }
    }
    
    # Check database
    try:
        if db and await db.check_connection():
            health_status["services"]["database"] = "connected"
        else:
            health_status["services"]["database"] = "disconnected"
            health_status["status"] = "degraded"
    except:
        health_status["services"]["database"] = "error"
        health_status["status"] = "unhealthy"
    
    # Check Ollama
    ollama_host = os.getenv('OLLAMA_HOST')
    if ollama_host:
        try:
            import httpx
            async with httpx.AsyncClient() as client:
                response = await client.get(f"http://{ollama_host}:11434/api/tags", timeout=5)
                if response.status_code == 200:
                    health_status["services"]["ollama"] = "available"
                else:
                    health_status["services"]["ollama"] = "unavailable"
        except:
            health_status["services"]["ollama"] = "error"
    else:
        health_status["services"]["ollama"] = "not_configured"
    
    # Check Shibarium API
    if os.getenv('SHIBARIUM_API_KEY'):
        health_status["services"]["shibarium_api"] = "configured"
    else:
        health_status["services"]["shibarium_api"] = "not_configured"
    
    # Determine overall status
    status_code = 200 if health_status["status"] == "healthy" else 503
    
    return web.json_response(health_status, status=status_code)


async def error_handler(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    """Handle errors"""
    logger.error(f"Update {update} caused error {context.error}")
    
    # Notify user
    try:
        if update and update.effective_message:
            await update.effective_message.reply_text(
                "❌ An error occurred. Please try again or contact support.",
                parse_mode=ParseMode.MARKDOWN
            )
    except:
        pass
    
    # Notify admins
    admin_users = os.getenv('ADMIN_USERS', '').split(',')
    if admin_users and admin_users[0] and context.bot:
        error_message = f"⚠️ Bot Error:\n\n{str(context.error)[:500]}"
        for admin_id in admin_users:
            try:
                await context.bot.send_message(
                    chat_id=int(admin_id),
                    text=error_message
                )
            except:
                pass


def handle_signal(signum, frame):
    """Handle shutdown signals"""
    logger.info(f"Received signal {signum}")
    if app:
        app.stop_running()


def main() -> None:
    """Main entry point"""
    global app
    
    # Check environment
    if not check_environment():
        logger.error("Environment check failed!")
        sys.exit(1)
    
    # Get bot token
    token = os.getenv('BOT_TOKEN')
    if not token:
        logger.error("BOT_TOKEN not found in environment!")
        sys.exit(1)
    
    # Create application
    app = Application.builder().token(token).build()
    
    # Register handlers
    
    # Command handlers
    app.add_handler(CommandHandler("shit_start", start))
    app.add_handler(CommandHandler("shit_help", help_command))
    app.add_handler(CommandHandler("shit_cancel", cancel))
    
    # Menu callback handler
    app.add_handler(CallbackQueryHandler(
        MenuHandler.handle_callback,
        pattern="^(shit_|back_to_main|shit_help|shit_status|shit_settings)"
    ))
    
    # Conversation handlers
    app.add_handler(ChatHandler.get_conversation_handler())
    app.add_handler(TrackerHandler.get_conversation_handler())
    app.add_handler(GameHandler.get_conversation_handler())
    
    # Direct command handlers
    app.add_handler(CommandHandler("shit_scores", 
        lambda u, c: GameHandler(app.bot_data['db']).show_leaderboard_direct(u, c)))
    
    # Error handler
    app.add_error_handler(error_handler)
    
    # Post init and shutdown
    app.post_init = post_init
    app.post_shutdown = shutdown
    
    # Setup signal handlers
    signal.signal(signal.SIGINT, handle_signal)
    signal.signal(signal.SIGTERM, handle_signal)
    
    # Start bot
    logger.info("Starting S.H.I.T. Bot...")
    logger.info(f"Bot username: @{app.bot.username if hasattr(app.bot, 'username') else 'loading...'}")
    
    # Run bot
    app.run_polling(
        allowed_updates=Update.ALL_TYPES,
        drop_pending_updates=True,
        close_loop=False
    )


if __name__ == '__main__':
    # Run with proper event loop
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logger.info("Bot stopped by user")
    except Exception as e:
        logger.error(f"Fatal error: {e}")
        sys.exit(1)