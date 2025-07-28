-- IPL Venue Analysis & Advanced KPIs
-- Strategic insights into venue characteristics, match outcomes, and advanced performance metrics

-- =============================================
-- VENUE CHARACTERISTICS ANALYSIS
-- =============================================

-- Venue scoring patterns and match outcomes
SELECT 
    venue,
    city,
    COUNT(*) as total_matches,
    COUNT(CASE WHEN result = 'runs' THEN 1 END) as matches_won_by_runs,
    COUNT(CASE WHEN result = 'wickets' THEN 1 END) as matches_won_by_wickets,
    ROUND(
        (COUNT(CASE WHEN result = 'runs' THEN 1 END) * 100.0) / 
        NULLIF(COUNT(CASE WHEN result IN ('runs', 'wickets') THEN 1 END), 0), 2
    ) as batting_first_win_pct,
    AVG(CASE WHEN result = 'runs' THEN result_margin END) as avg_runs_margin,
    AVG(CASE WHEN result = 'wickets' THEN result_margin END) as avg_wickets_margin
FROM matches
WHERE result IN ('runs', 'wickets')
GROUP BY venue, city
HAVING COUNT(*) >= 5
ORDER BY batting_first_win_pct DESC;

-- High scoring vs low scoring venues
WITH venue_scores AS (
    SELECT 
        m.venue,
        m.match_id,
        SUM(d.batsman_runs) as total_match_runs,
        COUNT(CASE WHEN d.player_dismissed IS NOT NULL THEN 1 END) as total_wickets
    FROM matches m
    JOIN deliveries d ON m.match_id = d.match_id
    GROUP BY m.venue, m.match_id
)
SELECT 
    venue,
    COUNT(*) as matches_analyzed,
    ROUND(AVG(total_match_runs), 2) as avg_runs_per_match,
    ROUND(AVG(total_wickets), 2) as avg_wickets_per_match,
    MAX(total_match_runs) as highest_match_total,
    MIN(total_match_runs) as lowest_match_total,
    CASE 
        WHEN AVG(total_match_runs) >= 340 THEN 'High Scoring'
        WHEN AVG(total_match_runs) >= 300 THEN 'Medium Scoring'
        ELSE 'Low Scoring'
    END as venue_type
FROM venue_scores
GROUP BY venue
HAVING COUNT(*) >= 3
ORDER BY avg_runs_per_match DESC;

-- Toss impact by venue (bat vs field advantage)
SELECT 
    venue,
    COUNT(*) as total_matches,
    
    -- Toss decision breakdown
    COUNT(CASE WHEN toss_decision = 'bat' THEN 1 END) as chose_to_bat,
    COUNT(CASE WHEN toss_decision = 'field' THEN 1 END) as chose_to_field,
    
    -- Win rates by toss decision
    ROUND(
        (COUNT(CASE WHEN toss_decision = 'bat' AND winner = toss_winner THEN 1 END) * 100.0) /
        NULLIF(COUNT(CASE WHEN toss_decision = 'bat' THEN 1 END), 0), 2
    ) as bat_first_success_rate,
    
    ROUND(
        (COUNT(CASE WHEN toss_decision = 'field' AND winner = toss_winner THEN 1 END) * 100.0) /
        NULLIF(COUNT(CASE WHEN toss_decision = 'field' THEN 1 END), 0), 2
    ) as field_first_success_rate,
    
    -- Venue recommendation
    CASE 
        WHEN (COUNT(CASE WHEN toss_decision = 'bat' AND winner = toss_winner THEN 1 END) * 100.0) /
             NULLIF(COUNT(CASE WHEN toss_decision = 'bat' THEN 1 END), 0) > 55
        THEN 'Bat First Venue'
        WHEN (COUNT(CASE WHEN toss_decision = 'field' AND winner = toss_winner THEN 1 END) * 100.0) /
             NULLIF(COUNT(CASE WHEN toss_decision = 'field' THEN 1 END), 0) > 55
        THEN 'Field First Venue'
        ELSE 'Balanced Venue'
    END as venue_strategy
FROM matches
WHERE toss_winner IS NOT NULL AND winner IS NOT NULL
GROUP BY venue
HAVING COUNT(*) >= 5
ORDER BY bat_first_success_rate DESC;

-- =============================================
-- POWERPLAY & DEATH OVER ANALYSIS BY VENUE
-- =============================================

-- Venue-wise powerplay scoring (overs 1-6)
WITH powerplay_scores AS (
    SELECT 
        m.venue,
        d.match_id,
        d.batting_team,
        SUM(d.batsman_runs) as powerplay_runs,
        COUNT(CASE WHEN d.player_dismissed IS NOT NULL THEN 1 END) as powerplay_wickets
    FROM matches m
    JOIN deliveries d ON m.match_id = d.match_id
    WHERE d.over_number BETWEEN 1 AND 6
    GROUP BY m.venue, d.match_id, d.batting_team
)
SELECT 
    venue,
    COUNT(*) as innings_analyzed,
    ROUND(AVG(powerplay_runs), 2) as avg_powerplay_runs,
    ROUND(AVG(powerplay_wickets), 2) as avg_powerplay_wickets,
    MAX(powerplay_runs) as highest_powerplay_score,
    MIN(powerplay_runs) as lowest_powerplay_score,
    CASE 
        WHEN AVG(powerplay_runs) >= 55 THEN 'Batting Paradise'
        WHEN AVG(powerplay_runs) >= 45 THEN 'Balanced'
        ELSE 'Bowler Friendly'
    END as powerplay_nature
FROM powerplay_scores
GROUP BY venue
HAVING COUNT(*) >= 6
ORDER BY avg_powerplay_runs DESC;

-- Death over analysis by venue (overs 16-20)
WITH death_over_scores AS (
    SELECT 
        m.venue,
        d.match_id,
        d.batting_team,
        SUM(d.batsman_runs) as death_over_runs,
        COUNT(CASE WHEN d.batsman_runs >= 4 THEN 1 END) as boundaries_in_death,
        COUNT(CASE WHEN d.player_dismissed IS NOT NULL THEN 1 END) as death_over_wickets
    FROM matches m
    JOIN deliveries d ON m.match_id = d.match_id
    WHERE d.over_number BETWEEN 16 AND 20
    GROUP BY m.venue, d.match_id, d.batting_team
)
SELECT 
    venue,
    COUNT(*) as innings_analyzed,
    ROUND(AVG(death_over_runs), 2) as avg_death_over_runs,
    ROUND(AVG(boundaries_in_death), 2) as avg_boundaries_in_death,
    ROUND(AVG(death_over_wickets), 2) as avg_death_over_wickets,
    MAX(death_over_runs) as highest_death_over_total,
    CASE 
        WHEN AVG(death_over_runs) >= 65 THEN 'High Scoring Death Overs'
        WHEN AVG(death_over_runs) >= 50 THEN 'Moderate Scoring'
        ELSE 'Tough for Batsmen'
    END as death_over_character
FROM death_over_scores
GROUP BY venue
HAVING COUNT(*) >= 6
ORDER BY avg_death_over_runs DESC;

-- =============================================
-- ADVANCED KPIs AND METRICS
-- =============================================

-- Win Probability Index by venue (combining multiple factors)
WITH venue_factors AS (
    SELECT 
        venue,
        COUNT(*) as total_matches,
        
        -- Batting first advantage
        ROUND(
            (COUNT(CASE WHEN result = 'runs' THEN 1 END) * 100.0) / 
            NULLIF(COUNT(CASE WHEN result IN ('runs', 'wickets') THEN 1 END), 0), 2
        ) as batting_first_win_pct,
        
        -- Average match runs
        AVG(
            (SELECT SUM(batsman_runs) 
             FROM deliveries d 
             WHERE d.match_id = m.match_id)
        ) as avg_match_runs,
        
        -- Close match percentage (decided by ≤10 runs or ≤2 wickets)
        ROUND(
            (COUNT(CASE WHEN (result = 'runs' AND result_margin <= 10) OR 
                            (result = 'wickets' AND result_margin <= 2) THEN 1 END) * 100.0) / 
            COUNT(*), 2
        ) as close_match_percentage
        
    FROM matches m
    WHERE result IN ('runs', 'wickets')
    GROUP BY venue
    HAVING COUNT(*) >= 5
)
SELECT 
    venue,
    total_matches,
    batting_first_win_pct,
    ROUND(avg_match_runs, 2) as avg_match_runs,
    close_match_percentage,
    
    -- Composite venue rating (0-100 scale)
    ROUND(
        (batting_first_win_pct * 0.3) + 
        (LEAST(avg_match_runs / 4, 100) * 0.4) + 
        (close_match_percentage * 0.3), 2
    ) as venue_excitement_index,
    
    CASE 
        WHEN ROUND(
            (batting_first_win_pct * 0.3) + 
            (LEAST(avg_match_runs / 4, 100) * 0.4) + 
            (close_match_percentage * 0.3), 2
        ) >= 70 THEN 'Premium Entertainment Venue'
        WHEN ROUND(
            (batting_first_win_pct * 0.3) + 
            (LEAST(avg_match_runs / 4, 100) * 0.4) + 
            (close_match_percentage * 0.3), 2
        ) >= 55 THEN 'Good Entertainment Value'
        ELSE 'Standard Venue'
    END as venue_rating
FROM venue_factors
ORDER BY venue_excitement_index DESC;

-- Player of the Match distribution by venue
SELECT 
    venue,
    COUNT(*) as total_matches,
    COUNT(DISTINCT player_of_match) as unique_mom_winners,
    ROUND(
        COUNT(DISTINCT player_of_match) * 100.0 / COUNT(*), 2
    ) as mom_diversity_percentage,
    
    -- Most frequent MOM at this venue
    (SELECT player_of_match 
     FROM matches m2 
     WHERE m2.venue = m.venue AND m2.player_of_match IS NOT NULL
     GROUP BY player_of_match 
     ORDER BY COUNT(*) DESC 
     LIMIT 1) as most_frequent_mom,
     
    (SELECT COUNT(*) 
     FROM matches m2 
     WHERE m2.venue = m.venue 
       AND m2.player_of_match = (
           SELECT player_of_match 
           FROM matches m3 
           WHERE m3.venue = m.venue AND m3.player_of_match IS NOT NULL
           GROUP BY player_of_match 
           ORDER BY COUNT(*) DESC 
           LIMIT 1
       )) as mom_frequency
FROM matches m
WHERE player_of_match IS NOT NULL
GROUP BY venue
HAVING COUNT(*) >= 5
ORDER BY mom_diversity_percentage DESC;

-- Season-wise venue performance trends
SELECT 
    venue,
    season,
    COUNT(*) as matches_hosted,
    ROUND(AVG(
        (SELECT SUM(batsman_runs) FROM deliveries d WHERE d.match_id = m.match_id)
    ), 2) as avg_runs_per_match,
    COUNT(CASE WHEN result = 'runs' THEN 1 END) as batting_first_wins,
    COUNT(CASE WHEN result = 'wickets' THEN 1 END) as chasing_wins,
    
    -- Year-over-year comparison
    LAG(ROUND(AVG(
        (SELECT SUM(batsman_runs) FROM deliveries d WHERE d.match_id = m.match_id)
    ), 2)) OVER (PARTITION BY venue ORDER BY season) as previous_season_avg
FROM matches m
WHERE result IN ('runs', 'wickets')
GROUP BY venue, season
HAVING COUNT(*) >= 3
ORDER BY venue, season;
