# IPL Cricket Analytics - SQL Project

## 🏏 Project Overview

This project demonstrates advanced SQL analytics capabilities using Indian Premier League (IPL) cricket data. It showcases comprehensive data analysis skills essential for business and data analyst roles, focusing on player performance, team strategies, venue insights, and match outcome predictions.

## 📊 Dataset Description

The project uses two main datasets:
- **matches.csv** (370 records): Match-level information including teams, venues, results, and outcomes
- **deliveries.csv** (10,097 records): Ball-by-ball data with player actions, runs, wickets, and dismissals

## 🎯 Business Questions Answered

1. **Player Performance**: Who are the most consistent batsmen and economical bowlers?
2. **Team Strategy**: Which teams perform best under pressure and at specific venues?
3. **Venue Analysis**: What are the characteristics of high-scoring vs low-scoring grounds?
4. **Toss Impact**: How much does winning the toss influence match outcomes?
5. **Market Insights**: Which players and teams provide the best entertainment value?

## 📁 Project Structure

```
ipl-sql-project/
├── README.md                    # This file
├── data/
│   ├── matches.csv             # Match results and details
│   └── deliveries.csv          # Ball-by-ball data
├── sql/
│   ├── 01_schema_setup.sql     # Database schema and data loading
│   ├── 02_player_analysis.sql  # Batting and bowling performance metrics
│   ├── 03_team_performance.sql # Team win-loss records and head-to-head
│   ├── 04_venue_analysis.sql   # Venue characteristics and advanced KPIs
│   └── 05_advanced_kpis.sql    # Complex analytics and insights
└── IPL-Cricket-SQL-Project.md  # Detailed business insights report
```

## 🚀 Quick Start

### Prerequisites
- PostgreSQL, MySQL, or SQLite
- Basic SQL knowledge
- CSV file import capability

### Setup Instructions

1. **Clone or Download** this project folder
2. **Create Database**:
   ```sql
   CREATE DATABASE ipl_analytics;
   USE ipl_analytics;
   ```

3. **Run Schema Setup**:
   ```bash
   # Execute the schema setup script
   psql -d ipl_analytics -f sql/01_schema_setup.sql
   ```

4. **Load Data**:
   - Modify file paths in `01_schema_setup.sql`
   - Load `matches.csv` and `deliveries.csv` using your preferred method

5. **Run Analysis Queries**:
   - Execute SQL files in order (02, 03, 04, 05)
   - Each file contains multiple analytical queries with business insights

## 📈 Key Analytics & Insights

### Player Performance Metrics
- **Strike Rate Analysis**: Identifies aggressive vs defensive batsmen
- **Bowling Economy**: Reveals most economical bowlers in different match phases
- **Consistency Index**: Uses coefficient of variation to find reliable performers
- **All-rounder Identification**: Classifies players based on batting and bowling contributions

### Team Strategic Analysis
- **Win-Loss Patterns**: Season-wise performance trends and improvement metrics
- **Toss Strategy**: Effectiveness of batting vs fielding first decisions
- **Head-to-Head Records**: Historical performance between team pairs
- **Venue Advantage**: Home ground performance and travel impact

### Venue Intelligence
- **Scoring Patterns**: High-scoring vs bowler-friendly venues
- **Powerplay Analysis**: First 6 overs performance by ground
- **Death Over Trends**: Last 5 overs scoring patterns and pressure situations
- **Win Probability**: Factors influencing match outcomes at different venues

## 🔧 Technical Highlights

### Advanced SQL Techniques Used
- **Window Functions**: ROW_NUMBER(), RANK(), LAG(), LEAD()
- **CTEs (Common Table Expressions)**: Complex multi-step analysis
- **Conditional Aggregation**: CASE WHEN statements for metric calculations
- **Subqueries & Joins**: Multi-table analysis and data correlation
- **Statistical Functions**: PERCENTILE, STDDEV, correlation analysis

### Performance Optimization
- Strategic indexing on frequently queried columns
- Efficient JOIN strategies for large datasets
- Query optimization for complex analytical operations

## 📋 Sample Queries & Results

### Top Run Scorers with Strike Rate
```sql
SELECT batsman, SUM(batsman_runs) as total_runs,
       ROUND((SUM(batsman_runs) * 100.0) / COUNT(*), 2) as strike_rate
FROM deliveries 
GROUP BY batsman
HAVING COUNT(*) >= 50
ORDER BY total_runs DESC;
```

### Venue Batting vs Bowling Advantage
```sql
SELECT venue, 
       COUNT(CASE WHEN result = 'runs' THEN 1 END) * 100.0 / COUNT(*) as bat_first_win_pct
FROM matches
GROUP BY venue
HAVING COUNT(*) >= 5;
```

## 💼 Business Value

This project demonstrates:
- **Data-Driven Decision Making**: Using analytics to inform cricket strategy
- **KPI Development**: Creating meaningful metrics for performance evaluation
- **Trend Analysis**: Identifying patterns in player and team performance
- **Predictive Insights**: Using historical data to forecast outcomes
- **Stakeholder Communication**: Translating complex data into business insights

## 🎓 Skills Demonstrated

- **SQL Mastery**: Complex queries, optimization, and database design
- **Statistical Analysis**: Variance, correlation, and trend analysis
- **Business Intelligence**: KPI creation and performance measurement
- **Data Storytelling**: Converting numbers into actionable insights
- **Sports Analytics**: Domain-specific knowledge application

## 📊 Visualization Opportunities

While this project focuses on SQL analysis, the results can be easily integrated with:
- **Tableau/Power BI**: For interactive dashboards
- **Python/R**: For advanced statistical modeling
- **Excel**: For quick charts and stakeholder presentations

## 🔄 Next Steps & Extensions

Potential enhancements:
1. **Player Market Value Prediction**: Using performance metrics to estimate player worth
2. **Team Composition Optimization**: Analyzing ideal team combinations
3. **Match Outcome Prediction**: Machine learning models based on SQL features
4. **Fan Engagement Analysis**: Correlating performance with viewership data

## 📞 Contact & Portfolio

This project is part of a data analytics portfolio demonstrating SQL expertise for business and data analyst positions. The analysis provides actionable insights for cricket team management, broadcasting companies, and sports betting organizations.

**Key Takeaway**: Cricket isn't just about individual brilliance—it's about understanding data patterns, venue characteristics, and strategic decision-making that can be measured and optimized through advanced SQL analytics.

---

*Created as part of a data analytics portfolio showcasing SQL skills for business intelligence and sports analytics applications.*