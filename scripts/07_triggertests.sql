-- ============================================================================
-- STAGEUP EVENT SETUP - TRIGGER TESTS (RESTRUCTURED SCHEMA)
-- ============================================================================
-- Tests for:
-- 1. CHECK_TEAM_CONSTRAINTS
-- 2. CHECK_BOOKING_CONSTRAINTS
-- 3. Booking ownership via OfficeRef (not Team REF)
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = C##STAGEUPDBA';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- TEST 1: Successful Team Creation with Region and Office References
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
    v_initial_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 1: Successful Team Creation with Regional Assignment ===');

    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(o) INTO v_office_ref FROM Office_TAB o WHERE OfficeType = 'Depot' ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    v_team_code := team_code_seq.NEXTVAL;

    INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code,
        'TestTeam_' || v_team_code,
        0,
        Member_VA(
            Member_t('AABBCC1111111111', 'John', 'Test', DATE '1990-05-15'),
            Member_t('DDEEGG2222222222', 'Jane', 'Test', DATE '1992-07-20')
        ),
        v_region_ref,
        v_office_ref
    );

    SELECT NoInstallations INTO v_initial_count FROM Team_TAB WHERE TeamCode = v_team_code;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK Team created with TeamCode: ' || v_team_code);
    DBMS_OUTPUT.PUT_LINE('OK NoInstallations initialized to: ' || v_initial_count);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERR TEST 1: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 2: Invalid Team Creation - Non-zero Initial Installations
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 2: Invalid Team Creation (Non-zero Installations) ===');

    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(o) INTO v_office_ref FROM Office_TAB o WHERE OfficeType = 'Depot' ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    v_team_code := team_code_seq.NEXTVAL;

    INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code,
        'FailTeam_' || v_team_code,
        5,
        Member_VA(Member_t('XXXX1111111111XX', 'Fail', 'Test', DATE '1995-03-10')),
        v_region_ref,
        v_office_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST 2: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 3: Successful Booking Insertion (Managed by Central Office)
-- ============================================================================
DECLARE
    v_booking_id NUMBER;
    v_office_ref REF Office_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 3: Successful Booking Insertion (Central Office) ===');

    SELECT REF(o) INTO v_office_ref FROM Office_TAB o WHERE Name = 'Central_Office_HQ';
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    v_booking_id := booking_id_seq.NEXTVAL;

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (v_booking_id, 'One-time', TRUNC(SYSDATE) + 5, 8, 500.00, 'Email', v_location_ref, v_office_ref);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK Booking inserted. BookingID: ' || v_booking_id);
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERR TEST 3: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 4: Invalid Booking - Zero Cost
-- ============================================================================
DECLARE
    v_booking_id NUMBER;
    v_office_ref REF Office_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 4: Invalid Booking (Zero Cost) ===');

    SELECT REF(o) INTO v_office_ref FROM Office_TAB o WHERE Name = 'Central_Office_HQ';
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    v_booking_id := booking_id_seq.NEXTVAL;

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (v_booking_id, 'One-time', TRUNC(SYSDATE), 4, 0, 'Phone', v_location_ref, v_office_ref);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST 4: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- VERIFICATION
-- ============================================================================
DECLARE
    v_region_count NUMBER;
    v_municipality_count NUMBER;
    v_office_count NUMBER;
    v_team_count NUMBER;
    v_booking_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_region_count FROM Region_TAB;
    SELECT COUNT(*) INTO v_municipality_count FROM Municipality_TAB;
    SELECT COUNT(*) INTO v_office_count FROM Office_TAB;
    SELECT COUNT(*) INTO v_team_count FROM Team_TAB;
    SELECT COUNT(*) INTO v_booking_count FROM Booking_TAB;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== SCHEMA VERIFICATION ===');
    DBMS_OUTPUT.PUT_LINE('Regions:        ' || v_region_count || ' (expected: 22)');
    DBMS_OUTPUT.PUT_LINE('Municipalities: ' || v_municipality_count || ' (expected: 220)');
    DBMS_OUTPUT.PUT_LINE('Offices:        ' || v_office_count || ' (expected: 23)');
    DBMS_OUTPUT.PUT_LINE('Teams:          ' || v_team_count || ' (expected: >= 110)');
    DBMS_OUTPUT.PUT_LINE('Bookings:       ' || v_booking_count || ' (expected: >= 100)');
END;
/
