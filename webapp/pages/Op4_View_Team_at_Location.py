"""
OPERATION 4: View the team that handled setups at a specific event location
- Frequency: 20 times per day
- Query to find team details for a given event location's bookings
"""

import streamlit as st
import oracledb
import db_utils

db_utils.ensure_session_state()

st.title("🔍 Operation 4: View Team at Event Location")
st.markdown("**Frequency:** 20 times/day | **Description:** Track which team handled setups at a specific event location")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        # Fetch all locations
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT l.LocationCode, l.Address.City, l.Address.Street, 
                       COUNT(b.BookingID) as BookingCount
                FROM Location_TAB l
                LEFT JOIN Booking_TAB b ON b.AtLocation = REF(l)
                GROUP BY l.LocationCode, l.Address.City, l.Address.Street
                ORDER BY l.LocationCode DESC
            """)
            locations = cursor.fetchall()

        if not locations:
            st.error("❌ No event locations found. Create some using Operation 3 first.")
            st.stop()

        # Selection interface
        st.subheader("🏢 Select Event Location")
        
        location_options = {}
        for loc in locations:
            label = f"{loc[0]} - {loc[2]} {loc[1]} ({loc[3]} bookings)"
            location_options[label] = loc[0]

        selected_label = st.selectbox("Choose Location", list(location_options.keys()))
        selected_location_code = location_options[selected_label]

        # Fetch bookings for this location
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT b.BookingID, 
                       b.BookingType, 
                       b.BookingDate,
                       b.Duration,
                       b.TotalCost,
                       DEREF(b.HandledBy).Name as OfficeName,
                       DEREF(b.HandledBy).OfficeType as OfficeType,
                       DEREF(b.HandledBy).NoEmployees as NoEmployees
                FROM Booking_TAB b
                WHERE b.AtLocation = (SELECT REF(l) FROM Location_TAB l WHERE LocationCode = :1)
                ORDER BY b.BookingDate DESC
            """, [selected_location_code])
            bookings = cursor.fetchall()

        st.subheader(f"📅 Bookings at Location {selected_location_code}")

        if not bookings:
            st.info(f"No bookings found for location {selected_location_code}")
        else:
            # Display bookings
            st.write(f"**Total Bookings:** {len(bookings)}")
            
            booking_data = []
            for b in bookings:
                booking_data.append({
                    "Booking ID": b[0],
                    "Type": b[1],
                    "Date": b[2],
                    "Duration (h)": b[3],
                    "Cost (€)": f"{b[4]:.2f}",
                    "Office": b[5],
                    "Office Type": b[6],
                    "Employees": b[7]
                })
            
            st.dataframe(booking_data, width='stretch')

            # For each booking, show the team details
            st.subheader("👥 Teams Involved in Bookings")
            
            for booking in bookings:
                booking_id = booking[0]
                office_name = booking[5]

                with st.expander(f"📍 Booking #{booking_id} - {office_name}"):
                    # Get team details from the office
                    # Note: In this schema, we need to find teams assigned to this office/region
                    with connection.cursor() as cursor:
                        cursor.execute("""
                            SELECT t.TeamCode,
                                   t.TeamName,
                                   t.N_Total_Installations,
                                   (SELECT COUNT(*) FROM TABLE(CAST(t.Members AS Member_VA))) as TeamSize,
                                   DEREF(t.RegionRef).RegionName as RegionName
                            FROM Team_TAB t
                            WHERE t.OfficeRef = (
                                SELECT REF(o) FROM Office_TAB o WHERE o.Name = :1
                            )
                            ORDER BY t.TeamCode
                        """, [office_name])
                        teams = cursor.fetchall()

                    if teams:
                        team_data = []
                        for team in teams:
                            team_data.append({
                                "Team Code": team[0],
                                "Team Name": team[1],
                                "Installations": team[2],
                                "Members": team[3],
                                "Region": team[4]
                            })
                        st.dataframe(team_data, width='stretch')

                        # Show team members for first team
                        if team_data:
                            team_code = teams[0][0]
                            st.subheader(f"👤 Team Members (Team {team_code})")
                            
                            with connection.cursor() as cursor:
                                cursor.execute("""
                                    SELECT m.TaxCode,
                                           m.FirstName,
                                           m.LastName,
                                           m.BirthDate
                                    FROM TABLE(
                                        SELECT CAST(t.Members AS Member_VA) FROM Team_TAB t WHERE t.TeamCode = :1
                                    ) m
                                """, [team_code])
                                members = cursor.fetchall()

                            if members:
                                member_data = []
                                for member in members:
                                    member_data.append({
                                        "Tax Code": member[0],
                                        "First Name": member[1],
                                        "Last Name": member[2],
                                        "Birth Date": member[3]
                                    })
                                st.dataframe(member_data, width='stretch')
                            else:
                                st.info("No team members assigned yet.")
                    else:
                        st.info(f"No teams found for office {office_name}")

        # Summary statistics
        st.divider()
        st.subheader("📊 Location Statistics")
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT l.LocationCode,
                       l.Address.City,
                       COUNT(b.BookingID) as TotalBookings,
                       SUM(b.Duration) as TotalHours,
                       SUM(b.TotalCost) as TotalRevenue
                FROM Location_TAB l
                LEFT JOIN Booking_TAB b ON b.AtLocation = REF(l)
                WHERE l.LocationCode = :1
                GROUP BY l.LocationCode, l.Address.City
            """, [selected_location_code])
            stats = cursor.fetchone()

        if stats:
            col1, col2, col3 = st.columns(3)
            with col1:
                st.metric("Total Bookings", stats[2] or 0)
            with col2:
                st.metric("Total Hours", stats[3] or 0)
            with col3:
                st.metric("Total Revenue (€)", f"{stats[4] or 0:.2f}")
