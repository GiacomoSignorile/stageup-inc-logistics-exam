import streamlit as st
import oracledb
import db_utils


st.title("📈 Team Performance Overview")

if not st.session_state.db_connected or not st.session_state.logged_in_user:
    st.warning("You must be logged in to view this report. Please go to **Login**.")
else:
    try:
        with st.session_state.db_pool.acquire() as connection:
            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT TeamCode, TeamName, NoInstallations,
                           CARDINALITY(Members) AS TeamSize
                    FROM Team_TAB
                    ORDER BY NoInstallations DESC, TeamCode
                    """
                )
                team_rows = cursor.fetchall()

            st.subheader("Teams Ranked by Installations")
            if not team_rows:
                st.info("No teams found.")
            else:
                st.dataframe(
                    [
                        {
                            "TeamCode": row[0],
                            "TeamName": row[1],
                            "NoInstallations": row[2],
                            "TeamSize": row[3],
                        }
                        for row in team_rows
                    ],
                    use_container_width=True,
                )

            with connection.cursor() as cursor:
                cursor.execute(
                    """
                    SELECT b.BookingType, COUNT(*) AS TotalBookings,
                           ROUND(AVG(b.TotalCost), 2) AS AvgCost
                    FROM Booking_TAB b
                    GROUP BY b.BookingType
                    ORDER BY TotalBookings DESC
                    """
                )
                type_rows = cursor.fetchall()

            st.subheader("Bookings by Type")
            if not type_rows:
                st.info("No bookings found.")
            else:
                st.dataframe(
                    [
                        {
                            "BookingType": row[0],
                            "TotalBookings": row[1],
                            "AverageCost": row[2],
                        }
                        for row in type_rows
                    ],
                    use_container_width=True,
                )
    except oracledb.Error as e:
        error_obj, = e.args
        st.error(f"Database Error: {error_obj.message}")
    except Exception as e:
        st.error(f"Unexpected error: {e}")
