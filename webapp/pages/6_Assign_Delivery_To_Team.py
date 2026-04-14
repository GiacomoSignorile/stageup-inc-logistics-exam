import streamlit as st
import oracledb
import db_utils

st.title("👥 Reassign Booking Team")

if not st.session_state.db_connected or not st.session_state.logged_in_user:
    st.warning("You must be logged in to assign teams. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT b.BookingID,
                       b.BookingType,
                       b.BookingDate,
                       DEREF(b.HandledBy).TeamCode,
                       DEREF(b.HandledBy).TeamName
                FROM Booking_TAB b
                ORDER BY b.BookingID
                """
            )
            bookings = cursor.fetchall()

        booking_options = {
            (
                f"BookingID: {row[0]} | Type: {row[1]} | Date: {row[2].strftime('%Y-%m-%d')} "
                f"| Team: {row[4]} (Code: {row[3]})"
            ): row[0]
            for row in bookings
        }

        if not booking_options:
            st.info("No bookings available for assignment.")
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
            if not teams:
                st.warning("No teams found.")
                st.stop()

            team_options = {
                f"{row[1]} (Code: {row[0]})": row[0]
                for row in teams
            }

        with st.form("assign_delivery_form"):
            st.subheader("Assign Team to Booking")
            booking_label = st.selectbox(
                "Select Booking",
                list(booking_options.keys())
            )
            team_label = st.selectbox(
                "Select Team",
                list(team_options.keys())
            )
            team_code = team_options[team_label]
            submitted = st.form_submit_button("Assign Team")

        if submitted:
            try:
                with connection.cursor() as cursor:
                    cursor.execute(
                        """
                        UPDATE Booking_TAB
                        SET HandledBy = (
                            SELECT REF(t)
                            FROM Team_TAB t
                            WHERE t.TeamCode = :team_code
                        )
                        WHERE BookingID = :booking_id
                        """,
                        {
                            'team_code': team_code,
                            'booking_id': booking_options[booking_label],
                        }
                    )
                    connection.commit()
                    st.success(f"Booking {booking_options[booking_label]} assigned to {team_label}.")
            except oracledb.Error as e:
                error_obj, = e.args
                st.error(f"Database Error: {error_obj.message}")
            except Exception as e:
                st.error(f"Unexpected error: {e}")
