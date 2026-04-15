import streamlit as st
import oracledb
import db_utils
from datetime import date

db_utils.ensure_session_state()

st.title("📝 Create New Booking")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in to create a booking. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute("SELECT LocationCode FROM Location_TAB ORDER BY LocationCode")
            locations = [row[0] for row in cursor.fetchall()]

        with connection.cursor() as cursor:
            cursor.execute("SELECT TeamCode, TeamName FROM Team_TAB ORDER BY TeamCode")
            teams = cursor.fetchall()

        if not locations:
            st.error("No locations found. Populate Location_TAB first.")
            st.stop()

        if not teams:
            st.error("No teams found. Populate Team_TAB first.")
            st.stop()

        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(BookingID), 0) + 1 FROM Booking_TAB")
            next_booking_id = cursor.fetchone()[0]

        team_options = {f"{row[1]} (Code: {row[0]})": row[0] for row in teams}

        with st.form("create_booking_form"):
            st.subheader("Create Booking")
            st.info(f"Next Booking ID: {next_booking_id}")
            location_code = st.selectbox("Location", locations)
            team_label = st.selectbox("Assigned Team", list(team_options.keys()))
            booking_type = st.selectbox("Booking Type", ["One-time", "Recurring", "Seasonal", "Promotional"])
            booking_date = st.date_input("Booking Date", value=date.today())
            duration = st.number_input("Duration (hours)", min_value=1, max_value=72, step=1, value=4)
            total_cost = st.number_input("Total Cost", min_value=1.0, step=50.0, value=500.0)
            placement_mode = st.selectbox("Placement Mode", ["Phone", "Mail", "Email", "Website"])
            submitted = st.form_submit_button("Create Booking")

        if submitted:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        INSERT INTO Booking_TAB
                        (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
                        VALUES (
                            :booking_id,
                            :booking_type,
                            :booking_date,
                            :duration,
                            :total_cost,
                            :placement_mode,
                            (SELECT REF(l) FROM Location_TAB l WHERE l.LocationCode = :location_code),
                            (SELECT t.OfficeRef FROM Team_TAB t WHERE t.TeamCode = :team_code)
                        )
                        """,
                        {
                            'booking_id': int(next_booking_id),
                            'booking_type': booking_type,
                            'booking_date': booking_date,
                            'duration': int(duration),
                            'total_cost': float(total_cost),
                            'placement_mode': placement_mode,
                            'location_code': location_code,
                            'team_code': team_options[team_label],
                        }
                    )
                    connection.commit()
                    st.success(f"Booking {next_booking_id} created successfully.")
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")