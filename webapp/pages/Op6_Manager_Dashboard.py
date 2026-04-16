import pandas as pd
import streamlit as st
import oracledb
import db_utils
from ui_theme import apply_dashboard_theme, render_section_title


db_utils.ensure_session_state()
apply_dashboard_theme()

render_section_title(
    "Manager Dashboard",
    "Comprehensive booking and team insights built from the operational Oracle schema.",
)

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in to view this dashboard. Please go to Login.")
    st.stop()


def fetch_df(connection, sql, params=None):
    with connection.cursor() as cursor:
        cursor.execute(sql, params or {})
        rows = cursor.fetchall()
        cols = [d[0] for d in cursor.description]
    return pd.DataFrame(rows, columns=cols)


try:
    with st.session_state.db_pool.acquire() as connection:
        years_df = fetch_df(
            connection,
            """
            SELECT DISTINCT EXTRACT(YEAR FROM BookingDate) AS BookingYear
            FROM Booking_TAB
            ORDER BY BookingYear
            """,
        )

        office_df = fetch_df(
            connection,
            """
            SELECT Name
            FROM Office_TAB
            ORDER BY Name
            """,
        )

        filter_col1, filter_col2, filter_col3 = st.columns([1.1, 1.2, 1.1], gap="large")

        with filter_col1:
            year_options = ["All"] + [str(int(y)) for y in years_df["BOOKINGYEAR"].dropna().tolist()]
            selected_year = st.selectbox("Analysis Year", year_options)

        with filter_col2:
            office_options = ["All"] + office_df["NAME"].dropna().tolist()
            selected_office = st.selectbox("Office Filter", office_options)

        with filter_col3:
            top_n = st.slider("Top Teams to Display", min_value=5, max_value=20, value=10, step=1)

        where_clauses = []
        bind_vars = {}

        if selected_year != "All":
            where_clauses.append("EXTRACT(YEAR FROM b.BookingDate) = :selected_year")
            bind_vars["selected_year"] = int(selected_year)

        if selected_office != "All":
            where_clauses.append("DEREF(b.HandledBy).Name = :selected_office")
            bind_vars["selected_office"] = selected_office

        where_sql = f"WHERE {' AND '.join(where_clauses)}" if where_clauses else ""

        kpi_df = fetch_df(
            connection,
            f"""
            SELECT
                COUNT(*) AS TotalBookings,
                NVL(SUM(b.TotalCost), 0) AS TotalRevenue,
                ROUND(NVL(AVG(b.Duration), 0), 2) AS AvgDuration,
                COUNT(DISTINCT DEREF(b.HandledBy).Name) AS ActiveOffices
            FROM Booking_TAB b
            {where_sql}
            """,
            bind_vars,
        )

        kpi = kpi_df.iloc[0]

        kpi1, kpi2, kpi3, kpi4 = st.columns(4, gap="large")
        with kpi1:
            st.metric("Total Orders", f"{int(kpi['TOTALBOOKINGS'])}")
        with kpi2:
            st.metric("Total Revenue", f"€ {float(kpi['TOTALREVENUE']):,.0f}")
        with kpi3:
            st.metric("Avg Duration (h)", f"{float(kpi['AVGDURATION']):.2f}")
        with kpi4:
            st.metric("Active Offices", f"{int(kpi['ACTIVEOFFICES'])}")

        left_col, right_col = st.columns([1.1, 2.1], gap="large")

        with left_col:
            st.markdown('<div class="stageup-section-title">Team Scores</div>', unsafe_allow_html=True)
            team_df = fetch_df(
                connection,
                """
                SELECT
                    t.TeamCode,
                    t.TeamName,
                    t.N_Total_Installations,
                    (SELECT COUNT(*) FROM TABLE(CAST(t.Members AS Member_VA))) AS TeamSize,
                    DEREF(t.OfficeRef).Name AS OfficeName,
                    CASE
                        WHEN MAX(t.N_Total_Installations) OVER () = 0 THEN 0
                        ELSE ROUND((t.N_Total_Installations / MAX(t.N_Total_Installations) OVER ()) * 100, 0)
                    END AS ScorePct
                FROM Team_TAB t
                ORDER BY t.N_Total_Installations DESC, t.TeamCode
                """,
            )

            if team_df.empty:
                st.info("No teams found.")
            else:
                st.dataframe(
                    team_df.head(top_n).rename(
                        columns={
                            "TEAMCODE": "Team",
                            "TEAMNAME": "Name",
                            "N_TOTAL_INSTALLATIONS": "Installations",
                            "TEAMSIZE": "Members",
                            "OFFICENAME": "Office",
                            "SCOREPCT": "Score %",
                        }
                    ),
                    width="stretch",
                    hide_index=True,
                )

                st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Selected Team Snapshot</div>', unsafe_allow_html=True)
                team_labels = [f"{row['TEAMNAME']} (#{int(row['TEAMCODE'])})" for _, row in team_df.head(top_n).iterrows()]
                selected_team = st.selectbox("Team", team_labels)
                selected_row = team_df.head(top_n).iloc[team_labels.index(selected_team)]
                st.progress(int(selected_row["SCOREPCT"]) / 100 if selected_row["SCOREPCT"] else 0)
                st.caption(
                    f"Score {int(selected_row['SCOREPCT'])}% | Installations: {int(selected_row['N_TOTAL_INSTALLATIONS'])} | Members: {int(selected_row['TEAMSIZE'])}"
                )

        with right_col:
            top_grid_1, top_grid_2 = st.columns(2, gap="large")

            with top_grid_1:
                st.markdown('<div class="stageup-section-title">Historical Orders</div>', unsafe_allow_html=True)
                trend_df = fetch_df(
                    connection,
                    f"""
                    SELECT
                        TO_CHAR(b.BookingDate, 'YYYY-MM') AS YearMonth,
                        COUNT(*) AS BookingCount
                    FROM Booking_TAB b
                    {where_sql}
                    GROUP BY TO_CHAR(b.BookingDate, 'YYYY-MM')
                    ORDER BY YearMonth
                    """,
                    bind_vars,
                )
                if trend_df.empty:
                    st.info("No trend data for current filters.")
                else:
                    st.line_chart(trend_df.set_index("YEARMONTH"), height=280)

            with top_grid_2:
                st.markdown('<div class="stageup-section-title">Yearly Order Demand</div>', unsafe_allow_html=True)
                yearly_df = fetch_df(
                    connection,
                    """
                    SELECT
                        EXTRACT(YEAR FROM BookingDate) AS YearValue,
                        COUNT(*) AS BookingCount
                    FROM Booking_TAB
                    GROUP BY EXTRACT(YEAR FROM BookingDate)
                    ORDER BY YearValue
                    """,
                )
                if yearly_df.empty:
                    st.info("No yearly data.")
                else:
                    st.area_chart(yearly_df.set_index("YEARVALUE"), height=280)

            bottom_grid_1, bottom_grid_2 = st.columns(2, gap="large")

            with bottom_grid_1:
                st.markdown('<div class="stageup-section-title">Orders by Province</div>', unsafe_allow_html=True)
                province_df = fetch_df(
                    connection,
                    f"""
                    SELECT
                        DEREF(b.AtLocation).Address.Province AS Province,
                        COUNT(*) AS BookingCount
                    FROM Booking_TAB b
                    {where_sql}
                    GROUP BY DEREF(b.AtLocation).Address.Province
                    ORDER BY BookingCount DESC
                    """,
                    bind_vars,
                )
                if province_df.empty:
                    st.info("No provincial data.")
                else:
                    st.bar_chart(province_df.set_index("PROVINCE"), height=280)

            with bottom_grid_2:
                st.markdown('<div class="stageup-section-title">Order Modality</div>', unsafe_allow_html=True)
                mode_df = fetch_df(
                    connection,
                    f"""
                    SELECT
                        b.PlacementMode,
                        COUNT(*) AS BookingCount
                    FROM Booking_TAB b
                    {where_sql}
                    GROUP BY b.PlacementMode
                    ORDER BY BookingCount DESC
                    """,
                    bind_vars,
                )
                if mode_df.empty:
                    st.info("No modality data.")
                else:
                    st.bar_chart(mode_df.set_index("PLACEMENTMODE"), height=280)

            st.markdown('<div class="stageup-section-title" style="margin-top:1rem;">Center Scores</div>', unsafe_allow_html=True)
            office_score_df = fetch_df(
                connection,
                f"""
                SELECT
                    DEREF(b.HandledBy).Name AS OfficeName,
                    COUNT(*) AS BookingCount,
                    ROUND(AVG(b.TotalCost), 2) AS AvgCost
                FROM Booking_TAB b
                {where_sql}
                GROUP BY DEREF(b.HandledBy).Name
                ORDER BY BookingCount DESC
                """,
                bind_vars,
            )
            if office_score_df.empty:
                st.info("No office score data.")
            else:
                st.dataframe(
                    office_score_df.rename(
                        columns={
                            "OFFICENAME": "Office",
                            "BOOKINGCOUNT": "Orders",
                            "AVGCOST": "Avg Cost (€)",
                        }
                    ),
                    width="stretch",
                    hide_index=True,
                )

except oracledb.Error as e:
    error_obj, = e.args
    st.error(f"Database Error: {error_obj.message}")
except Exception as e:
    st.error(f"Unexpected error: {e}")
