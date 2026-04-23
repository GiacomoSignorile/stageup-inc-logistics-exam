"""
OPERATION 2: Record a new booking
- Frequency: 300 times per day
- Creates booking records linked to customers, event locations, and teams
"""

import streamlit as st
import oracledb
import db_utils
from datetime import date, datetime, timedelta

db_utils.ensure_session_state()

st.title("📅 Operation 2: Record New Booking")
st.markdown("**Frequency:** 300 times/day | **Description:** Create bookings for customer event locations with assigned teams")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        # Fetch customers
        with connection.cursor() as cursor:
            cursor.execute("SELECT CustomerCode, FirstName, LastName FROM Customer_TAB ORDER BY CustomerCode DESC")
            customers = cursor.fetchall()

        if not customers:
            st.error("❌ No customers found. Please use Operation 1 to register customers first.")
            st.stop()

        # Fetch teams
        with connection.cursor() as cursor:
            cursor.execute("SELECT TeamCode, TeamName, N_Total_Installations FROM Team_TAB ORDER BY TeamCode")
            teams = cursor.fetchall()

        if not teams:
            st.error("❌ No teams found. Database must be populated first.")
            st.stop()

        # Get next booking ID
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(BookingID), 0) + 1 FROM Booking_TAB")
            next_booking_id = cursor.fetchone()[0]

        st.info(f"Next Booking ID: **{next_booking_id}**")

        # Form for new booking
        with st.form("record_booking_form"):
            st.subheader("📝 Booking Details")

            # Select customer
            customer_options = {f"{c[1]} {c[2] or ''} ({c[0]})": c[0] for c in customers}
            selected_customer_label = st.selectbox("Select Customer", list(customer_options.keys()))
            selected_customer_code = customer_options[selected_customer_label]

            # Fetch locations for selected customer
            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT l.LocationCode, l.Address.Street, l.SetupTimeEstimate
                    FROM Location_TAB l
                    WHERE l.OwnerRef = (SELECT REF(c) FROM Customer_TAB c WHERE CustomerCode = :1)
                    ORDER BY l.LocationCode
                """, [selected_customer_code])
                locations = cursor.fetchall()

            if not locations:
                st.warning(f"⚠️  Customer {selected_customer_code} has no registered event locations. Create one in Operation 3.")
                location_code = None

                # Keep a submit button in every render path to satisfy Streamlit form requirements.
                submitted = st.form_submit_button("✅ Record Booking", disabled=True)
            else:
                location_options = {f"{l[0]} - {l[1]} (Setup: {l[2]}h)": l[0] for l in locations}
                location_code = location_options[st.selectbox("Select Event Location", list(location_options.keys()))]

                # Team selection
                team_options = {f"{t[1]} (Code: {t[0]}, Installations: {t[2]})": t[0] for t in teams}
                team_label = st.selectbox("Assign Team", list(team_options.keys()))
                team_code = team_options[team_label]

                # Booking details
                col1, col2 = st.columns(2)
                with col1:
                    booking_type = st.selectbox("Booking Type", ["One-time", "Recurring", "Seasonal", "Promotional"])
                    booking_date = st.date_input("Booking Date", value=date.today())
                with col2:
                    duration = st.number_input("Duration (hours)", min_value=1, max_value=72, value=4)
                    placement_mode = st.selectbox("Placement Mode", ["Phone", "Mail", "Email", "Website"])

                total_cost = st.number_input("Total Cost (€)", min_value=1.0, step=50.0, value=500.0)

                submitted = st.form_submit_button("✅ Record Booking")

        if submitted:
            try:
                with connection.cursor() as cursor:
                    # Validate
                    if not location_code:
                        st.error("Location code is required!")
                        st.stop()

                    # Ensure at least one office exists before the insert subquery.
                    cursor.execute("SELECT COUNT(*) FROM Office_TAB")
                    office_count = cursor.fetchone()[0]
                    if office_count == 0:
                        st.error("No offices found in database!")
                        st.stop()

                    # Insert booking
                    cursor.execute("""
                        INSERT INTO Booking_TAB 
                        (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
                        VALUES (
                            :1,
                            :2,
                            :3,
                            :4,
                            :5,
                            :6,
                            (SELECT REF(l) FROM Location_TAB l WHERE l.LocationCode = :7),
                            (SELECT REF(o) FROM Office_TAB o WHERE ROWNUM = 1)
                        )
                    """, [
                        next_booking_id,
                        booking_type,
                        booking_date,
                        duration,
                        total_cost,
                        placement_mode,
                        location_code
                    ])

                    connection.commit()

                    st.success(f"✅ Booking **#{next_booking_id}** recorded successfully!")
                    
                    st.subheader("📊 Booking Summary")
                    st.write(f"- **Booking ID:** {next_booking_id}")
                    st.write(f"- **Customer:** {selected_customer_code}")
                    st.write(f"- **Location:** {location_code}")
                    st.write(f"- **Team:** {team_label}")
                    st.write(f"- **Type:** {booking_type}")
                    st.write(f"- **Date:** {booking_date}")
                    st.write(f"- **Duration:** {duration} hours")
                    st.write(f"- **Cost:** €{total_cost}")

            except oracledb.DatabaseError as e:
                st.error(f"Database Error: {e}")
            except Exception as e:
                st.error(f"Error: {str(e)}")

        # Display recent bookings
        st.divider()
        st.subheader("📊 Recent Bookings")
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT b.BookingID, b.BookingType, b.BookingDate, b.Duration, 
                       b.TotalCost, b.PlacementMode
                FROM Booking_TAB b
                ORDER BY b.BookingID DESC
            """)
            bookings = cursor.fetchall()

        if bookings:
            df_bookings = []
            for b in bookings:
                df_bookings.append({
                    "ID": b[0],
                    "Type": b[1],
                    "Date": b[2],
                    "Duration (h)": b[3],
                    "Cost (€)": f"{b[4]:.2f}",
                    "Mode": b[5]
                })
            st.dataframe(df_bookings[:20], width='stretch')
        else:
            st.info("No bookings recorded yet.")
