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
-- - 80 Locations
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
BEGIN
    DBMS_SESSION.SET_IDENTIFIER('BOOTSTRAP_POPULATION');
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
    v_regions(21) := 'San Marino';
    v_regions(22) := 'Citta del Vaticano';

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

    v_muni_names(1) := 'Nord';
    v_muni_names(2) := 'Sud';
    v_muni_names(3) := 'Est';
    v_muni_names(4) := 'Ovest';
    v_muni_names(5) := 'Centro';
    v_muni_names(6) := 'Alto';
    v_muni_names(7) := 'Basso';
    v_muni_names(8) := 'Interno';
    v_muni_names(9) := 'Esterno';
    v_muni_names(10) := 'Marittimo';

    FOR r IN (SELECT RegionCode, RegionName FROM Region_TAB ORDER BY RegionCode) LOOP
        SELECT REF(rg) INTO v_region_ref
        FROM Region_TAB rg
        WHERE rg.RegionCode = r.RegionCode;

        FOR m IN 1..10 LOOP
            INSERT INTO Municipality_TAB (MunicipalityCode, MunicipalityName, RegionRef)
            VALUES (
                municipality_code_seq.NEXTVAL,
                SUBSTR(v_muni_names(m) || ' ' || r.RegionName, 1, 30),
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
    v_capital_zip DBMS_SQL.varchar2_table;
    v_capital_street DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Office_TAB ---');

    v_capital_city(1) := 'L''Aquila';
    v_capital_city(2) := 'Potenza';
    v_capital_city(3) := 'Catanzaro';
    v_capital_city(4) := 'Napoli';
    v_capital_city(5) := 'Bologna';
    v_capital_city(6) := 'Trieste';
    v_capital_city(7) := 'Roma';
    v_capital_city(8) := 'Genova';
    v_capital_city(9) := 'Milano';
    v_capital_city(10) := 'Ancona';
    v_capital_city(11) := 'Campobasso';
    v_capital_city(12) := 'Torino';
    v_capital_city(13) := 'Bari';
    v_capital_city(14) := 'Cagliari';
    v_capital_city(15) := 'Palermo';
    v_capital_city(16) := 'Firenze';
    v_capital_city(17) := 'Trento';
    v_capital_city(18) := 'Perugia';
    v_capital_city(19) := 'Aosta';
    v_capital_city(20) := 'Venezia';
    v_capital_city(21) := 'San Marino';
    v_capital_city(22) := 'Citta del Vaticano';

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
    v_capital_province(21) := 'SM';
    v_capital_province(22) := 'VA';

    -- ZIP is NUMBER(5) in Address_t; CAPs with leading zero are stored without the initial zero.
    v_capital_zip(1) := '67100';
    v_capital_zip(2) := '85100';
    v_capital_zip(3) := '88100';
    v_capital_zip(4) := '80133';
    v_capital_zip(5) := '40121';
    v_capital_zip(6) := '34121';
    v_capital_zip(7) := '184';
    v_capital_zip(8) := '16121';
    v_capital_zip(9) := '20121';
    v_capital_zip(10) := '60121';
    v_capital_zip(11) := '86100';
    v_capital_zip(12) := '10121';
    v_capital_zip(13) := '70121';
    v_capital_zip(14) := '9124';
    v_capital_zip(15) := '90133';
    v_capital_zip(16) := '50122';
    v_capital_zip(17) := '38122';
    v_capital_zip(18) := '6121';
    v_capital_zip(19) := '11100';
    v_capital_zip(20) := '30121';
    v_capital_zip(21) := '47890';
    v_capital_zip(22) := '120';

    v_capital_street(1) := 'Via XX Settembre';
    v_capital_street(2) := 'Via Pretoria';
    v_capital_street(3) := 'Corso Mazzini';
    v_capital_street(4) := 'Via Toledo';
    v_capital_street(5) := 'Via Indipendenza';
    v_capital_street(6) := 'Via Carducci';
    v_capital_street(7) := 'Via del Corso';
    v_capital_street(8) := 'Via Garibaldi';
    v_capital_street(9) := 'Corso Venezia';
    v_capital_street(10) := 'Corso Stamira';
    v_capital_street(11) := 'Corso Vittorio Emanuele';
    v_capital_street(12) := 'Via Roma';
    v_capital_street(13) := 'Corso Cavour';
    v_capital_street(14) := 'Via Roma';
    v_capital_street(15) := 'Via Maqueda';
    v_capital_street(16) := 'Via Calzaiuoli';
    v_capital_street(17) := 'Via Belenzani';
    v_capital_street(18) := 'Corso Vannucci';
    v_capital_street(19) := 'Via Porta Pretoria';
    v_capital_street(20) := 'Riva del Carbon';
    v_capital_street(21) := 'Via Piana';
    v_capital_street(22) := 'Via della Conciliazione';

    v_address := Address_t('Via Don Luigi Sturzo', '7', 70029, 'Santeramo in Colle', 'BA');
    INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
    VALUES ('Central_Office_HQ', v_address, 50, 'Central');

    FOR r IN (SELECT RegionCode, RegionName FROM Region_TAB ORDER BY RegionCode) LOOP
        v_address := Address_t(
            v_capital_street(v_idx),
            LPAD(v_idx, 3, '0'),
            TO_NUMBER(v_capital_zip(v_idx)),
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

    v_first_names(1) := 'Alessandro'; v_first_names(2) := 'Beatrice'; v_first_names(3) := 'Carlo';
    v_first_names(4) := 'Daniela'; v_first_names(5) := 'Emanuele'; v_first_names(6) := 'Francesca';
    v_first_names(7) := 'Giorgio'; v_first_names(8) := 'Ilaria'; v_first_names(9) := 'Luca';
    v_first_names(10) := 'Martina';

    v_last_names(1) := 'Rossi'; v_last_names(2) := 'Bianchi'; v_last_names(3) := 'Russo';
    v_last_names(4) := 'Ferrari'; v_last_names(5) := 'Esposito'; v_last_names(6) := 'Romano';
    v_last_names(7) := 'Colombo'; v_last_names(8) := 'Ricci'; v_last_names(9) := 'Marino';
    v_last_names(10) := 'Greco';

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

            INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
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
    DBMS_OUTPUT.PUT_LINE('--- Populating historical N_Total_Installations in Team_TAB ---');

    FOR t IN (SELECT TeamCode FROM Team_TAB ORDER BY TeamCode) LOOP
        -- Seed realistic prior installations (0..15).
        v_target_installs := TRUNC(DBMS_RANDOM.VALUE(0, 16));

        FOR i IN 1..v_target_installs LOOP
            -- Keep +1 increments to satisfy CHECK_TEAM_CONSTRAINTS trigger.
            UPDATE Team_TAB
            SET N_Total_Installations = N_Total_Installations + 1
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

    v_first_names(1) := 'Marco'; v_first_names(2) := 'Giulia'; v_first_names(3) := 'Francesco';
    v_first_names(4) := 'Sara'; v_first_names(5) := 'Andrea'; v_first_names(6) := 'Chiara';
    v_first_names(7) := 'Matteo'; v_first_names(8) := 'Elena'; v_first_names(9) := 'Davide';
    v_first_names(10) := 'Federica';

    v_last_names(1) := 'Rossi'; v_last_names(2) := 'Bianchi'; v_last_names(3) := 'Russo';
    v_last_names(4) := 'Ferrari'; v_last_names(5) := 'Esposito'; v_last_names(6) := 'Romano';
    v_last_names(7) := 'Gallo'; v_last_names(8) := 'Costa'; v_last_names(9) := 'Fontana';
    v_last_names(10) := 'Conti';

    v_domains(1) := 'gmail.com'; v_domains(2) := 'libero.it'; v_domains(3) := 'outlook.com';
    v_domains(4) := 'azienda.it'; v_domains(5) := 'email.it'; v_domains(6) := 'eventi.it';

    FOR i IN 1..80 LOOP
        v_customer_code := 'CUST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
        v_customer_type := CASE WHEN MOD(i, 5) = 0 THEN 'Individual' ELSE 'Company' END;

        INSERT INTO Customer_TAB (CustomerCode, FirstName, LastName, Email, CustomerType)
        VALUES (
            v_customer_code,
            v_first_names(MOD(i, 10) + 1),
            v_last_names(MOD(i + 5, 10) + 1),
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
-- PHASE 7: LOCATIONS (80)
-- ---------------------------------------------------------------------------
DECLARE
    v_location_code VARCHAR2(10);
    v_address Address_t;
    v_customer_ref REF Customer_t;
    v_setup_time NUMBER;
    v_equipment_cap NUMBER;
    v_cities DBMS_SQL.varchar2_table;
    v_streets DBMS_SQL.varchar2_table;
    v_zipcodes DBMS_SQL.varchar2_table;
    v_provinces DBMS_SQL.varchar2_table;
    v_city_idx NUMBER;
    v_idx NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Location_TAB ---');

    v_cities(1) := 'Roma'; v_cities(2) := 'Milano'; v_cities(3) := 'Napoli';
    v_cities(4) := 'Torino'; v_cities(5) := 'Palermo'; v_cities(6) := 'Genova';
    v_cities(7) := 'Bologna'; v_cities(8) := 'Firenze'; v_cities(9) := 'Venezia';
    v_cities(10) := 'Verona';

    v_streets(1) := 'Via del Corso';
    v_streets(2) := 'Corso Buenos Aires';
    v_streets(3) := 'Via Toledo';
    v_streets(4) := 'Via Po';
    v_streets(5) := 'Via Roma';
    v_streets(6) := 'Via XX Settembre';
    v_streets(7) := 'Via Indipendenza';
    v_streets(8) := 'Via dei Calzaiuoli';
    v_streets(9) := 'Riva degli Schiavoni';
    v_streets(10) := 'Via Mazzini';

    -- ZIP is NUMBER(5) in Address_t; CAPs with leading zero are stored without the initial zero.
    v_zipcodes(1) := '184';
    v_zipcodes(2) := '20121';
    v_zipcodes(3) := '80133';
    v_zipcodes(4) := '10121';
    v_zipcodes(5) := '90133';
    v_zipcodes(6) := '16121';
    v_zipcodes(7) := '40121';
    v_zipcodes(8) := '50122';
    v_zipcodes(9) := '30121';
    v_zipcodes(10) := '37121';

    v_provinces(1) := 'RM';
    v_provinces(2) := 'MI';
    v_provinces(3) := 'NA';
    v_provinces(4) := 'TO';
    v_provinces(5) := 'PA';
    v_provinces(6) := 'GE';
    v_provinces(7) := 'BO';
    v_provinces(8) := 'FI';
    v_provinces(9) := 'VE';
    v_provinces(10) := 'VR';

    -- Assign one location to each customer to guarantee full coverage.
    FOR cust IN (
        SELECT REF(c) AS customer_ref
        FROM Customer_TAB c
        ORDER BY c.CustomerCode
    ) LOOP
        v_idx := v_idx + 1;
        v_location_code := 'LOC' || LPAD(location_code_seq.NEXTVAL, 7, '0');

        v_city_idx := MOD(v_idx, 10) + 1;
        v_address := Address_t(
            v_streets(v_city_idx),
            TO_CHAR(MOD(v_idx * 25, 999) + 1),
            TO_NUMBER(v_zipcodes(v_city_idx)),
            v_cities(v_city_idx),
            v_provinces(v_city_idx)
        );

        v_customer_ref := cust.customer_ref;

        v_setup_time := TRUNC(DBMS_RANDOM.VALUE(30, 481));
        v_equipment_cap := TRUNC(DBMS_RANDOM.VALUE(10, 1001));

        INSERT INTO Location_TAB (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
        VALUES (v_location_code, v_address, v_setup_time, v_equipment_cap, v_customer_ref);
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 80 locations into Location_TAB.');
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
    v_location_capacity NUMBER;
    v_handling_office_ref REF Office_t;
    v_booking_date DATE;
    v_booking_type VARCHAR2(20);
    v_placement_mode VARCHAR2(15);
    v_duration NUMBER;
    v_total_cost NUMBER(10, 2);
    v_booking_types DBMS_SQL.varchar2_table;
    v_placement_modes DBMS_SQL.varchar2_table;
BEGIN
    DBMS_OUTPUT.PUT_LINE('--- Populating Booking_TAB ---');

    v_booking_types(1) := 'One-time';
    v_booking_types(2) := 'Recurring';
    v_booking_types(3) := 'Seasonal';
    v_booking_types(4) := 'Promotional';

    v_placement_modes(1) := 'Phone';
    v_placement_modes(2) := 'Mail';
    v_placement_modes(3) := 'Email';
    v_placement_modes(4) := 'Website';

    FOR i IN 1..100 LOOP
        SELECT REF(l), l.EquipmentCapacity
        INTO v_location_ref, v_location_capacity
        FROM Location_TAB l
        ORDER BY DBMS_RANDOM.VALUE
        FETCH FIRST 1 ROW ONLY;

        SELECT t.OfficeRef
        INTO v_handling_office_ref
        FROM Team_TAB t
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

        -- Keep population trigger-safe: Promotional bookings require capacity >= 100.
        IF v_booking_type = 'Promotional' AND v_location_capacity < 100 THEN
            v_booking_type := 'One-time';
        END IF;

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
            v_handling_office_ref
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Successfully populated 100 bookings into Booking_TAB.');
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error populating Booking_TAB: missing teams, offices, or locations.');
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
    v_booking_without_team NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_region_count FROM Region_TAB;
    SELECT COUNT(*) INTO v_municipality_count FROM Municipality_TAB;
    SELECT COUNT(*) INTO v_office_count FROM Office_TAB;
    SELECT COUNT(*) INTO v_team_count FROM Team_TAB;
    SELECT COUNT(*) INTO v_equipment_count FROM Equipment_TAB;
    SELECT COUNT(*) INTO v_customer_count FROM Customer_TAB;
    SELECT COUNT(*) INTO v_location_count FROM Location_TAB;
    SELECT COUNT(*) INTO v_booking_count FROM Booking_TAB;
    SELECT COUNT(*) INTO v_booking_without_team FROM Booking_TAB b WHERE b.AssignedTeam IS NULL;

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
    DBMS_OUTPUT.PUT_LINE('Bookings w/o Team: ' || v_booking_without_team);
END;
/
BEGIN
    DBMS_SESSION.CLEAR_IDENTIFIER;
END;
/
