import streamlit as st
import oracledb
import db_utils

db_utils.ensure_session_state()

st.title("📋 View Team Bookings")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in to view reports. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT TeamCode, TeamName, NoInstallations
                FROM Team_TAB
                ORDER BY TeamCode
                """
            )
            teams = cursor.fetchall()
        team_options = {
            f"{row[1]} (Code: {row[0]}, Installations: {row[2]})": row[0]
            for row in teams
        }

        with st.form("select_chief_form"):
            st.subheader("Select Team")
            if not team_options:
                st.info("No teams found.")
                st.stop()
            team_label = st.selectbox(
                "Team",
                list(team_options.keys())
            )
            team_code = team_options[team_label]
            submitted = st.form_submit_button("View Bookings")

        if submitted:
            with connection.cursor() as cursor:
                cursor.execute(
                    "SELECT TeamCode, TeamName, DEREF(OfficeRef).Name FROM Team_TAB WHERE TeamCode = :team_code",
                    {'team_code': team_code}
                )
                teams = cursor.fetchall()
            if not teams:
                st.info("No team found for the selected code.")
                st.stop()

            st.markdown(f"**Selected Team Code:** {teams[0][0]}")
            st.markdown(f"### Bookings for Team: {teams[0][1]}")
            st.markdown(f"**Handled by Office:** {teams[0][2]}")

            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT b.BookingID,
                           b.BookingType,
                           b.BookingDate,
                           b.Duration,
                           b.TotalCost,
                           b.PlacementMode,
                           DEREF(b.AtLocation).LocationCode,
                           DEREF(DEREF(b.AtLocation).OwnerRef).CustomerCode
                    FROM Booking_TAB b
                          WHERE b.HandledBy = (SELECT OfficeRef FROM Team_TAB WHERE TeamCode = :team_code)
                    ORDER BY b.BookingID
                    """,
                    {'team_code': team_code}
                )
                bookings = cursor.fetchall()

            if not bookings:
                st.info("No bookings assigned to this team.")
            else:
                st.dataframe(
                    [
                        {
                            "BookingID": row[0],
                            "Type": row[1],
                            "Booking Date": row[2].strftime('%Y-%m-%d'),
                            "Duration (h)": row[3],
                            "Total Cost": row[4],
                            "Placement": row[5],
                            "Location": row[6],
                            "Customer": row[7],
                        }
                        for row in bookings
                    ],
                    width="stretch"
                )
