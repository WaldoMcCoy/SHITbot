-- File location: /schema_fixed.sql
-- S.H.I.T. Bot Database Schema
-- PostgreSQL schema with all features

-- Create database if not exists
-- CREATE DATABASE shitbot;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    user_id BIGINT PRIMARY KEY,
    username VARCHAR(255),
    first_name VARCHAR(255),
    last_name VARCHAR(255),
    is_active BOOLEAN DEFAULT true,
    is_admin BOOLEAN DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_seen TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_active ON users(is_active);

-- User settings
CREATE TABLE IF NOT EXISTS user_settings (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    ai_unlimited_mode BOOLEAN DEFAULT true,
    ai_bold_mode BOOLEAN DEFAULT false,
    ai_default_model VARCHAR(100) DEFAULT 'llama2',
    tracker_auto_delete BOOLEAN DEFAULT true,
    tracker_deep_scan BOOLEAN DEFAULT false,
    tracker_include_usd BOOLEAN DEFAULT true,
    notifications_enabled BOOLEAN DEFAULT true,
    game_dm_mode BOOLEAN DEFAULT false,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Game states table
CREATE TABLE IF NOT EXISTS game_states (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    username VARCHAR(255),
    state_data JSONB NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_game_states_user ON game_states(user_id);
CREATE INDEX idx_game_states_active ON game_states(is_active);

-- Leaderboard table
CREATE TABLE IF NOT EXISTS leaderboard (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    username VARCHAR(255),
    score INTEGER NOT NULL,
    days_survived INTEGER DEFAULT 0,
    final_cash INTEGER DEFAULT 0,
    final_debt INTEGER DEFAULT 0,
    highest_cash INTEGER DEFAULT 0,
    highest_debt INTEGER DEFAULT 0,
    total_trades INTEGER DEFAULT 0,
    game_version VARCHAR(10) DEFAULT '1.0',
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_leaderboard_score ON leaderboard(score DESC);
CREATE INDEX idx_leaderboard_user ON leaderboard(user_id);
CREATE INDEX idx_leaderboard_timestamp ON leaderboard(timestamp DESC);

-- Player statistics
CREATE TABLE IF NOT EXISTS player_stats (
    user_id BIGINT PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    games_played INTEGER DEFAULT 0,
    high_score INTEGER DEFAULT 0,
    total_score BIGINT DEFAULT 0,
    total_profit BIGINT DEFAULT 0,
    highest_cash INTEGER DEFAULT 0,
    highest_debt_survived INTEGER DEFAULT 0,
    most_guns INTEGER DEFAULT 0,
    best_health INTEGER DEFAULT 0,
    perfect_games INTEGER DEFAULT 0,
    survivor_games INTEGER DEFAULT 0,
    favorite_location VARCHAR(100),
    most_traded_drug VARCHAR(50),
    total_days_played INTEGER DEFAULT 0,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Competitions table
CREATE TABLE IF NOT EXISTS competitions (
    id SERIAL PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    start_date TIMESTAMP NOT NULL,
    end_date TIMESTAMP NOT NULL,
    games_required INTEGER DEFAULT 10,
    created_by BIGINT REFERENCES users(user_id),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_competitions_active ON competitions(is_active);
CREATE INDEX idx_competitions_dates ON competitions(start_date, end_date);

-- Competition participants
CREATE TABLE IF NOT EXISTS competition_participants (
    competition_id INTEGER REFERENCES competitions(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    games_played INTEGER DEFAULT 0,
    best_score INTEGER DEFAULT 0,
    total_score BIGINT DEFAULT 0,
    joined_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (competition_id, user_id)
);

-- Competition results
CREATE TABLE IF NOT EXISTS competition_results (
    id SERIAL PRIMARY KEY,
    competition_id INTEGER REFERENCES competitions(id) ON DELETE CASCADE,
    user_id BIGINT REFERENCES users(user_id) ON DELETE CASCADE,
    position INTEGER NOT NULL,
    final_score INTEGER NOT NULL,
    games_played INTEGER NOT NULL,
    awarded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- AI chat history
CREATE TABLE IF NOT EXISTS chat_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    model VARCHAR(100) NOT NULL,
    role VARCHAR(20) NOT NULL,
    content TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_chat_history_user ON chat_history(user_id);
CREATE INDEX idx_chat_history_timestamp ON chat_history(timestamp DESC);

-- AI model usage stats
CREATE TABLE IF NOT EXISTS model_usage (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    model VARCHAR(100) NOT NULL,
    messages_sent INTEGER DEFAULT 0,
    total_tokens BIGINT DEFAULT 0,
    last_used TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_model_usage_user ON model_usage(user_id);

-- Tracker scan history
CREATE TABLE IF NOT EXISTS scan_history (
    id SERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    wallet_address VARCHAR(42) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    total_transactions INTEGER DEFAULT 0,
    token_transfers INTEGER DEFAULT 0,
    nft_transfers INTEGER DEFAULT 0,
    unique_tokens INTEGER DEFAULT 0,
    export_formats JSONB,
    scan_duration INTEGER, -- seconds
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_scan_history_user ON scan_history(user_id);
CREATE INDEX idx_scan_history_wallet ON scan_history(wallet_address);

-- Discovered tokens cache
CREATE TABLE IF NOT EXISTS token_cache (
    address VARCHAR(42) PRIMARY KEY,
    symbol VARCHAR(50),
    name VARCHAR(255),
    decimals INTEGER,
    total_supply VARCHAR(100),
    metadata JSONB,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Router/DEX cache
CREATE TABLE IF NOT EXISTS router_cache (
    address VARCHAR(42) PRIMARY KEY,
    name VARCHAR(255),
    type VARCHAR(50), -- 'dex', 'bridge', 'aggregator'
    version VARCHAR(20),
    metadata JSONB,
    discovered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Bot statistics
CREATE TABLE IF NOT EXISTS bot_statistics (
    id SERIAL PRIMARY KEY,
    stat_date DATE NOT NULL UNIQUE,
    total_users INTEGER DEFAULT 0,
    active_users INTEGER DEFAULT 0,
    new_users INTEGER DEFAULT 0,
    total_games INTEGER DEFAULT 0,
    total_scans INTEGER DEFAULT 0,
    total_ai_messages INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_bot_statistics_date ON bot_statistics(stat_date DESC);

-- Error logs
CREATE TABLE IF NOT EXISTS error_logs (
    id SERIAL PRIMARY KEY,
    user_id BIGINT REFERENCES users(user_id),
    error_type VARCHAR(100),
    error_message TEXT,
    context JSONB,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_error_logs_timestamp ON error_logs(timestamp DESC);
CREATE INDEX idx_error_logs_type ON error_logs(error_type);

-- Functions for updating timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
CREATE TRIGGER update_user_settings_updated_at BEFORE UPDATE ON user_settings
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_game_states_updated_at BEFORE UPDATE ON game_states
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_player_stats_updated_at BEFORE UPDATE ON player_stats
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_token_cache_updated_at BEFORE UPDATE ON token_cache
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Views for easier querying
CREATE OR REPLACE VIEW v_active_games AS
SELECT 
    gs.user_id,
    gs.username,
    (gs.state_data->>'day')::int as current_day,
    (gs.state_data->>'cash')::int as cash,
    (gs.state_data->>'debt')::int as debt,
    gs.state_data->>'current_location' as location,
    gs.created_at,
    gs.updated_at
FROM game_states gs
WHERE gs.is_active = true;

CREATE OR REPLACE VIEW v_top_players AS
SELECT 
    u.user_id,
    u.username,
    ps.games_played,
    ps.high_score,
    ps.total_score,
    CASE 
        WHEN ps.games_played > 0 THEN ps.total_score / ps.games_played 
        ELSE 0 
    END as avg_score,
    ps.perfect_games,
    ps.survivor_games
FROM users u
JOIN player_stats ps ON u.user_id = ps.user_id
ORDER BY ps.high_score DESC;

-- Initial data
INSERT INTO bot_statistics (stat_date, total_users, active_users, new_users)
VALUES (CURRENT_DATE, 0, 0, 0)
ON CONFLICT (stat_date) DO NOTHING;