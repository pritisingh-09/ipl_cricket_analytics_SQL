import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import numpy as np

# Page configuration
st.set_page_config(
    page_title="IPL Cricket Analytics Dashboard",
    page_icon="🏏",
    layout="wide",
    initial_sidebar_state="expanded"
)

# Custom CSS
st.markdown("""
<style>
    .main-header {
        font-size: 3rem;
        color: #1f77b4;
        text-align: center;
        margin-bottom: 2rem;
    }
    .metric-card {
        background-color: #f0f2f6;
        padding: 1rem;
        border-radius: 0.5rem;
        border-left: 5px solid #1f77b4;
    }
    .insight-box {
        background-color: #e8f4f8;
        padding: 1rem;
        border-radius: 0.5rem;
        margin: 1rem 0;
    }
</style>
""", unsafe_allow_html=True)

# Load data
@st.cache_data
def load_data():
    try:
        matches = pd.read_csv('data/matches.csv')
        deliveries = pd.read_csv('data/deliveries.csv')
        matches['date'] = pd.to_datetime(matches['date'])
        return matches, deliveries
    except FileNotFoundError:
        st.error("Data files not found. Please ensure matches.csv and deliveries.csv are in the same directory.")
        return None, None

matches, deliveries = load_data()

if matches is None or deliveries is None:
    st.stop()

# Create is_wicket column
deliveries['is_wicket'] = deliveries['player_dismissed'].notna().astype(int)

# Main title
st.markdown('<h1 class="main-header">🏏 IPL Cricket Analytics Dashboard</h1>', unsafe_allow_html=True)

# Sidebar filters
st.sidebar.header("📊 Filter Options")
selected_seasons = st.sidebar.multiselect(
    "Select Seasons",
    options=sorted(matches['season'].unique()),
    default=sorted(matches['season'].unique())
)

selected_teams = st.sidebar.multiselect(
    "Select Teams",
    options=sorted(matches['team1'].unique()),
    default=sorted(matches['team1'].unique())
)

selected_venues = st.sidebar.multiselect(
    "Select Venues",
    options=sorted(matches['venue'].unique()),
    default=sorted(matches['venue'].unique())[:5]
)

# Filter data
filtered_matches = matches[
    (matches['season'].isin(selected_seasons)) &
    ((matches['team1'].isin(selected_teams)) | (matches['team2'].isin(selected_teams))) &
    (matches['venue'].isin(selected_venues))
]

filtered_deliveries = deliveries[deliveries['match_id'].isin(filtered_matches['match_id'])].copy()
filtered_deliveries['is_wicket'] = filtered_deliveries['player_dismissed'].notna().astype(int)

# Key Metrics
st.header("📈 Key Performance Indicators")
col1, col2, col3, col4 = st.columns(4)

with col1:
    st.markdown('<div class="metric-card">', unsafe_allow_html=True)
    st.metric("Total Matches", len(filtered_matches))
    st.markdown('</div>', unsafe_allow_html=True)

with col2:
    st.markdown('<div class="metric-card">', unsafe_allow_html=True)
    st.metric("Total Balls", f"{len(filtered_deliveries):,}")
    st.markdown('</div>', unsafe_allow_html=True)

with col3:
    st.markdown('<div class="metric-card">', unsafe_allow_html=True)
    st.metric("Total Runs", f"{filtered_deliveries['total_runs'].sum():,}")
    st.markdown('</div>', unsafe_allow_html=True)

with col4:
    st.markdown('<div class="metric-card">', unsafe_allow_html=True)
    st.metric("Total Wickets", filtered_deliveries['is_wicket'].sum())
    st.markdown('</div>', unsafe_allow_html=True)

# Tabs
tab1, tab2, tab3, tab4 = st.tabs(["🏆 Team Performance", "👤 Player Analysis", "🏟️ Venue Insights", "📊 Advanced Analytics"])

with tab1:
    st.subheader("Team Performance Analysis")
    col1, col2 = st.columns(2)

    with col1:
        team_wins = filtered_matches.groupby('winner').size().reset_index(name='wins')
        total_matches_per_team = [
            len(filtered_matches[(filtered_matches['team1'] == team) | (filtered_matches['team2'] == team)])
            for team in team_wins['winner']
        ]
        team_wins['total_matches'] = total_matches_per_team
        team_wins['win_percentage'] = (team_wins['wins'] / team_wins['total_matches'] * 100).round(1)
        team_wins = team_wins.sort_values('win_percentage', ascending=False)

        fig_wins = px.bar(team_wins, x='winner', y='win_percentage', color='win_percentage', title="Team Win Percentage", color_continuous_scale='viridis')
        fig_wins.update_xaxes(tickangle=45)
        st.plotly_chart(fig_wins, use_container_width=True)

    with col2:
        toss_impact = filtered_matches.groupby(['toss_winner', 'winner']).size().reset_index(name='count')
        toss_wins = toss_impact[toss_impact['toss_winner'] == toss_impact['winner']]
        toss_total = filtered_matches['toss_winner'].value_counts()
        toss_win_rate = [(toss_wins[toss_wins['toss_winner'] == team]['count'].sum() / toss_total[team]) * 100 if toss_total[team] > 0 else 0 for team in toss_total.index]
        toss_df = pd.DataFrame({'team': toss_total.index, 'toss_win_rate': toss_win_rate})

        fig_toss = px.bar(toss_df, x='team', y='toss_win_rate', color='toss_win_rate', title="Win Rate After Winning Toss", color_continuous_scale='plasma')
        fig_toss.update_xaxes(tickangle=45)
        st.plotly_chart(fig_toss, use_container_width=True)

with tab2:
    st.subheader("Player Performance Analysis")
    col1, col2 = st.columns(2)

    with col1:
        batsman_stats = filtered_deliveries.groupby('batsman').agg({
            'batsman_runs': 'sum',
            'match_id': 'nunique',
            'ball': 'count'
        }).reset_index()
        batsman_stats.columns = ['batsman', 'total_runs', 'matches', 'balls_faced']
        batsman_stats['strike_rate'] = (batsman_stats['total_runs'] / batsman_stats['balls_faced'] * 100).round(2)
        batsman_stats = batsman_stats[batsman_stats['balls_faced'] >= 50]
        top_scorers = batsman_stats.nlargest(10, 'total_runs')

        fig_runs = px.bar(top_scorers, x='batsman', y='total_runs', title="Top 10 Run Scorers", color='strike_rate', color_continuous_scale='reds')
        fig_runs.update_xaxes(tickangle=45)
        st.plotly_chart(fig_runs, use_container_width=True)

    with col2:
        bowler_stats = filtered_deliveries.groupby('bowler').agg({
            'is_wicket': 'sum',
            'total_runs': 'sum',
            'match_id': 'nunique'
        }).reset_index()
        bowler_stats.columns = ['bowler', 'wickets', 'runs_conceded', 'matches']
        bowler_stats['economy'] = (bowler_stats['runs_conceded'] / (bowler_stats['matches'] * 24)).round(2)
        bowler_stats = bowler_stats[bowler_stats['wickets'] >= 5]
        top_bowlers = bowler_stats.nlargest(10, 'wickets')

        fig_wickets = px.bar(top_bowlers, x='bowler', y='wickets', title="Top 10 Wicket Takers", color='economy', color_continuous_scale='blues_r')
        fig_wickets.update_xaxes(tickangle=45)
        st.plotly_chart(fig_wickets, use_container_width=True)

with tab3:
    st.subheader("Venue Analysis")
    col1, col2 = st.columns(2)

    with col1:
        venue_stats = filtered_matches.merge(
            filtered_deliveries.groupby('match_id')['total_runs'].sum().reset_index(),
            left_on='match_id', right_on='match_id'
        )
        venue_runs = venue_stats.groupby('venue')['total_runs'].mean().reset_index().sort_values('total_runs', ascending=False)

        fig_venue = px.bar(venue_runs, x='venue', y='total_runs', title="Average Runs per Match by Venue", color='total_runs', color_continuous_scale='viridis')
        fig_venue.update_xaxes(tickangle=45)
        st.plotly_chart(fig_venue, use_container_width=True)

    with col2:
        toss_decision_venue = filtered_matches.groupby(['venue', 'toss_decision']).size().unstack(fill_value=0)
        toss_decision_venue['bat_percentage'] = (toss_decision_venue['bat'] / (toss_decision_venue['bat'] + toss_decision_venue['field']) * 100).round(1)

        fig_toss_venue = px.bar(toss_decision_venue.reset_index(), x='venue', y='bat_percentage', title="Teams Choosing to Bat First", color='bat_percentage', color_continuous_scale='plasma')
        fig_toss_venue.update_xaxes(tickangle=45)
        st.plotly_chart(fig_toss_venue, use_container_width=True)

with tab4:
    st.subheader("Advanced Analytics")
    col1, col2 = st.columns(2)

    with col1:
        filtered_deliveries['phase'] = filtered_deliveries['over'].apply(
            lambda x: 'Powerplay (1-6)' if x <= 6 else 'Middle (7-15)' if x <= 15 else 'Death (16-20)'
        )
        phase_stats = filtered_deliveries.groupby('phase').agg({
            'total_runs': 'sum',
            'is_wicket': 'sum'
        }).reset_index()
        phase_stats['balls'] = filtered_deliveries.groupby('phase').size().values
        phase_stats['run_rate'] = (phase_stats['total_runs'] / phase_stats['balls'] * 6).round(2)

        fig_phase = px.bar(phase_stats, x='phase', y='run_rate', title="Run Rate by Match Phase", color='run_rate', color_continuous_scale='reds')
        st.plotly_chart(fig_phase, use_container_width=True)

    with col2:
        dismissal_stats = filtered_deliveries[filtered_deliveries['is_wicket'] == 1]['dismissal_kind'].value_counts()

        fig_dismissal = px.pie(values=dismissal_stats.values, names=dismissal_stats.index, title="Dismissal Types")
        st.plotly_chart(fig_dismissal, use_container_width=True)

# Insights
st.header("🎯 Key Business Insights")

st.markdown("""
**Strategic Recommendations Based on Data Analysis:**

1. **Toss Strategy**: Toss winners have a slight advantage, especially at certain venues.
2. **Venue Impact**: Some stadiums are clearly more batting-friendly.
3. **Player Impact**: High strike rates and lower economy rates correlate with winning.
4. **Game Phases**: Death overs are the most expensive – plan bowling accordingly.
5. **Balanced Teams**: Success depends on consistent performers across all roles.
""")
st.markdown('</div>', unsafe_allow_html=True)

# Footer
st.markdown("---")
st.markdown("**📊 Built with:** Python, Streamlit, Plotly | **🎯 Project:** Advanced SQL Analytics Portfolio")
