import streamlit as st
import oracledb
import db_utils

st.title("⏰ Upcoming Bookings (Next 30 Days)")

if not st.session_state.db_connected or not st.session_state.logged_in_user:
    st.warning("You must be logged in to view this report. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                '''
                SELECT b.BookingID,
                       b.BookingType,
                       b.BookingDate,
                       b.Duration,
                       b.TotalCost,
                       b.PlacementMode,
                       DEREF(b.AtLocation).LocationCode,
                       DEREF(b.AtLocation).Address.City,
                       DEREF(b.HandledBy).TeamName,
                       DEREF(DEREF(b.AtLocation).OwnerRef).CustomerCode
                FROM Booking_TAB b
                WHERE b.BookingDate BETWEEN TRUNC(SYSDATE) AND TRUNC(SYSDATE) + 30
                ORDER BY b.BookingDate, b.BookingID
                '''
            )
            rows = cursor.fetchall()
        if not rows:
            st.info("No upcoming bookings in the next 30 days.")
        else:
            st.dataframe(
                [
                    {
                        "BookingID": row[0],
                        "Type": row[1],
                        "Booking Date": row[2].strftime('%Y-%m-%d') if row[2] else '',
                        "Duration (h)": row[3],
                        "Total Cost": row[4],
                        "Placement": row[5],
                        "Location": row[6],
                        "City": row[7],
                        "Team": row[8],
                        "Customer": row[9],
                    }
                    for row in rows
                ],
                use_container_width=True
            )
