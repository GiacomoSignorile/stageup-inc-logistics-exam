-- ============================================================================
-- STAGEUP EVENT SETUP - POPULATION SCRIPT (NEW SCHEMA)
-- ============================================================================
-- This script populates the new event booking management schema:
-- Offices, Teams, Customers, Locations, Equipment, and Bookings
-- 
-- Data volumes: Medium (50-100 records per table)
-- Relationships: Fully referentially integrated
-- Team sizes: Variable 1-10 members per team
-- Booking dates: Mix of past, present, and future
-- ============================================================================

-- DROP old sequences if they exist
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE team_code_seq';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE customer_code_seq';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE location_code_seq';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE booking_id_seq';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/
BEGIN
  EXECUTE IMMEDIATE 'DROP SEQUENCE equipment_code_seq';
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

-- CREATE new sequences
CREATE SEQUENCE team_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE customer_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE location_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE booking_id_seq START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE equipment_code_seq START WITH 1 INCREMENT BY 1 NOCACHE;


/

-- ============================================================================
-- PHASE 1: POPULATE OFFICE_TAB
-- ============================================================================
DECLARE
    v_office_id     NUMBER;
    v_address       Address_t;
    v_cities        DBMS_SQL.varchar2_table;
    v_office_types  DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Office_TAB ---');
    
    -- Sample city names
    v_cities(1) := 'New York'; v_cities(2) := 'Los Angeles'; v_cities(3) := 'Chicago';
    v_cities(4) := 'Houston'; v_cities(5) := 'Phoenix'; v_cities(6) := 'Boston';
    v_cities(7) := 'Miami'; v_cities(8) := 'Seattle'; v_cities(9) := 'Denver';
    v_cities(10) := 'Dallas';
    
    -- Office types
    v_office_types(1) := 'Central';
    v_office_types(2) := 'Depot';
    
    FOR i IN 1..15 LOOP
        v_address := Address_t(
            Street => 'Main Street',
            StreetNo => TO_CHAR(MOD(i*15, 999) + 1),
            ZipCode => 10000 + MOD(i*1000, 89999),
            City => v_cities(MOD(i, 10) + 1),
            Province => CASE WHEN MOD(i, 3) = 0 THEN 'NY' WHEN MOD(i, 3) = 1 THEN 'CA' ELSE 'TX' END
        );
        
        INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
        VALUES (
            'Office_' || LPAD(i, 3, '0'),
            v_address,
            TRUNC(DBMS_RANDOM.VALUE(10, 100)),
            v_office_types(CASE WHEN i <= 5 THEN 1 ELSE 2 END) -- First 5 are Central, rest are Depots
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 15 offices into Office_TAB.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Office_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- PHASE 2: POPULATE EQUIPMENT_TAB
-- ============================================================================
DECLARE
    v_equipment_id  NUMBER;
    v_equipment     DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Equipment_TAB ---');
    
    -- Sample equipment types
    v_equipment(1) := 'Sound System';
    v_equipment(2) := 'Lighting Rig';
    v_equipment(3) := 'Projection Screen';
    v_equipment(4) := 'Microphone';
    v_equipment(5) := 'Speaker Box';
    v_equipment(6) := 'Mixing Console';
    v_equipment(7) := 'Folding Table';
    v_equipment(8) := 'Folding Chair';
    v_equipment(9) := 'Stage Platform';
    v_equipment(10) := 'Camera Stand';
    
    FOR i IN 1..25 LOOP
        v_equipment_id := equipment_code_seq.NEXTVAL;
        
        INSERT INTO Equipment_TAB (ItemCode, Description, UnitsAvailable)
        VALUES (
            v_equipment_id,
            v_equipment(MOD(i, 10) + 1) || ' Model-' || LPAD(i, 3, '0'),
            TRUNC(DBMS_RANDOM.VALUE(5, 100))
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 25 equipment types into Equipment_TAB.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Equipment_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- PHASE 3: POPULATE CUSTOMER_TAB
-- ============================================================================
DECLARE
    v_customer_code VARCHAR2(10);
    v_customer_type VARCHAR2(15);
    v_first_names   DBMS_SQL.varchar2_table;
    v_last_names    DBMS_SQL.varchar2_table;
    v_domains       DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Customer_TAB ---');
    
    -- Sample names for variety
    v_first_names(1) := 'John'; v_first_names(2) := 'Jane'; v_first_names(3) := 'Robert';
    v_first_names(4) := 'Patricia'; v_first_names(5) := 'Michael'; v_first_names(6) := 'Jennifer';
    v_first_names(7) := 'David'; v_first_names(8) := 'Linda'; v_first_names(9) := 'James';
    v_first_names(10) := 'Barbara';
    
    v_last_names(1) := 'Smith'; v_last_names(2) := 'Johnson'; v_last_names(3) := 'Williams';
    v_last_names(4) := 'Brown'; v_last_names(5) := 'Jones'; v_last_names(6) := 'Garcia';
    v_last_names(7) := 'Miller'; v_last_names(8) := 'Davis'; v_last_names(9) := 'Rodriguez';
    v_last_names(10) := 'Martinez';
    
    v_domains(1) := 'gmail.com'; v_domains(2) := 'yahoo.com'; v_domains(3) := 'outlook.com';
    v_domains(4) := 'company.com'; v_domains(5) := 'mail.com'; v_domains(6) := 'events.com';
    
    FOR i IN 1..60 LOOP
        v_customer_code := 'CUST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
        
        -- 40% Individual, 60% Company
        IF MOD(i, 5) = 0 THEN
            v_customer_type := 'Individual';
        ELSE
            v_customer_type := 'Company';
        END IF;
        
        INSERT INTO Customer_TAB (CustomerCode, Email, CustomerType)
        VALUES (
            v_customer_code,
            LOWER(v_first_names(MOD(i, 10) + 1) || '.' || v_last_names(MOD(i+5, 10) + 1) || 
                  '@' || v_domains(MOD(i, 6) + 1)),
            v_customer_type
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 60 customers into Customer_TAB.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Customer_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- PHASE 4: POPULATE TEAM_TAB (with Member_VA members)
-- ============================================================================
DECLARE
    v_team_code     NUMBER;
    v_team_name     VARCHAR2(30);
    v_members       Member_VA;
    v_member        Member_t;
    v_tax_code      CHAR(16);
    v_first_names   DBMS_SQL.varchar2_table;
    v_last_names    DBMS_SQL.varchar2_table;
    v_num_members   NUMBER;
    v_birth_date    DATE;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Team_TAB ---');
    
    v_first_names(1) := 'Alice'; v_first_names(2) := 'Bob'; v_first_names(3) := 'Charlie';
    v_first_names(4) := 'Diana'; v_first_names(5) := 'Edward'; v_first_names(6) := 'Fiona';
    v_first_names(7) := 'George'; v_first_names(8) := 'Hannah'; v_first_names(9) := 'Isaac';
    v_first_names(10) := 'Julia';
    
    v_last_names(1) := 'Anderson'; v_last_names(2) := 'Baker'; v_last_names(3) := 'Clark';
    v_last_names(4) := 'Davis'; v_last_names(5) := 'Evans'; v_last_names(6) := 'Foster';
    v_last_names(7) := 'Green'; v_last_names(8) := 'Harris'; v_last_names(9) := 'Irving';
    v_last_names(10) := 'Jackson';
    
    FOR i IN 1..12 LOOP
        v_team_code := team_code_seq.NEXTVAL;
        v_team_name := 'Team_' || LPAD(v_team_code, 3, '0');
        v_members := Member_VA(); -- Initialize empty VARRAY
        
        -- Random team size: 1-10 members
        v_num_members := TRUNC(DBMS_RANDOM.VALUE(1, 10.99));
        
        FOR j IN 1..v_num_members LOOP
            -- Generate random 16-char tax code
            v_tax_code := CHR(65 + MOD(v_team_code*j, 26)) || 
                         CHR(65 + MOD(v_team_code+j, 26)) ||
                         LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)), 7, '0') ||
                         LPAD(TRUNC(DBMS_RANDOM.VALUE(100000, 999999)), 6, '0');
            
            -- Random birth date: 25-65 years old
            v_birth_date := TRUNC(SYSDATE) - (365 * (25 + TRUNC(DBMS_RANDOM.VALUE(0, 40.99))));
            
            v_member := Member_t(
                TaxCode => v_tax_code,
                FirstName => v_first_names(MOD(j + v_team_code, 10) + 1),
                LastName => v_last_names(MOD(j, 10) + 1),
                BirthDate => v_birth_date
            );
            
            v_members.EXTEND;
            v_members(v_members.LAST) := v_member;
        END LOOP;
        
        INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members)
        VALUES (
            v_team_code,
            v_team_name,
            0,
            v_members
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 12 teams with variable member counts (1-10) into Team_TAB.');
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Team_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- PHASE 5: POPULATE LOCATION_TAB (referencing Customer_TAB)
-- ============================================================================
DECLARE
    v_location_code   VARCHAR2(10);
    v_address         Address_t;
    v_customer_ref    REF Customer_t;
    v_customer_code   Customer_TAB.CustomerCode%TYPE;
    v_setup_time      NUMBER;
    v_equipment_cap   NUMBER;
    v_cities          DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Location_TAB ---');
    
    v_cities(1) := 'New York'; v_cities(2) := 'Los Angeles'; v_cities(3) := 'Chicago';
    v_cities(4) := 'Houston'; v_cities(5) := 'Phoenix'; v_cities(6) := 'Boston';
    v_cities(7) := 'Miami'; v_cities(8) := 'Seattle'; v_cities(9) := 'Denver';
    v_cities(10) := 'Dallas';
    
    FOR i IN 1..40 LOOP
        v_location_code := 'LOC' || LPAD(location_code_seq.NEXTVAL, 7, '0');
        
        -- Random address
        v_address := Address_t(
            Street => 'Event Street',
            StreetNo => TO_CHAR(MOD(i*25, 999) + 1),
            ZipCode => 10000 + MOD(i*2000, 89999),
            City => v_cities(MOD(i, 10) + 1),
            Province => CASE WHEN MOD(i, 3) = 0 THEN 'NY' WHEN MOD(i, 3) = 1 THEN 'CA' ELSE 'TX' END
        );
        
        -- Random customer reference
        SELECT CustomerCode INTO v_customer_code
        FROM Customer_TAB
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;
        
        SELECT REF(c) INTO v_customer_ref
        FROM Customer_TAB c
        WHERE c.CustomerCode = v_customer_code;
        
        v_setup_time := TRUNC(DBMS_RANDOM.VALUE(30, 480.99)); -- 30-480 minutes
        v_equipment_cap := TRUNC(DBMS_RANDOM.VALUE(10, 1000.99)); -- 10-1000 units
        
        INSERT INTO Location_TAB (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
        VALUES (
            v_location_code,
            v_address,
            v_setup_time,
            v_equipment_cap,
            v_customer_ref
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 40 locations into Location_TAB.');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: No customers found. Ensure Customer_TAB is populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Location_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- PHASE 6: POPULATE BOOKING_TAB (referencing Team_TAB and Location_TAB)
-- ============================================================================
DECLARE
    v_booking_id         NUMBER;
    v_team_ref           REF Team_t;
    v_location_ref       REF Location_t;
    v_team_code          Team_TAB.TeamCode%TYPE;
    v_location_code      Location_TAB.LocationCode%TYPE;
    v_booking_type       VARCHAR2(20);
    v_booking_date       DATE;
    v_duration           NUMBER;
    v_total_cost         NUMBER(10,2);
    v_placement_mode     VARCHAR2(15);
    v_booking_types      DBMS_SQL.varchar2_table;
    v_placement_modes    DBMS_SQL.varchar2_table;
    v_date_offset        NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Booking_TAB ---');
    
    -- Booking types
    v_booking_types(1) := 'One-time';
    v_booking_types(2) := 'Recurring';
    v_booking_types(3) := 'Seasonal';
    v_booking_types(4) := 'Promotional';
    
    -- Placement modes
    v_placement_modes(1) := 'Phone';
    v_placement_modes(2) := 'Mail';
    v_placement_modes(3) := 'Email';
    v_placement_modes(4) := 'Website';
    
    FOR i IN 1..80 LOOP
        v_booking_id := booking_id_seq.NEXTVAL;
        
        -- Random team reference
        SELECT TeamCode INTO v_team_code
        FROM Team_TAB
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;
        
        SELECT REF(t) INTO v_team_ref
        FROM Team_TAB t
        WHERE t.TeamCode = v_team_code;
        
        -- Random location reference
        SELECT LocationCode INTO v_location_code
        FROM Location_TAB
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;
        
        SELECT REF(l) INTO v_location_ref
        FROM Location_TAB l
        WHERE l.LocationCode = v_location_code;
        
        -- Mix of past, present, future bookings
        -- 40% past, 30% future, 30% current
        v_date_offset := DBMS_RANDOM.VALUE(1, 100);
        IF v_date_offset <= 40 THEN
            -- Past booking: 1-365 days ago
            v_booking_date := TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(1, 365.99));
        ELSIF v_date_offset <= 70 THEN
            -- Future booking: 1-730 days ahead
            v_booking_date := TRUNC(SYSDATE) + TRUNC(DBMS_RANDOM.VALUE(1, 730.99));
        ELSE
            -- Current booking: within ±30 days
            v_booking_date := TRUNC(SYSDATE) + TRUNC(DBMS_RANDOM.VALUE(-30, 30.99));
        END IF;
        
        v_duration := TRUNC(DBMS_RANDOM.VALUE(1, 48.99)); -- 1-48 hours
        v_total_cost := ROUND(DBMS_RANDOM.VALUE(100, 10000), 2); -- $100-$10,000
        v_booking_type := v_booking_types(TRUNC(DBMS_RANDOM.VALUE(1, 4.99)));
        v_placement_mode := v_placement_modes(TRUNC(DBMS_RANDOM.VALUE(1, 4.99)));
        
        INSERT INTO Booking_TAB (
            BookingID, BookingType, BookingDate, Duration, TotalCost, 
            PlacementMode, AtLocation, HandledBy
        )
        VALUES (
            v_booking_id,
            v_booking_type,
            v_booking_date,
            v_duration,
            v_total_cost,
            v_placement_mode,
            v_location_ref,
            v_team_ref
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 80 bookings into Booking_TAB.');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: Not enough teams or locations. Ensure Team_TAB and Location_TAB are populated: ' || SQLERRM);
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Booking_TAB: ' || SQLERRM);
END;
/

-- ============================================================================
-- VERIFICATION SUMMARY
-- ============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== POPULATION COMPLETE ===');
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.NEW_LINE;
END;
/

-- Display row counts
SET PAGESIZE 0 FEEDBACK OFF VERIFY OFF HEADING OFF ECHO OFF;
SPOOL OFF;

DECLARE
    v_office_count      NUMBER;
    v_equipment_count   NUMBER;
    v_customer_count    NUMBER;
    v_team_count        NUMBER;
    v_location_count    NUMBER;
    v_booking_count     NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_office_count FROM Office_TAB;
    SELECT COUNT(*) INTO v_equipment_count FROM Equipment_TAB;
    SELECT COUNT(*) INTO v_customer_count FROM Customer_TAB;
    SELECT COUNT(*) INTO v_team_count FROM Team_TAB;
    SELECT COUNT(*) INTO v_location_count FROM Location_TAB;
    SELECT COUNT(*) INTO v_booking_count FROM Booking_TAB;
    
    DBMS_OUTPUT.PUT_LINE('Offices:     ' || v_office_count);
    DBMS_OUTPUT.PUT_LINE('Equipment:   ' || v_equipment_count);
    DBMS_OUTPUT.PUT_LINE('Customers:   ' || v_customer_count);
    DBMS_OUTPUT.PUT_LINE('Teams:       ' || v_team_count);
    DBMS_OUTPUT.PUT_LINE('Locations:   ' || v_location_count);
    DBMS_OUTPUT.PUT_LINE('Bookings:    ' || v_booking_count);
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('All tables populated successfully!');
END;
/