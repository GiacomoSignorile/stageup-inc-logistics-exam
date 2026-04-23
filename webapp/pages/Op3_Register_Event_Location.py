"""
OPERATION 3: Register a new event location
- Frequency: 50 times per day
- Creates event locations for registered customers
"""

import streamlit as st
import oracledb
import db_utils

db_utils.ensure_session_state()

st.title("🏢 Operation 3: Register New Event Location")
st.markdown("**Frequency:** 50 times/day | **Description:** Register event locations for customers")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        # Fetch customers
        with connection.cursor() as cursor:
            cursor.execute("SELECT CustomerCode, FirstName, LastName FROM Customer_TAB ORDER BY CustomerCode DESC")
            customers = cursor.fetchall()

        if not customers:
            st.error("❌ No customers registered. Use Operation 1 first.")
            st.stop()

        # Get next location code
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(LocationCode), 'L0000'), COUNT(*) FROM Location_TAB")
            result = cursor.fetchone()
            last_code = result[0] if result[0] and result[0] != 'L0000' else 'L0000'
            location_count = result[1] if result else 0
            
            try:
                num = int(last_code[1:]) + 1
                next_loc_code = f"L{num:04d}"
            except:
                next_loc_code = f"L{location_count + 1:04d}"

        st.info(f"Next Location Code: **{next_loc_code}**")

        # Form for event location registration
        with st.form("register_location_form"):
            st.subheader("🏠 Event Location Details")

            # Select customer
            customer_options = {f"{c[1]} {c[2] or ''} ({c[0]})": c[0] for c in customers}
            selected_customer_label = st.selectbox("Select Customer", list(customer_options.keys()))
            selected_customer_code = customer_options[selected_customer_label]

            st.subheader("📍 Location Address")
            col1, col2 = st.columns(2)
            with col1:
                street = st.text_input("Street Name", max_chars=30)
                street_no = st.text_input("Street Number", max_chars=5)
            with col2:
                zipcode = st.number_input("ZIP Code", min_value=1000, max_value=99999, value=70100)
                city = st.text_input("City", max_chars=30, value="Bari")

            province = st.text_input("Province (2 chars)", max_chars=5, value="BA")

            st.subheader("⚙️ Equipment & Setup")
            col1, col2 = st.columns(2)
            with col1:
                setup_time = st.number_input("Setup Time Estimate (hours)", min_value=1, max_value=24, value=4)
            with col2:
                equipment_capacity = st.number_input("Equipment Capacity", min_value=1, value=100)

            submitted = st.form_submit_button("✅ Register Event Location")

        if submitted:
            try:
                with connection.cursor() as cursor:
                    # Validate inputs
                    if not street or not city:
                        st.error("Street and City are required!")
                        st.stop()

                    # Insert location
                    cursor.execute("""
                        INSERT INTO Location_TAB 
                        (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
                        VALUES (
                            :1,
                            Address_t(:2, :3, :4, SUBSTR(:5, 1, 30), SUBSTR(:6, 1, 5)),
                            :7,
                            :8,
                            (SELECT REF(c) FROM Customer_TAB c WHERE c.CustomerCode = :9)
                        )
                    """, [
                        next_loc_code,
                        street,
                        street_no,
                        int(zipcode),
                        city,
                        province,
                        setup_time,
                        equipment_capacity,
                        selected_customer_code
                    ])

                    connection.commit()

                    st.success(f"✅ Event Location **{next_loc_code}** registered successfully!")
                    
                    st.subheader("📊 Location Summary")
                    st.write(f"- **Location Code:** {next_loc_code}")
                    st.write(f"- **Customer:** {selected_customer_code}")
                    st.write(f"- **Address:** {street} {street_no}, {city} ({province}) {zipcode}")
                    st.write(f"- **Setup Time:** {setup_time} hours")
                    st.write(f"- **Equipment Capacity:** {equipment_capacity}")

            except oracledb.DatabaseError as e:
                st.error(f"Database Error: {e}")
            except Exception as e:
                st.error(f"Error: {str(e)}")

        # Display locations by customer
        st.divider()
        st.subheader("📋 Event Locations by Customer")

        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    c.CustomerCode,
                    c.FirstName,
                    COUNT(l.LocationCode) as LocationCount
                FROM Customer_TAB c
                LEFT JOIN Location_TAB l ON l.OwnerRef = REF(c)
                GROUP BY c.CustomerCode, c.FirstName
                ORDER BY c.CustomerCode DESC
            """)
            customer_locations = cursor.fetchall()

        if customer_locations:
            df_customer_locs = []
            for cl in customer_locations:
                df_customer_locs.append({
                    "Customer Code": cl[0],
                    "Name": cl[1],
                    "# Locations": cl[2] or 0
                })
            st.dataframe(df_customer_locs, width='stretch')
        else:
            st.info("No data available.")

        # Display all locations
        st.subheader("📍 All Event Locations")
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT l.LocationCode, l.Address.City, l.SetupTimeEstimate, l.EquipmentCapacity
                FROM Location_TAB l
                ORDER BY l.LocationCode DESC
            """)
            locations = cursor.fetchall()

        if locations:
            df_locations = []
            for loc in locations:
                df_locations.append({
                    "Code": loc[0],
                    "City": loc[1],
                    "Setup Time (h)": loc[2],
                    "Capacity": loc[3]
                })
            st.dataframe(df_locations[:50], width='stretch')
        else:
            st.info("No event locations registered yet.")
