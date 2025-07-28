-- IPL Cricket Analytics Database Schema Setup
-- This script creates tables and loads sample data for IPL analysis

-- Create database (uncomment if using PostgreSQL/MySQL)
-- CREATE DATABASE ipl_analytics;
-- USE ipl_analytics;

-- =============================================
-- MATCHES TABLE
-- =============================================
DROP TABLE IF EXISTS matches;

CREATE TABLE matches (
    match_id INTEGER PRIMARY KEY,
    season INTEGER NOT NULL,
    city VARCHAR(50),
    match_date DATE,
    team1 VARCHAR(50) NOT NULL,
    team2 VARCHAR(50) NOT NULL,
    toss_winner VARCHAR(50),
    toss_decision VARCHAR(10),
    result VARCHAR(20),
    result_margin INTEGER,
    winner VARCHAR(50),
    venue VARCHAR(100),
    player_of_match VARCHAR(50)
);

-- =============================================
-- DELIVERIES TABLE (Ball-by-ball data)
-- =============================================
DROP TABLE IF EXISTS deliveries;

CREATE TABLE deliveries (
    delivery_id INTEGER PRIMARY KEY,
    match_id INTEGER,
    inning INTEGER,
    batting_team VARCHAR(50),
    bowling_team VARCHAR(50),
    over_number INTEGER,
    ball INTEGER,
    batsman VARCHAR(50),
    non_striker VARCHAR(50),
    bowler VARCHAR(50),
    batsman_runs INTEGER,
    extra_runs INTEGER,
    total_runs INTEGER,
    player_dismissed VARCHAR(50),
    dismissal_kind VARCHAR(20),
    fielder VARCHAR(50),
    extras_type VARCHAR(15),
    FOREIGN KEY (match_id) REFERENCES matches(match_id)
);

-- =============================================
-- CREATE INDEXES FOR PERFORMANCE
-- =============================================

-- Indexes on matches table
CREATE INDEX idx_matches_season ON matches(season);
CREATE INDEX idx_matches_winner ON matches(winner);
CREATE INDEX idx_matches_venue ON matches(venue);
CREATE INDEX idx_matches_date ON matches(match_date);

-- Indexes on deliveries table
CREATE INDEX idx_deliveries_match_id ON deliveries(match_id);
CREATE INDEX idx_deliveries_batting_team ON deliveries(batting_team);
CREATE INDEX idx_deliveries_bowler ON deliveries(bowler);
CREATE INDEX idx_deliveries_batsman ON deliveries(batsman);
CREATE INDEX idx_deliveries_over ON deliveries(over_number);

-- =============================================
-- LOAD DATA (Modify paths as needed)
-- =============================================

-- For PostgreSQL:
-- COPY matches FROM '/path/to/matches.csv' DELIMITER ',' CSV HEADER;
-- COPY deliveries FROM '/path/to/deliveries.csv' DELIMITER ',' CSV HEADER;

-- For MySQL:
-- LOAD DATA INFILE '/path/to/matches.csv' 
-- INTO TABLE matches 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n' 
-- IGNORE 1 ROWS;

-- LOAD DATA INFILE '/path/to/deliveries.csv' 
-- INTO TABLE deliveries 
-- FIELDS TERMINATED BY ',' 
-- ENCLOSED BY '"' 
-- LINES TERMINATED BY '\n' 
-- IGNORE 1 ROWS;

-- =============================================
-- DATA VALIDATION QUERIES
-- =============================================

-- Check total records loaded
SELECT 'matches' as table_name, COUNT(*) as record_count FROM matches
UNION ALL
SELECT 'deliveries' as table_name, COUNT(*) as record_count FROM deliveries;

-- Check data quality
SELECT 
    season,
    COUNT(*) as matches_count,
    COUNT(DISTINCT winner) as unique_winners
FROM matches 
GROUP BY season 
ORDER BY season;

-- Verify foreign key relationships
SELECT 
    COUNT(*) as deliveries_count,
    COUNT(DISTINCT match_id) as unique_matches_in_deliveries
FROM deliveries;

SELECT 'Schema setup completed successfully!' as status;
