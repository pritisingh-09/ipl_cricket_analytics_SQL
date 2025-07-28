-- IPL Player Performance Analysis
-- Advanced SQL queries for player batting and bowling statistics

-- =============================================
-- BATTING PERFORMANCE ANALYSIS
-- =============================================

-- Top run scorers across all seasons
SELECT 
    batsman,
    COUNT(*) as balls_faced,
    SUM(batsman_runs) as total_runs,
    ROUND(AVG(CAST(batsman_runs AS DECIMAL)), 2) as avg_runs_per_ball,
    ROUND((SUM(batsman_runs) * 100.0) / COUNT(*), 2) as strike_rate,
    SUM(CASE WHEN batsman_runs = 4 THEN 1 ELSE 0 END) as fours,
    SUM(CASE WHEN batsman_runs = 6 THEN 1 ELSE 0 END) as sixes,
    COUNT(DISTINCT match_id) as matches_played
FROM deliveries 
WHERE batsman_runs >= 0
GROUP BY batsman
HAVING COUNT(*) >= 50  -- Minimum 50 balls faced
ORDER BY total_runs DESC
LIMIT 20;

-- Batting average by dismissal (excluding run outs)
WITH batting_stats AS (
    SELECT 
        batsman,
        COUNT(*) as innings_played,
        SUM(batsman_runs) as total_runs,
        COUNT(CASE WHEN player_dismissed = batsman 
              AND dismissal_kind NOT IN ('run out', 'retired hurt') 
              THEN 1 END) as dismissals
    FROM deliveries 
    GROUP BY batsman
    HAVING COUNT(*) >= 30
)
SELECT 
    batsman,
    total_runs,
    dismissals,
    CASE 
        WHEN dismissals > 0 THEN ROUND(total_runs::DECIMAL / dismissals, 2)
        ELSE total_runs 
    END as batting_average,
    innings_played
FROM batting_stats
ORDER BY batting_average DESC
LIMIT 15;

-- Most consistent batsmen (lowest coefficient of variation)
WITH batsman_match_scores AS (
    SELECT 
        batsman,
        match_id,
        SUM(batsman_runs) as match_runs
    FROM deliveries
    GROUP BY batsman, match_id
),
batsman_consistency AS (
    SELECT 
        batsman,
        COUNT(*) as matches,
        AVG(match_runs) as avg_runs_per_match,
        STDDEV(match_runs) as std_dev_runs
    FROM batsman_match_scores
    GROUP BY batsman
    HAVING COUNT(*) >= 10
)
SELECT 
    batsman,
    matches,
    ROUND(avg_runs_per_match, 2) as avg_runs_per_match,
    ROUND(std_dev_runs, 2) as std_deviation,
    ROUND((std_dev_runs / NULLIF(avg_runs_per_match, 0)) * 100, 2) as coefficient_of_variation
FROM batsman_consistency
WHERE std_dev_runs > 0
ORDER BY coefficient_of_variation ASC
LIMIT 10;

-- =============================================
-- BOWLING PERFORMANCE ANALYSIS
-- =============================================

-- Top wicket takers and bowling economy
SELECT 
    bowler,
    COUNT(*) as balls_bowled,
    ROUND(COUNT(*) / 6.0, 1) as overs_bowled,
    SUM(total_runs) as runs_conceded,
    COUNT(CASE WHEN player_dismissed IS NOT NULL 
          AND dismissal_kind != 'run out' THEN 1 END) as wickets_taken,
    ROUND(SUM(total_runs) / NULLIF(COUNT(*) / 6.0, 0), 2) as economy_rate,
    ROUND(COUNT(*) / NULLIF(COUNT(CASE WHEN player_dismissed IS NOT NULL 
          AND dismissal_kind != 'run out' THEN 1 END), 0), 2) as strike_rate_balls_per_wicket
FROM deliveries
WHERE extras_type != 'wides'  -- Exclude wide balls from overs calculation
GROUP BY bowler
HAVING COUNT(*) >= 60  -- Minimum 10 overs bowled
ORDER BY wickets_taken DESC, economy_rate ASC
LIMIT 20;

-- Death over specialists (overs 16-20)
SELECT 
    bowler,
    COUNT(*) as death_over_balls,
    SUM(total_runs) as death_over_runs,
    ROUND(SUM(total_runs) / NULLIF(COUNT(*) / 6.0, 0), 2) as death_over_economy,
    COUNT(CASE WHEN player_dismissed IS NOT NULL THEN 1 END) as death_over_wickets,
    COUNT(CASE WHEN batsman_runs >= 4 THEN 1 END) as boundaries_conceded
FROM deliveries
WHERE over_number BETWEEN 16 AND 20
GROUP BY bowler
HAVING COUNT(*) >= 30  -- Minimum 5 death overs bowled
ORDER BY death_over_economy ASC
LIMIT 15;

-- Powerplay bowling performance (overs 1-6)
SELECT 
    bowler,
    COUNT(*) as powerplay_balls,
    SUM(total_runs) as powerplay_runs,
    ROUND(SUM(total_runs) / NULLIF(COUNT(*) / 6.0, 0), 2) as powerplay_economy,
    COUNT(CASE WHEN player_dismissed IS NOT NULL THEN 1 END) as powerplay_wickets,
    SUM(CASE WHEN batsman_runs = 0 THEN 1 ELSE 0 END) as dot_balls
FROM deliveries
WHERE over_number BETWEEN 1 AND 6
GROUP BY bowler
HAVING COUNT(*) >= 30
ORDER BY powerplay_economy ASC
LIMIT 15;

-- =============================================
-- PLAYER VERSATILITY ANALYSIS
-- =============================================

-- All-rounders: Players who both bat and bowl significantly
WITH batting_summary AS (
    SELECT 
        batsman as player,
        SUM(batsman_runs) as batting_runs,
        COUNT(*) as batting_balls
    FROM deliveries
    GROUP BY batsman
),
bowling_summary AS (
    SELECT 
        bowler as player,
        COUNT(*) as bowling_balls,
        COUNT(CASE WHEN player_dismissed IS NOT NULL 
              AND dismissal_kind != 'run out' THEN 1 END) as bowling_wickets
    FROM deliveries
    GROUP BY bowler
)
SELECT 
    COALESCE(b.player, bo.player) as player,
    COALESCE(b.batting_runs, 0) as total_batting_runs,
    COALESCE(b.batting_balls, 0) as batting_balls_faced,
    COALESCE(bo.bowling_balls, 0) as bowling_balls_bowled,
    COALESCE(bo.bowling_wickets, 0) as bowling_wickets,
    CASE 
        WHEN b.batting_balls >= 50 AND bo.bowling_balls >= 60 
        THEN 'All-rounder'
        WHEN b.batting_balls >= 100 THEN 'Batsman'
        WHEN bo.bowling_balls >= 120 THEN 'Bowler'
        ELSE 'Occasional'
    END as player_type
FROM batting_summary b
FULL OUTER JOIN bowling_summary bo ON b.player = bo.player
WHERE (COALESCE(b.batting_balls, 0) >= 50 AND COALESCE(bo.bowling_balls, 0) >= 60)
ORDER BY (COALESCE(b.batting_runs, 0) + COALESCE(bo.bowling_wickets, 0) * 20) DESC;

-- Performance against specific teams
SELECT 
    batsman,
    bowling_team as opponent,
    COUNT(*) as balls_faced,
    SUM(batsman_runs) as runs_scored,
    ROUND((SUM(batsman_runs) * 100.0) / COUNT(*), 2) as strike_rate_vs_team
FROM deliveries
WHERE batsman IN (
    SELECT batsman 
    FROM deliveries 
    GROUP BY batsman 
    HAVING SUM(batsman_runs) >= 200
)
GROUP BY batsman, bowling_team
HAVING COUNT(*) >= 20
ORDER BY batsman, strike_rate_vs_team DESC;
