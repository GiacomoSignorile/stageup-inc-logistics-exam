"""
OPERATION 1: Enter all data related to a new customer
- Frequency: 10 times a day
- Inserting customer with personal/company details and optionally one or more event locations
"""

import streamlit as st
import oracledb
import db_utils
from datetime import date

db_utils.ensure_session_state()

st.title("👥 Operation 1: Register New Customer")
st.markdown("**Frequency:** 10 times/day | **Description:** Enter complete customer data with personal/company details and event locations")

if not st.session_state.get("db_connected") or not st.session_state.get("logged_in_user"):
    st.warning("You must be logged in. Please go to **Login**.")
else:
    with st.session_state.db_pool.acquire() as connection:
        # Get next customer code
        with connection.cursor() as cursor:
            cursor.execute("SELECT NVL(MAX(CustomerCode), 'C000'), COUNT(*) as cnt FROM Customer_TAB")
            result = cursor.fetchone()
            last_code = result[0] if result[0] and result[0] != 'C000' else 'C000'
            customer_count = result[1] if result else 0
            
            try:
                num = int(last_code[1:]) + 1
                next_code = f"C{num:03d}"
            except:
                next_code = f"C{customer_count + 1:03d}"

        st.info(f"Next Customer Code: **{next_code}**")

        st.subheader("📍 Event Locations (Optional)")
        num_locations = st.number_input(
            "Number of Event Locations to Add",
            min_value=0,
            max_value=5,
            value=0,
            key="num_locations_op1"
        )

        # Main form for customer registration
        with st.form("register_customer_form"):
            st.subheader("📋 Customer Information")
            
            col1, col2 = st.columns(2)
            with col1:
                customer_type = st.selectbox("Customer Type", ["Individual", "Company"])
                first_name = st.text_input("First Name / Company Name", max_chars=50)
                
            with col2:
                last_name = st.text_input("Last Name (if Individual)", max_chars=50)
                email = st.text_input("Email", max_chars=50)

            st.subheader("🏠 Primary Address")
            col1, col2 = st.columns(2)
            with col1:
                street = st.text_input("Street Name", max_chars=30)
                street_no = st.text_input("Street Number", max_chars=5)
            with col2:
                zipcode = st.number_input("ZIP Code", min_value=1000, max_value=99999, value=70100)
                city = st.text_input("City", max_chars=30, value="Bari")
            
            province = st.text_input("Province (2 chars)", max_chars=5, value="BA")

            locations = []
            if num_locations > 0:
                for i in range(num_locations):
                    with st.expander(f"Location {i+1}"):
                        loc_street = st.text_input(f"Location {i+1} - Street", max_chars=30, key=f"loc_street_{i}")
                        loc_street_no = st.text_input(f"Location {i+1} - Street Number", max_chars=5, key=f"loc_street_no_{i}")
                        loc_zipcode = st.number_input(f"Location {i+1} - ZIP", min_value=1000, max_value=99999, value=70100, key=f"loc_zip_{i}")
                        loc_city = st.text_input(f"Location {i+1} - City", max_chars=30, key=f"loc_city_{i}", value="Bari")
                        loc_province = st.text_input(f"Location {i+1} - Province", max_chars=5, key=f"loc_prov_{i}", value="BA")
                        setup_time = st.number_input(f"Location {i+1} - Setup Time (hours)", min_value=1, max_value=24, value=4, key=f"setup_{i}")
                        capacity = st.number_input(f"Location {i+1} - Equipment Capacity", min_value=1, value=100, key=f"capacity_{i}")
                        
                        locations.append({
                            'street': loc_street,
                            'street_no': loc_street_no,
                            'zipcode': loc_zipcode,
                            'city': loc_city,
                            'province': loc_province,
                            'setup_time': setup_time,
                            'capacity': capacity
                        })

            submitted = st.form_submit_button("✅ Register Customer & Locations")

        if submitted:
            try:
                with connection.cursor() as cursor:
                    # Validate inputs
                    if not first_name or not email:
                        st.error("First Name and Email are required!")
                        st.stop()

                    # Get customer address reference
                    with connection.cursor() as csr:
                        csr.execute("""
                            SELECT ROWID FROM Customer_TAB 
                            WHERE CustomerCode = :1
                        """, [next_code])
                        existing = csr.fetchone()
                        if existing:
                            st.error(f"Customer {next_code} already exists!")
                            st.stop()

                    # Insert customer
                    cursor.execute("""
                        INSERT INTO Customer_TAB 
                        (CustomerCode, FirstName, LastName, Email, CustomerType, Address)
                        VALUES (
                            :1,
                            SUBSTR(:2, 1, 50),
                            SUBSTR(NVL(:3, ''), 1, 50),
                            SUBSTR(:4, 1, 50),
                            :5,
                            Address_t(:6, :7, :8, SUBSTR(:9, 1, 30), SUBSTR(:10, 1, 5))
                        )
                    """, [
                        next_code,
                        first_name,
                        last_name,
                        email,
                        customer_type,
                        street,
                        street_no,
                        int(zipcode),
                        city,
                        province
                    ])

                    # Insert event locations
                    for idx, loc in enumerate(locations):
                        # Get next location code
                        with connection.cursor() as lc:
                            lc.execute("""
                                SELECT NVL(MAX(LocationCode), 'L0000'), COUNT(*) FROM Location_TAB
                            """)
                            result = lc.fetchone()
                            last_loc = result[0] if result[0] else 'L0000'
                            try:
                                loc_num = int(last_loc[1:]) + 1
                                next_loc_code = f"L{loc_num:04d}"
                            except:
                                next_loc_code = f"L{idx + 1:04d}"

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
                            loc['street'],
                            loc['street_no'],
                            int(loc['zipcode']),
                            loc['city'],
                            loc['province'],
                            loc['setup_time'],
                            loc['capacity'],
                            next_code
                        ])

                    connection.commit()
                    st.success(f"✅ Customer **{next_code}** registered successfully with {len(locations)} location(s)!")

                    # Display results
                    st.subheader("📊 Registration Summary")
                    st.write(f"- **Customer Code:** {next_code}")
                    st.write(f"- **Name:** {first_name} {last_name if customer_type == 'Individual' and last_name else ''}")
                    st.write(f"- **Email:** {email}")
                    st.write(f"- **Type:** {customer_type}")
                    st.write(f"- **Locations Added:** {len(locations)}")

            except oracledb.DatabaseError as e:
                st.error(f"Database Error: {e}")
            except Exception as e:
                st.error(f"Error: {str(e)}")

        # Display existing customers
        st.divider()
        st.subheader("📋 Registered Customers")
        
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT c.CustomerCode, c.FirstName, c.LastName, c.Email, c.CustomerType
                FROM Customer_TAB c
                ORDER BY c.CustomerCode DESC
            """)
            customers = cursor.fetchall()

        if customers:
            df_customers = []
            for cust in customers:
                df_customers.append({
                    "Code": cust[0],
                    "First Name": cust[1],
                    "Last Name": cust[2] or "",
                    "Email": cust[3],
                    "Type": cust[4]
                })
            st.dataframe(df_customers, width='stretch')
        else:
            st.info("No customers registered yet.")
