"""
OPERATION 5: Print a list of event locations sorted in descending order by the number of bookings
- Frequency: 5 times per day
- Analytics report for location booking activity
"""

import streamlit as st
import oracledb
import db_utils
import pandas as pd

db_utils.ensure_session_state()

st.title("📊 Operation 5: Location Activity Report")
st.markdown("**Frequency:** 5 times/day | **Description:** Analyze event locations sorted by booking activity")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        # Main report: Locations sorted by booking count
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT l.LocationCode,
                       l.Address.Street,
                       l.Address.City,
                       l.Address.ZipCode,
                       COUNT(b.BookingID) as BookingCount,
                       SUM(b.Duration) as TotalSetupHours,
                       SUM(b.TotalCost) as TotalRevenue,
                       l.SetupTimeEstimate,
                       l.EquipmentCapacity,
                       DEREF(l.OwnerRef).FirstName as CustomerName
                FROM Location_TAB l
                LEFT JOIN Booking_TAB b ON b.AtLocation = REF(l)
                GROUP BY l.LocationCode, l.Address.Street, l.Address.City, l.Address.ZipCode,
                         l.SetupTimeEstimate, l.EquipmentCapacity,
                         DEREF(l.OwnerRef).FirstName
                ORDER BY COUNT(b.BookingID) DESC, l.LocationCode
            """)
            locations = cursor.fetchall()

        # Prepare data for display
        location_data = []
        for loc in locations:
            location_data.append({
                "Location Code": loc[0],
                "Street": loc[1],
                "City": loc[2],
                "ZIP": loc[3],
                "# Bookings": loc[4] or 0,
                "Setup Hours": loc[5] or 0,
                "Revenue (€)": f"{loc[6] or 0:.2f}",
                "Est Setup (h)": loc[7],
                "Capacity": loc[8],
                "Customer": loc[9]
            })

        # Display main report
        st.subheader("📍 All Event Locations (Sorted by Booking Activity)")
        
        if location_data:
            # Create DataFrame for better visualization
            df = pd.DataFrame(location_data)
            st.dataframe(df, width='stretch', height=600)

            # Export option
            csv = df.to_csv(index=False)
            st.download_button(
                label="📥 Download as CSV",
                data=csv,
                file_name="location_activity_report.csv",
                mime="text/csv"
            )

            # Statistics
            st.divider()
            st.subheader("📈 Summary Statistics")

            col1, col2, col3, col4 = st.columns(4)
            with col1:
                st.metric("Total Locations", len(location_data))
            with col2:
                total_bookings = sum(int(loc["# Bookings"]) for loc in location_data)
                st.metric("Total Bookings", total_bookings)
            with col3:
                total_hours = sum(int(loc["Setup Hours"]) if isinstance(loc["Setup Hours"], int) else 0 for loc in location_data)
                st.metric("Total Hours", total_hours)
            with col4:
                total_revenue = sum(float(loc["Revenue (€)"].replace('€', '').replace(',', '.')) for loc in location_data)
                st.metric("Total Revenue (€)", f"{total_revenue:.2f}")

            # Top performers
            st.divider()
            st.subheader("🏆 Top Performing Locations")

            top_count = 5
            top_locations = sorted(location_data, key=lambda x: int(x["# Bookings"]), reverse=True)[:top_count]

            for idx, loc in enumerate(top_locations, 1):
                col1, col2, col3, col4 = st.columns(4)
                with col1:
                    st.metric(f"#{idx} - {loc['Location Code']}", f"{loc['# Bookings']} bookings")
                with col2:
                    st.metric("City", loc['City'])
                with col3:
                    st.metric("Revenue", loc['Revenue (€)'])
                with col4:
                    st.metric("Customer", loc['Customer'])
                st.divider()

            # Activity by location
            st.divider()
            st.subheader("📋 Detailed Location Analysis")

            # Filter and detail view
            selected_location = st.selectbox(
                "Select Location for Details",
                [f"{loc['Location Code']} - {loc['City']}" for loc in location_data]
            )

            selected_code = selected_location.split(" - ")[0]
            selected_loc = next((loc for loc in location_data if loc["Location Code"] == selected_code), None)

            if selected_loc:
                st.write(f"**Location Code:** {selected_loc['Location Code']}")
                st.write(f"**Address:** {selected_loc['Street']}, {selected_loc['City']} {selected_loc['ZIP']}")
                st.write(f"**Customer:** {selected_loc['Customer']}")
                st.write(f"**Setup Estimate:** {selected_loc['Est Setup (h)']} hours")
                st.write(f"**Equipment Capacity:** {selected_loc['Capacity']}")
                st.divider()

                # Show all bookings for this location
                with connection.cursor() as cursor:
                    cursor.execute("""
                        SELECT b.BookingID,
                               b.BookingType,
                               b.BookingDate,
                               b.Duration,
                               b.TotalCost,
                               b.PlacementMode,
                               DEREF(b.HandledBy).Name as Office
                        FROM Booking_TAB b
                        WHERE b.AtLocation = (SELECT REF(l) FROM Location_TAB l WHERE LocationCode = :1)
                        ORDER BY b.BookingDate DESC
                    """, [selected_code])
                    bookings = cursor.fetchall()

                if bookings:
                    st.write(f"**Bookings at {selected_code}:**")
                    booking_data = []
                    for b in bookings:
                        booking_data.append({
                            "Booking ID": b[0],
                            "Type": b[1],
                            "Date": b[2],
                            "Duration (h)": b[3],
                            "Cost (€)": f"{b[4]:.2f}",
                            "Mode": b[5],
                            "Office": b[6]
                        })
                    st.dataframe(booking_data, width='stretch')
                else:
                    st.info(f"No bookings yet for location {selected_code}")

            # Heat map visualization
            st.divider()
            st.subheader("🔥 Booking Distribution by City")

            with connection.cursor() as cursor:
                cursor.execute("""
                    SELECT l.Address.City,
                           COUNT(b.BookingID) as BookingCount
                    FROM Location_TAB l
                    LEFT JOIN Booking_TAB b ON b.AtLocation = REF(l)
                    GROUP BY l.Address.City
                    ORDER BY COUNT(b.BookingID) DESC
                """)
                city_data = cursor.fetchall()

            if city_data:
                city_df = pd.DataFrame(city_data, columns=["City", "Bookings"])
                
                col1, col2 = st.columns([2, 1])
                with col1:
                    st.bar_chart(city_df.set_index("City"))
                with col2:
                    st.dataframe(city_df, width='stretch', hide_index=True)

        else:
            st.info("No locations found. Create some using Operation 3 first.")
