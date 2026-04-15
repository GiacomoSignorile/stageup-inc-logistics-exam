-- ============================================================================
-- STAGEUP EVENT SETUP - POPULATION SCRIPT (RESTRUCTURED SCHEMA)
-- ============================================================================
-- Safe to rerun: it clears table data and recreates sequences.
-- Expected outcome:
-- - 22 Regions
-- - 220 Municipalities
-- - 23 Offices (1 Central + 22 Depots)
-- - 110 Teams
-- - 25 Equipment rows
-- - 80 Customers
-- - 50 Locations
-- - 100 Bookings
-- ============================================================================

SET SERVEROUTPUT ON;

-- Ensure we run against the application schema even if connected as another user.
BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = C##STAGEUPDBA';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;
/

-- ---------------------------------------------------------------------------
-- CLEAN TABLE DATA (idempotent reruns)
-- ---------------------------------------------------------------------------
BEGIN
    DELETE FROM Booking_TAB;
    DELETE FROM Location_TAB;
    DELETE FROM Team_TAB;
    DELETE FROM Municipality_TAB;
    DELETE FROM Region_TAB;
    DELETE FROM Equipment_TAB;
    DELETE FROM Customer_TAB;
    DELETE FROM Office_TAB;
    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Warning while clearing existing rows: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- DROP/CREATE SEQUENCES
-- ---------------------------------------------------------------------------
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE region_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE municipality_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE team_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE customer_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE location_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE booking_id_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE equipment_code_seq'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE region_code_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE municipality_code_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE team_code_seq START WITH 100 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE customer_code_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE location_code_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE booking_id_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'CREATE SEQUENCE equipment_code_seq START WITH 1 INCREMENT BY 1 NOCACHE'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF; END;
/

-- ---------------------------------------------------------------------------
-- PHASE 1: REGIONS (22)
-- ---------------------------------------------------------------------------
DECLARE
    v_regions DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Region_TAB ---');

    v_regions(1) := 'Abruzzo';
    v_regions(2) := 'Basilicata';
    v_regions(3) := 'Calabria';
    v_regions(4) := 'Campania';
    v_regions(5) := 'Emilia-Romagna';
    v_regions(6) := 'Friuli-Venezia Giulia';
    v_regions(7) := 'Lazio';
    v_regions(8) := 'Liguria';
    v_regions(9) := 'Lombardia';
    v_regions(10) := 'Marche';
    v_regions(11) := 'Molise';
    v_regions(12) := 'Piemonte';
    v_regions(13) := 'Puglia';
    v_regions(14) := 'Sardegna';
    v_regions(15) := 'Sicilia';
    v_regions(16) := 'Toscana';
    v_regions(17) := 'Trentino-Alto Adige';
    v_regions(18) := 'Umbria';
    v_regions(19) := 'Valle d''Aosta';
    v_regions(20) := 'Veneto';
    v_regions(21) := 'Corsica';
    v_regions(22) := 'Malta';

    FOR i IN 1..22 LOOP
        INSERT INTO Region_TAB (RegionCode, RegionName)
        VALUES (region_code_seq.NEXTVAL, v_regions(i));
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 22 regions into Region_TAB.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Region_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 2: MUNICIPALITIES (10 per region = 220)
-- ---------------------------------------------------------------------------
DECLARE
    v_region_ref REF Region_t;
    v_muni_names DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Municipality_TAB ---');

    v_muni_names(1) := 'North';
    v_muni_names(2) := 'South';
    v_muni_names(3) := 'East';
    v_muni_names(4) := 'West';
    v_muni_names(5) := 'Central';
    v_muni_names(6) := 'Upper';
    v_muni_names(7) := 'Lower';
    v_muni_names(8) := 'Inner';
    v_muni_names(9) := 'Outer';
    v_muni_names(10) := 'Maritime';

    FOR r IN (SELECT RegionCode, RegionName FROM Region_TAB ORDER BY RegionCode) LOOP
        SELECT REF(rg) INTO v_region_ref
        FROM Region_TAB rg
        WHERE rg.RegionCode = r.RegionCode;

        FOR m IN 1..10 LOOP
            INSERT INTO Municipality_TAB (MunicipalityCode, MunicipalityName, RegionRef)
            VALUES (
                municipality_code_seq.NEXTVAL,
                v_muni_names(m) || ' ' || r.RegionName,
                v_region_ref
            );
        END LOOP;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 220 municipalities into Municipality_TAB.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Municipality_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 3: OFFICES (1 central + 22 depots)
-- ---------------------------------------------------------------------------
DECLARE
    v_address Address_t;
    v_idx NUMBER := 1;
    v_capital_city DBMS_SQL.varchar2_table;
    v_capital_province DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Office_TAB ---');

    v_capital_city(1) := 'L''Aquila';
    v_capital_city(2) := 'Potenza';
    v_capital_city(3) := 'Catanzaro';
    v_capital_city(4) := 'Naples';
    v_capital_city(5) := 'Bologna';
    v_capital_city(6) := 'Trieste';
    v_capital_city(7) := 'Rome';
    v_capital_city(8) := 'Genoa';
    v_capital_city(9) := 'Milan';
    v_capital_city(10) := 'Ancona';
    v_capital_city(11) := 'Campobasso';
    v_capital_city(12) := 'Turin';
    v_capital_city(13) := 'Bari';
    v_capital_city(14) := 'Cagliari';
    v_capital_city(15) := 'Palermo';
    v_capital_city(16) := 'Florence';
    v_capital_city(17) := 'Trento';
    v_capital_city(18) := 'Perugia';
    v_capital_city(19) := 'Aosta';
    v_capital_city(20) := 'Venice';
    v_capital_city(21) := 'Ajaccio';
    v_capital_city(22) := 'Valletta';

    v_capital_province(1) := 'AQ';
    v_capital_province(2) := 'PZ';
    v_capital_province(3) := 'CZ';
    v_capital_province(4) := 'NA';
    v_capital_province(5) := 'BO';
    v_capital_province(6) := 'TS';
    v_capital_province(7) := 'RM';
    v_capital_province(8) := 'GE';
    v_capital_province(9) := 'MI';
    v_capital_province(10) := 'AN';
    v_capital_province(11) := 'CB';
    v_capital_province(12) := 'TO';
    v_capital_province(13) := 'BA';
    v_capital_province(14) := 'CA';
    v_capital_province(15) := 'PA';
    v_capital_province(16) := 'FI';
    v_capital_province(17) := 'TN';
    v_capital_province(18) := 'PG';
    v_capital_province(19) := 'AO';
    v_capital_province(20) := 'VE';
    v_capital_province(21) := 'AJ';
    v_capital_province(22) := 'VA';

    v_address := Address_t('Central Avenue', '1', 10000, 'Rome', 'RM');
    INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
    VALUES ('Central_Office_HQ', v_address, 50, 'Central');

    FOR r IN (SELECT RegionCode, RegionName FROM Region_TAB ORDER BY RegionCode) LOOP
        v_address := Address_t(
            r.RegionName || ' Street',
            LPAD(v_idx, 3, '0'),
            10000 + v_idx,
            v_capital_city(v_idx),
            v_capital_province(v_idx)
        );

        INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
        VALUES ('Depot_Region_' || LPAD(v_idx, 2, '0'), v_address, 20 + MOD(v_idx, 10), 'Depot');

        v_idx := v_idx + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 23 offices into Office_TAB.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Office_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 4: TEAMS (5 per region = 110)
-- ---------------------------------------------------------------------------
DECLARE
    v_members Member_VA;
    v_member Member_t;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
    v_num_members NUMBER;
    v_tax_code CHAR(16);
    v_first_names DBMS_SQL.varchar2_table;
    v_last_names DBMS_SQL.varchar2_table;
    v_region_idx NUMBER := 1;
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

    FOR r IN (SELECT RegionCode FROM Region_TAB ORDER BY RegionCode) LOOP
        SELECT REF(rg) INTO v_region_ref
        FROM Region_TAB rg
        WHERE rg.RegionCode = r.RegionCode;

        SELECT REF(o) INTO v_office_ref
        FROM Office_TAB o
        WHERE o.Name = 'Depot_Region_' || LPAD(v_region_idx, 2, '0');

        FOR t IN 1..5 LOOP
            v_members := Member_VA();
            v_num_members := TRUNC(DBMS_RANDOM.VALUE(2, 9));

            FOR j IN 1..v_num_members LOOP
                v_tax_code :=
                    CHR(65 + MOD(v_region_idx + t + j, 26)) ||
                    CHR(65 + MOD(v_region_idx + j, 26)) ||
                    LPAD(TRUNC(DBMS_RANDOM.VALUE(1000000, 9999999)), 7, '0') ||
                    LPAD(TRUNC(DBMS_RANDOM.VALUE(100000, 999999)), 6, '0');

                v_member := Member_t(
                    v_tax_code,
                    v_first_names(MOD(j + t, 10) + 1),
                    v_last_names(MOD(j + v_region_idx, 10) + 1),
                    ADD_MONTHS(TRUNC(SYSDATE), -12 * TRUNC(DBMS_RANDOM.VALUE(24, 60)))
                );

                v_members.EXTEND;
                v_members(v_members.COUNT) := v_member;
            END LOOP;

            INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members, RegionRef, OfficeRef)
            VALUES (
                team_code_seq.NEXTVAL,
                'Team_Region' || LPAD(v_region_idx, 2, '0') || '_' || LPAD(t, 2, '0'),
                0,
                v_members,
                v_region_ref,
                v_office_ref
            );
        END LOOP;

        v_region_idx := v_region_idx + 1;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 110 teams into Team_TAB.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Team_TAB: depot not found for a region.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Team_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 9: HISTORICAL INSTALLATIONS FOR TEAMS
-- ---------------------------------------------------------------------------
DECLARE
    v_target_installs NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating historical NoInstallations in Team_TAB ---');

    FOR t IN (SELECT TeamCode FROM Team_TAB ORDER BY TeamCode) LOOP
        -- Seed realistic prior installations (0..15).
        v_target_installs := TRUNC(DBMS_RANDOM.VALUE(0, 16));

        FOR i IN 1..v_target_installs LOOP
            -- Keep +1 increments to satisfy CHECK_TEAM_CONSTRAINTS trigger.
            UPDATE Team_TAB
            SET NoInstallations = NoInstallations + 1
            WHERE TeamCode = t.TeamCode;
        END LOOP;
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated historical team installations.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating historical installations: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 5: EQUIPMENT (25)
-- ---------------------------------------------------------------------------
DECLARE
    v_equipment DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Equipment_TAB ---');

    v_equipment(1) := 'Sound System'; v_equipment(2) := 'Lighting Rig'; v_equipment(3) := 'Projection Screen';
    v_equipment(4) := 'Microphone'; v_equipment(5) := 'Speaker Box'; v_equipment(6) := 'Mixing Console';
    v_equipment(7) := 'Folding Table'; v_equipment(8) := 'Folding Chair'; v_equipment(9) := 'Stage Platform';
    v_equipment(10) := 'Camera Stand';

    FOR i IN 1..25 LOOP
        INSERT INTO Equipment_TAB (ItemCode, Description, UnitsAvailable)
        VALUES (
            equipment_code_seq.NEXTVAL,
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

-- ---------------------------------------------------------------------------
-- PHASE 6: CUSTOMERS (80)
-- ---------------------------------------------------------------------------
DECLARE
    v_customer_code VARCHAR2(10);
    v_customer_type VARCHAR2(15);
    v_first_names DBMS_SQL.varchar2_table;
    v_last_names DBMS_SQL.varchar2_table;
    v_domains DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Customer_TAB ---');

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

    FOR i IN 1..80 LOOP
        v_customer_code := 'CUST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
        v_customer_type := CASE WHEN MOD(i, 5) = 0 THEN 'Individual' ELSE 'Company' END;

        INSERT INTO Customer_TAB (CustomerCode, Email, CustomerType)
        VALUES (
            v_customer_code,
            LOWER(v_first_names(MOD(i, 10) + 1) || '.' || v_last_names(MOD(i + 5, 10) + 1) || '@' || v_domains(MOD(i, 6) + 1)),
            v_customer_type
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 80 customers into Customer_TAB.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Customer_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 7: LOCATIONS (50)
-- ---------------------------------------------------------------------------
DECLARE
    v_location_code VARCHAR2(10);
    v_address Address_t;
    v_customer_ref REF Customer_t;
    v_customer_code Customer_TAB.CustomerCode%TYPE;
    v_setup_time NUMBER;
    v_equipment_cap NUMBER;
    v_cities DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Location_TAB ---');

    v_cities(1) := 'Rome'; v_cities(2) := 'Milan'; v_cities(3) := 'Naples';
    v_cities(4) := 'Turin'; v_cities(5) := 'Palermo'; v_cities(6) := 'Genoa';
    v_cities(7) := 'Bologna'; v_cities(8) := 'Florence'; v_cities(9) := 'Venice';
    v_cities(10) := 'Verona';

    FOR i IN 1..50 LOOP
        v_location_code := 'LOC' || LPAD(location_code_seq.NEXTVAL, 7, '0');

        v_address := Address_t(
            'Event Street',
            TO_CHAR(MOD(i * 25, 999) + 1),
            10000 + MOD(i * 2000, 89999),
            v_cities(MOD(i, 10) + 1),
            SUBSTR(v_cities(MOD(i, 10) + 1), 1, 2)
        );

        SELECT CustomerCode
        INTO v_customer_code
        FROM Customer_TAB
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT REF(c)
        INTO v_customer_ref
        FROM Customer_TAB c
        WHERE c.CustomerCode = v_customer_code;

        v_setup_time := TRUNC(DBMS_RANDOM.VALUE(30, 481));
        v_equipment_cap := TRUNC(DBMS_RANDOM.VALUE(10, 1001));

        INSERT INTO Location_TAB (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
        VALUES (v_location_code, v_address, v_setup_time, v_equipment_cap, v_customer_ref);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 50 locations into Location_TAB.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Location_TAB: no customers found.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Location_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- PHASE 8: BOOKINGS (100) - managed by Central Office
-- ---------------------------------------------------------------------------
DECLARE
    v_location_ref REF Location_t;
    v_central_office_ref REF Office_t;
    v_booking_date DATE;
    v_booking_type VARCHAR2(20);
    v_placement_mode VARCHAR2(15);
    v_duration NUMBER;
    v_total_cost NUMBER(10, 2);
    v_booking_types DBMS_SQL.varchar2_table;
    v_placement_modes DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Booking_TAB ---');

    SELECT REF(o)
    INTO v_central_office_ref
    FROM Office_TAB o
    WHERE o.Name = 'Central_Office_HQ';

    v_booking_types(1) := 'One-time';
    v_booking_types(2) := 'Recurring';
    v_booking_types(3) := 'Seasonal';
    v_booking_types(4) := 'Promotional';

    v_placement_modes(1) := 'Phone';
    v_placement_modes(2) := 'Mail';
    v_placement_modes(3) := 'Email';
    v_placement_modes(4) := 'Website';

    FOR i IN 1..100 LOOP
        SELECT REF(l)
        INTO v_location_ref
        FROM Location_TAB l
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        IF MOD(i, 10) <= 3 THEN
            v_booking_date := TRUNC(SYSDATE) - TRUNC(DBMS_RANDOM.VALUE(1, 365));
        ELSIF MOD(i, 10) <= 6 THEN
            v_booking_date := TRUNC(SYSDATE) + TRUNC(DBMS_RANDOM.VALUE(1, 365));
        ELSE
            v_booking_date := TRUNC(SYSDATE) + TRUNC(DBMS_RANDOM.VALUE(-30, 31));
        END IF;

        v_duration := TRUNC(DBMS_RANDOM.VALUE(1, 49));
        v_total_cost := ROUND(DBMS_RANDOM.VALUE(100, 10000), 2);
        v_booking_type := v_booking_types(TRUNC(DBMS_RANDOM.VALUE(1, 5)));
        v_placement_mode := v_placement_modes(TRUNC(DBMS_RANDOM.VALUE(1, 5)));

        INSERT INTO Booking_TAB (
            BookingID,
            BookingType,
            BookingDate,
            Duration,
            TotalCost,
            PlacementMode,
            AtLocation,
            HandledBy
        )
        VALUES (
            booking_id_seq.NEXTVAL,
            v_booking_type,
            v_booking_date,
            v_duration,
            v_total_cost,
            v_placement_mode,
            v_location_ref,
            v_central_office_ref
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 100 bookings into Booking_TAB.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Booking_TAB: missing Central Office or Locations.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Booking_TAB: ' || SQLERRM);
END;
/

-- ---------------------------------------------------------------------------
-- VERIFICATION SUMMARY
-- ---------------------------------------------------------------------------
DECLARE
    v_region_count NUMBER;
    v_municipality_count NUMBER;
    v_office_count NUMBER;
    v_team_count NUMBER;
    v_equipment_count NUMBER;
    v_customer_count NUMBER;
    v_location_count NUMBER;
    v_booking_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_region_count FROM Region_TAB;
    SELECT COUNT(*) INTO v_municipality_count FROM Municipality_TAB;
    SELECT COUNT(*) INTO v_office_count FROM Office_TAB;
    SELECT COUNT(*) INTO v_team_count FROM Team_TAB;
    SELECT COUNT(*) INTO v_equipment_count FROM Equipment_TAB;
    SELECT COUNT(*) INTO v_customer_count FROM Customer_TAB;
    SELECT COUNT(*) INTO v_location_count FROM Location_TAB;
    SELECT COUNT(*) INTO v_booking_count FROM Booking_TAB;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== POPULATION COMPLETE ===');
    DBMS_OUTPUT.PUT_LINE('Regions:        ' || v_region_count);
    DBMS_OUTPUT.PUT_LINE('Municipalities: ' || v_municipality_count);
    DBMS_OUTPUT.PUT_LINE('Offices:        ' || v_office_count);
    DBMS_OUTPUT.PUT_LINE('Teams:          ' || v_team_count);
    DBMS_OUTPUT.PUT_LINE('Equipment:      ' || v_equipment_count);
    DBMS_OUTPUT.PUT_LINE('Customers:      ' || v_customer_count);
    DBMS_OUTPUT.PUT_LINE('Locations:      ' || v_location_count);
    DBMS_OUTPUT.PUT_LINE('Bookings:       ' || v_booking_count);
END;
/
