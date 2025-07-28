-- IPL Team Performance Analysis
-- Strategic insights into team performance, winning patterns, and head-to-head records

-- =============================================
-- TEAM WIN-LOSS RECORDS BY SEASON
-- =============================================

-- Overall team performance across all seasons
WITH team_matches AS (
    SELECT 
        team,
        season,
        SUM(matches_played) as total_matches,
        SUM(wins) as total_wins,
        SUM(losses) as total_losses
    FROM (
        -- Count wins and losses for each team
        SELECT 
            team1 as team,
            season,
            COUNT(*) as matches_played,
            SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END) as wins,
            SUM(CASE WHEN winner IS NOT NULL AND winner != team1 THEN 1 ELSE 0 END) as losses
        FROM matches
        GROUP BY team1, season
        
        UNION ALL
        
        SELECT 
            team2 as team,
            season,
            COUNT(*) as matches_played,
            SUM(CASE WHEN winner = team2 THEN 1 ELSE 0 END) as wins,
            SUM(CASE WHEN winner IS NOT NULL AND winner != team2 THEN 1 ELSE 0 END) as losses
        FROM matches
        GROUP BY team2, season
    ) team_stats
    GROUP BY team, season
)
SELECT 
    team,
    season,
    total_matches,
    total_wins,
    total_losses,
    ROUND((total_wins * 100.0) / NULLIF(total_matches, 0), 2) as win_percentage,
    CASE 
        WHEN total_wins > total_losses THEN 'Winning Season'
        WHEN total_wins = total_losses THEN 'Break-even'
        ELSE 'Losing Season'
    END as season_performance
FROM team_matches
ORDER BY season DESC, win_percentage DESC;

-- Team performance trends (year-over-year improvement)
WITH yearly_performance AS (
    SELECT 
        team,
        season,
        ROUND((total_wins * 100.0) / NULLIF(total_matches, 0), 2) as win_percentage
    FROM (
        SELECT 
            team,
            season,
            SUM(matches_played) as total_matches,
            SUM(wins) as total_wins
        FROM (
            SELECT 
                team1 as team, season, COUNT(*) as matches_played,
                SUM(CASE WHEN winner = team1 THEN 1 ELSE 0 END) as wins
            FROM matches GROUP BY team1, season
            UNION ALL
            SELECT 
                team2 as team, season, COUNT(*) as matches_played,
                SUM(CASE WHEN winner = team2 THEN 1 ELSE 0 END) as wins
            FROM matches GROUP BY team2, season
        ) team_stats
        GROUP BY team, season
    ) performance_data
)
SELECT 
    current_year.team,
    current_year.season,
    current_year.win_percentage as current_win_pct,
    LAG(win_percentage) OVER (PARTITION BY team ORDER BY season) as previous_win_pct,
    ROUND(
        current_year.win_percentage - 
        LAG(win_percentage) OVER (PARTITION BY team ORDER BY season), 2
    ) as improvement_points
FROM yearly_performance current_year
ORDER BY current_year.team, current_year.season;

-- =============================================
-- TOSS IMPACT ANALYSIS
-- =============================================

-- Toss winning advantage by team
SELECT 
    toss_winner as team,
    COUNT(*) as toss_wins,
    SUM(CASE WHEN winner = toss_winner THEN 1 ELSE 0 END) as match_wins_after_toss_win,
    ROUND(
        (SUM(CASE WHEN winner = toss_winner THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
    ) as win_pct_after_winning_toss
FROM matches
WHERE toss_winner IS NOT NULL AND winner IS NOT NULL
GROUP BY toss_winner
HAVING COUNT(*) >= 10
ORDER BY win_pct_after_winning_toss DESC;

-- Bat vs Field decision effectiveness
SELECT 
    toss_decision,
    COUNT(*) as total_decisions,
    SUM(CASE WHEN winner = toss_winner THEN 1 ELSE 0 END) as wins_by_toss_winner,
    ROUND(
        (SUM(CASE WHEN winner = toss_winner THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
    ) as success_rate
FROM matches
WHERE toss_winner IS NOT NULL AND winner IS NOT NULL
GROUP BY toss_decision;

-- =============================================
-- HEAD-TO-HEAD RECORDS
-- =============================================

-- Team vs Team head-to-head performance
WITH head_to_head AS (
    SELECT 
        CASE WHEN team1 < team2 THEN team1 ELSE team2 END as team_a,
        CASE WHEN team1 < team2 THEN team2 ELSE team1 END as team_b,
        CASE WHEN team1 < team2 THEN winner ELSE 
             CASE WHEN winner = team1 THEN team2 
                  WHEN winner = team2 THEN team1 
                  ELSE winner END 
        END as normalized_winner
    FROM matches
    WHERE winner IS NOT NULL
)
SELECT 
    team_a,
    team_b,
    COUNT(*) as total_matches,
    SUM(CASE WHEN normalized_winner = team_a THEN 1 ELSE 0 END) as team_a_wins,
    SUM(CASE WHEN normalized_winner = team_b THEN 1 ELSE 0 END) as team_b_wins,
    CONCAT(
        team_a, ' leads ', 
        SUM(CASE WHEN normalized_winner = team_a THEN 1 ELSE 0 END),
        '-',
        SUM(CASE WHEN normalized_winner = team_b THEN 1 ELSE 0 END)
    ) as head_to_head_record
FROM head_to_head
GROUP BY team_a, team_b
HAVING COUNT(*) >= 5
ORDER BY total_matches DESC;

-- =============================================
-- BATTING AND BOWLING TEAM AVERAGES
-- =============================================

-- Team batting performance (runs per match, strike rate)
WITH team_batting AS (
    SELECT 
        batting_team,
        match_id,
        SUM(batsman_runs) as team_runs,
        COUNT(*) as balls_faced
    FROM deliveries
    GROUP BY batting_team, match_id
)
SELECT 
    batting_team as team,
    COUNT(*) as innings_batted,
    ROUND(AVG(team_runs), 2) as avg_runs_per_innings,
    ROUND(AVG((team_runs * 100.0) / balls_faced), 2) as team_strike_rate,
    MAX(team_runs) as highest_team_score,
    MIN(team_runs) as lowest_team_score
FROM team_batting
GROUP BY batting_team
ORDER BY avg_runs_per_innings DESC;

-- Team bowling performance (runs conceded, wickets per match)
WITH team_bowling AS (
    SELECT 
        bowling_team,
        match_id,
        SUM(total_runs) as runs_conceded,
        COUNT(CASE WHEN player_dismissed IS NOT NULL 
              AND dismissal_kind != 'run out' THEN 1 END) as wickets_taken,
        COUNT(*) as balls_bowled
    FROM deliveries
    GROUP BY bowling_team, match_id
)
SELECT 
    bowling_team as team,
    COUNT(*) as innings_bowled,
    ROUND(AVG(runs_conceded), 2) as avg_runs_conceded,
    ROUND(AVG(wickets_taken), 2) as avg_wickets_taken,
    ROUND(AVG(runs_conceded / NULLIF(balls_bowled / 6.0, 0)), 2) as team_economy_rate
FROM team_bowling
GROUP BY bowling_team
ORDER BY avg_runs_conceded ASC;

-- =============================================
-- VENUE PERFORMANCE
-- =============================================

-- Team performance at different venues
SELECT 
    team,
    venue,
    COUNT(*) as matches_played,
    SUM(CASE WHEN winner = team THEN 1 ELSE 0 END) as matches_won,
    ROUND(
        (SUM(CASE WHEN winner = team THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
    ) as win_percentage_at_venue
FROM (
    SELECT team1 as team, venue, winner FROM matches
    UNION ALL
    SELECT team2 as team, venue, winner FROM matches
) team_venue_matches
WHERE winner IS NOT NULL
GROUP BY team, venue
HAVING COUNT(*) >= 3
ORDER BY team, win_percentage_at_venue DESC;

-- Best and worst venues for each team
WITH venue_performance AS (
    SELECT 
        team,
        venue,
        COUNT(*) as matches_played,
        ROUND(
            (SUM(CASE WHEN winner = team THEN 1 ELSE 0 END) * 100.0) / COUNT(*), 2
        ) as win_percentage
    FROM (
        SELECT team1 as team, venue, winner FROM matches
        UNION ALL
        SELECT team2 as team, venue, winner FROM matches
    ) team_venue_matches
    WHERE winner IS NOT NULL
    GROUP BY team, venue
    HAVING COUNT(*) >= 3
),
ranked_venues AS (
    SELECT 
        team,
        venue,
        win_percentage,
        ROW_NUMBER() OVER (PARTITION BY team ORDER BY win_percentage DESC) as best_rank,
        ROW_NUMBER() OVER (PARTITION BY team ORDER BY win_percentage ASC) as worst_rank
    FROM venue_performance
)
SELECT 
    team,
    MAX(CASE WHEN best_rank = 1 THEN CONCAT(venue, ' (', win_percentage, '%)') END) as best_venue,
    MAX(CASE WHEN worst_rank = 1 THEN CONCAT(venue, ' (', win_percentage, '%)') END) as worst_venue
FROM ranked_venues
GROUP BY team
ORDER BY team;
