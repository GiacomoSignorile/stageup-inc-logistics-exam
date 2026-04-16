import streamlit as st
import db_utils
from app_config import APP_SUBTITLE, APP_TITLE
from ui_theme import apply_dashboard_theme, render_section_title, render_kpi


db_utils.ensure_session_state()
apply_dashboard_theme()

render_section_title(
    APP_TITLE,
    "A dashboard-style Oracle object-relational application for customers, bookings, teams, and operational reporting.",
)

col_left, col_right = st.columns([1.45, 0.85], gap="large")

with col_left:
    st.markdown('<div class="stageup-section-title">Overview</div>', unsafe_allow_html=True)
    overview_col1, overview_col2, overview_col3 = st.columns(3)
    with overview_col1:
        render_kpi("Core operations", "5")
    with overview_col2:
        render_kpi("Database modules", "8")
    with overview_col3:
        render_kpi("Trigger groups", "8")

    st.markdown(
        """
        <div class="stageup-card" style="margin-top: 1rem;">
            <p style="margin:0; font-size:1rem; line-height:1.6; color: rgba(30,39,50,0.8);">
                <strong>StageUp Inc.</strong> coordinates a decentralized installation network with a central office,
                depots, customers, event locations, teams, and bookings. The application is organized as a visual
                dashboard so the main data areas are immediately visible, just like a compact business control room.
            </p>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown('<div class="stageup-section-title" style="margin-top:1.2rem;">Quick Access</div>', unsafe_allow_html=True)
    q1, q2 = st.columns(2, gap="large")
    with q1:
        st.markdown(
            """
            <div class="stageup-card">
                <h3 style="margin-top:0;">Customer data</h3>
                <p style="margin-bottom:0; color: rgba(30,39,50,0.74);">
                    Register customers, manage locations, and inspect the customer activity trail.
                </p>
            </div>
            """,
            unsafe_allow_html=True,
        )
    with q2:
        st.markdown(
            """
            <div class="stageup-card">
                <h3 style="margin-top:0;">Booking operations</h3>
                <p style="margin-bottom:0; color: rgba(30,39,50,0.74);">
                    Create bookings, assign offices, and monitor team performance and deliveries.
                </p>
            </div>
            """,
            unsafe_allow_html=True,
        )

    st.markdown('<div class="stageup-section-title" style="margin-top:1.2rem;">5 Core Operations</div>', unsafe_allow_html=True)
    ops_data = [
        ("Operation 1", "Register New Customer", "10/day", "Customer and location onboarding"),
        ("Operation 2", "Record New Booking", "300/day", "Booking creation and team assignment"),
        ("Operation 3", "Register Event Location", "50/day", "Customer-owned location capture"),
        ("Operation 4", "View Team at Location", "20/day", "Operational drill-down and members"),
        ("Operation 5", "Location Activity Report", "5/day", "Ranking and reporting dashboard"),
    ]
    st.dataframe(
        [
            {
                "Op": row[0],
                "Screen": row[1],
                "Frequency": row[2],
                "Purpose": row[3],
            }
            for row in ops_data
        ],
        width="stretch",
        hide_index=True,
    )

with col_right:
    st.markdown('<div class="stageup-section-title">Connection</div>', unsafe_allow_html=True)
    if st.session_state.get("logged_in_user"):
        st.success(f"Logged in as: {st.session_state.logged_in_user}")
    else:
        st.warning("Please open Login in the sidebar.")

    if st.session_state.get("db_connected"):
        st.info("Database connection pool is active.")
    else:
        st.info("Database connection pool is inactive.")

    st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Trigger Summary</div>', unsafe_allow_html=True)
    st.markdown(
        """
        <div class="stageup-card">
            <ul style="margin:0; padding-left:1.1rem; color: rgba(30,39,50,0.8); line-height:1.8;">
                <li><strong>TrgSyncTeamOps</strong> updates team installation counters.</li>
                <li><strong>CHECK_TEAM_CONSTRAINTS</strong> keeps teams valid.</li>
                <li><strong>TrgTeamMemberDates</strong> blocks invalid member dates.</li>
                <li><strong>TrgBookingDates</strong> blocks bookings in the past.</li>
                <li><strong>TrgTeamMustHaveMembers</strong> avoids empty teams.</li>
            </ul>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Next Steps</div>', unsafe_allow_html=True)
    st.markdown(
        """
        <div class="stageup-card">
            <ol style="margin:0; padding-left:1.1rem; color: rgba(30,39,50,0.8); line-height:1.8;">
                <li>Open Login and connect to the database.</li>
                <li>Use Operation 1 and 3 to create customer data.</li>
                <li>Use Operation 2 to create bookings.</li>
                <li>Check Operation 4 and 5 for team and location reports.</li>
            </ol>
        </div>
        """,
        unsafe_allow_html=True,
    )

    st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">System Status</div>', unsafe_allow_html=True)
    st.markdown(
        f"""
        <div class="stageup-card">
            <p style="margin:0 0 0.4rem; color: rgba(30,39,50,0.75);">{APP_SUBTITLE}</p>
            <p style="margin:0; font-weight:700; color: var(--stageup-navy);">Streamlit front-end with Oracle 21c XE backend.</p>
        </div>
        """,
        unsafe_allow_html=True,
    )
