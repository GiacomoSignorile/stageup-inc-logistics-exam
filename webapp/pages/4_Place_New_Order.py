import streamlit as st
import oracledb
import db_utils
from datetime import date, timedelta

st.title("🚚 Update Booking Details")

if not st.session_state.db_connected or not st.session_state.logged_in_user:
    st.warning("You must be logged in to update bookings. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
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
                       DEREF(b.HandledBy).TeamCode,
                       DEREF(b.HandledBy).TeamName
                FROM Booking_TAB b
                ORDER BY b.BookingID
                """
            )
            bookings = cursor.fetchall()

        if not bookings:
            st.info("No bookings available.")
            st.stop()

        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT TeamCode, TeamName
                FROM Team_TAB
                ORDER BY TeamCode
                """
            )
            teams = cursor.fetchall()

        with connection.cursor() as cursor:
            cursor.execute("SELECT LocationCode FROM Location_TAB ORDER BY LocationCode")
            locations = [row[0] for row in cursor.fetchall()]

        team_options = {f"{row[1]} (Code: {row[0]})": row[0] for row in teams}
        booking_options = {
            (
                f"Booking {row[0]} | {row[1]} | Date: {row[2].strftime('%Y-%m-%d')} "
                f"| Team: {row[8]}"
            ): row
            for row in bookings
        }

        with st.form("update_booking_form"):
            st.subheader("Edit Existing Booking")
            booking_label = st.selectbox("Booking", list(booking_options.keys()))
            selected = booking_options[booking_label]

            booking_type = st.selectbox(
                "Booking Type",
                ["One-time", "Recurring", "Seasonal", "Promotional"],
                index=["One-time", "Recurring", "Seasonal", "Promotional"].index(selected[1]),
            )
            booking_date = st.date_input("Booking Date", value=selected[2])
            duration = st.number_input("Duration (hours)", min_value=1, max_value=72, value=int(selected[3]))
            total_cost = st.number_input("Total Cost", min_value=1.0, value=float(selected[4]))
            placement_mode = st.selectbox(
                "Placement Mode",
                ["Phone", "Mail", "Email", "Website"],
                index=["Phone", "Mail", "Email", "Website"].index(selected[5]),
            )
            location_code = st.selectbox("Location", locations, index=locations.index(selected[6]))
            team_label = st.selectbox(
                "Assigned Team",
                list(team_options.keys()),
                index=list(team_options.values()).index(selected[7]),
            )

            quick_shift = st.checkbox("Shift booking date by +2 days", value=False)
            submitted = st.form_submit_button("Update Booking")

        if submitted:
            try:
                final_date = booking_date + timedelta(days=2) if quick_shift else booking_date
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        UPDATE Booking_TAB
                        SET BookingType = :booking_type,
                            BookingDate = :booking_date,
                            Duration = :duration,
                            TotalCost = :total_cost,
                            PlacementMode = :placement_mode,
                            AtLocation = (SELECT REF(l) FROM Location_TAB l WHERE l.LocationCode = :location_code),
                            HandledBy = (SELECT REF(t) FROM Team_TAB t WHERE t.TeamCode = :team_code)
                        WHERE BookingID = :booking_id
                        """,
                        {
                            "booking_type": booking_type,
                            "booking_date": final_date,
                            "duration": int(duration),
                            "total_cost": float(total_cost),
                            "placement_mode": placement_mode,
                            "location_code": location_code,
                            "team_code": team_options[team_label],
                            "booking_id": int(selected[0]),
                        },
                    )
                connection.commit()
                st.success(f"Booking {selected[0]} updated successfully.")
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")
