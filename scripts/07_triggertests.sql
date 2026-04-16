-- ============================================================================
-- STAGEUP EVENT SETUP - TRIGGER TESTS
-- ============================================================================
-- Tests for:
-- 1) BR1 synchronization trigger (TrgSyncTeamOps)
--    - INSERT Booking: increment team operations
--    - UPDATE Booking.HandledBy: decrement old team and increment new team
--    - DELETE Booking: decrement team operations
-- 2) CHECK_TEAM_CONSTRAINTS
-- 3) Booking and location CHECK constraints + validation triggers
--
-- All identifiers are generated automatically (no manual code entry).
-- ============================================================================

SET SERVEROUTPUT ON;

BEGIN
    EXECUTE IMMEDIATE 'ALTER SESSION SET CURRENT_SCHEMA = C##STAGEUPDBA';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- ============================================================================
-- TEST A: CHECK_TEAM_CONSTRAINTS rejects non-zero initial operations
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST A: Team cannot start with non-zero operations ===');

    SELECT NVL(MAX(TeamCode), 0) + 1 INTO v_team_code FROM Team_TAB;
    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(o) INTO v_office_ref FROM Office_TAB o ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code,
        'FailTeam_' || v_team_code,
        5,
        Member_VA(Member_t('ZZZZZZ1111111111', 'Fail', 'Init', DATE '1990-01-01')),
        v_region_ref,
        v_office_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST A: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST B/C/D: BR1 synchronization on INSERT/UPDATE/DELETE Booking.HandledBy
-- ============================================================================
DECLARE
    v_team_code_1 NUMBER;
    v_team_code_2 NUMBER;
    v_booking_id NUMBER;
    v_region_ref REF Region_t;
    v_office_ref_1 REF Office_t;
    v_office_ref_2 REF Office_t;
    v_location_ref REF Location_t;
    v_ops_t1 NUMBER;
    v_ops_t2 NUMBER;
    v_assigned_team_code NUMBER;
    v_name_office_1 VARCHAR2(30);
    v_name_office_2 VARCHAR2(30);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST B/C/D: BR1 synchronization (INSERT/UPDATE/DELETE) ===');

    -- Automatic names to avoid manual entry/collisions.
    v_name_office_1 := 'TestDepotA_' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3');
    v_name_office_2 := 'TestDepotB_' || TO_CHAR(SYSTIMESTAMP, 'HH24MISSFF3');

    -- Pick one random region and one existing location for booking.
    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    -- Create two test depots.
    INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
    VALUES (
        v_name_office_1,
        Address_t('Via Test', '10', 70010, 'Bari', 'BA'),
        5,
        'Depot'
    );

    INSERT INTO Office_TAB (Name, Location, NoEmployees, OfficeType)
    VALUES (
        v_name_office_2,
        Address_t('Via Test', '20', 70010, 'Bari', 'BA'),
        6,
        'Depot'
    );

    SELECT REF(o) INTO v_office_ref_1 FROM Office_TAB o WHERE o.Name = v_name_office_1;
    SELECT REF(o) INTO v_office_ref_2 FROM Office_TAB o WHERE o.Name = v_name_office_2;

    -- Create one team per office with automatic TeamCode.
    SELECT NVL(MAX(TeamCode), 0) + 1 INTO v_team_code_1 FROM Team_TAB;
    SELECT v_team_code_1 + 1 INTO v_team_code_2 FROM dual;

    INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code_1,
        'TestTeamA_' || v_team_code_1,
        0,
        Member_VA(Member_t('AAAAAA1111111111', 'Alpha', 'Team', DATE '1991-01-01')),
        v_region_ref,
        v_office_ref_1
    );

    INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code_2,
        'TestTeamB_' || v_team_code_2,
        0,
        Member_VA(Member_t('BBBBBB2222222222', 'Beta', 'Team', DATE '1992-02-02')),
        v_region_ref,
        v_office_ref_2
    );

    COMMIT;

    -- TEST B: INSERT booking -> increment Team A.
    SELECT NVL(MAX(BookingID), 0) + 1 INTO v_booking_id FROM Booking_TAB;

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'One-time',
        TRUNC(SYSDATE) + 1,
        4,
        450,
        'Email',
        v_location_ref,
        v_office_ref_1
    );

    SELECT DEREF(b.AssignedTeam).TeamCode
      INTO v_assigned_team_code
      FROM Booking_TAB b
     WHERE b.BookingID = v_booking_id;

    SELECT N_Total_Installations INTO v_ops_t1 FROM Team_TAB WHERE TeamCode = v_team_code_1;
    DBMS_OUTPUT.PUT_LINE('TEST B - Team A ops after INSERT: ' || v_ops_t1 || ' (expected: 1)');
    DBMS_OUTPUT.PUT_LINE('TEST B - AssignedTeam after INSERT: ' || v_assigned_team_code || ' (expected: ' || v_team_code_1 || ')');

    -- TEST C: UPDATE booking HandledBy -> Team A decrement, Team B increment.
    UPDATE Booking_TAB
       SET HandledBy = v_office_ref_2
     WHERE BookingID = v_booking_id;

    SELECT N_Total_Installations INTO v_ops_t1 FROM Team_TAB WHERE TeamCode = v_team_code_1;
    SELECT N_Total_Installations INTO v_ops_t2 FROM Team_TAB WHERE TeamCode = v_team_code_2;
        SELECT DEREF(b.AssignedTeam).TeamCode
            INTO v_assigned_team_code
            FROM Booking_TAB b
         WHERE b.BookingID = v_booking_id;

    DBMS_OUTPUT.PUT_LINE('TEST C - Team A ops after UPDATE: ' || v_ops_t1 || ' (expected: 0)');
    DBMS_OUTPUT.PUT_LINE('TEST C - Team B ops after UPDATE: ' || v_ops_t2 || ' (expected: 1)');
        DBMS_OUTPUT.PUT_LINE('TEST C - AssignedTeam after UPDATE: ' || v_assigned_team_code || ' (expected: ' || v_team_code_2 || ')');

    -- TEST D: DELETE booking -> Team B decrement.
    DELETE FROM Booking_TAB WHERE BookingID = v_booking_id;

    SELECT N_Total_Installations INTO v_ops_t2 FROM Team_TAB WHERE TeamCode = v_team_code_2;
    DBMS_OUTPUT.PUT_LINE('TEST D - Team B ops after DELETE: ' || v_ops_t2 || ' (expected: 0)');

    -- Cleanup test teams/offices.
    DELETE FROM Team_TAB WHERE TeamCode IN (v_team_code_1, v_team_code_2);
    DELETE FROM Office_TAB WHERE Name IN (v_name_office_1, v_name_office_2);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('OK TEST B/C/D completed');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('ERR TEST B/C/D: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST E: Booking table CHECK rejects zero total cost
-- ============================================================================
DECLARE
    v_booking_id NUMBER;
    v_office_ref REF Office_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST E: Booking cost must be > 0 ===');

    SELECT NVL(MAX(BookingID), 0) + 1 INTO v_booking_id FROM Booking_TAB;
    SELECT t.OfficeRef INTO v_office_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (v_booking_id, 'One-time', TRUNC(SYSDATE), 2, 0, 'Phone', v_location_ref, v_office_ref);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST E: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST F: TrgTeamMemberDates rejects future birth dates
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST F: Team member birth date must be in the past ===');

    SELECT NVL(MAX(TeamCode), 0) + 1 INTO v_team_code FROM Team_TAB;
    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(o) INTO v_office_ref FROM Office_TAB o ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code,
        'FutureBirthTeam_' || v_team_code,
        0,
        Member_VA(Member_t('FUTURE1111111111', 'Future', 'Member', TRUNC(SYSDATE) + 1)),
        v_region_ref,
        v_office_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST F: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST G: Customer email CHECK rejects invalid email
-- ============================================================================
DECLARE
    v_customer_code VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST G: Customer email format must be valid ===');

    SELECT 'C' || LPAD(NVL(MAX(TO_NUMBER(SUBSTR(CustomerCode, 2))), 0) + 1, 3, '0')
      INTO v_customer_code
      FROM Customer_TAB
     WHERE REGEXP_LIKE(CustomerCode, '^C[0-9]+$');

    INSERT INTO Customer_TAB (CustomerCode, FirstName, LastName, Email, CustomerType, Address)
    VALUES (
        v_customer_code,
        'Invalid',
        'Email',
        'not-an-email',
        'Individual',
        Address_t('Via Test', '1', 70010, 'Bari', 'BA')
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST G: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST H: TrgBookingDates rejects booking dates in the past
-- ============================================================================
DECLARE
    v_booking_id NUMBER;
    v_office_ref REF Office_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST H: Booking date cannot be in the past ===');

    SELECT NVL(MAX(BookingID), 0) + 1 INTO v_booking_id FROM Booking_TAB;
    SELECT t.OfficeRef INTO v_office_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (v_booking_id, 'One-time', TRUNC(SYSDATE) - 1, 2, 100, 'Email', v_location_ref, v_office_ref);

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST H: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST I: Location table CHECK rejects zero setup time / capacity
-- ============================================================================
DECLARE
    v_location_code VARCHAR2(10);
    v_customer_ref REF Customer_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST I: Location setup time and capacity must be positive ===');

    SELECT 'L' || LPAD(NVL(MAX(TO_NUMBER(SUBSTR(LocationCode, 2))), 0) + 1, 4, '0')
      INTO v_location_code
      FROM Location_TAB
     WHERE REGEXP_LIKE(LocationCode, '^L[0-9]+$');

    SELECT REF(c) INTO v_customer_ref FROM Customer_TAB c ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Location_TAB (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
    VALUES (
        v_location_code,
        Address_t('Via Zero', '1', 70010, 'Bari', 'BA'),
        0,
        100,
        v_customer_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST I: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST J: TrgTeamMustHaveMembers rejects empty teams
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_region_ref REF Region_t;
    v_office_ref REF Office_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST J: Team must have at least one member ===');

    SELECT NVL(MAX(TeamCode), 0) + 1 INTO v_team_code FROM Team_TAB;
    SELECT REF(r) INTO v_region_ref FROM Region_TAB r ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(o) INTO v_office_ref FROM Office_TAB o ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    INSERT INTO Team_TAB (TeamCode, TeamName, N_Total_Installations, Members, RegionRef, OfficeRef)
    VALUES (
        v_team_code,
        'EmptyTeam_' || v_team_code,
        0,
        Member_VA(),
        v_region_ref,
        v_office_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST J: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST K: TrgCheckLocationCapacity rejects Promotional booking on low-capacity location
-- ============================================================================
DECLARE
    v_booking_id NUMBER;
    v_office_ref REF Office_t;
    v_customer_ref REF Customer_t;
    v_location_code VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST K: Promotional booking requires location capacity >= 100 ===');

    SELECT NVL(MAX(BookingID), 0) + 1 INTO v_booking_id FROM Booking_TAB;
    SELECT t.OfficeRef INTO v_office_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(c) INTO v_customer_ref FROM Customer_TAB c ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;

    SELECT 'LOC' || LPAD(NVL(MAX(TO_NUMBER(SUBSTR(LocationCode, 4))), 0) + 1, 7, '0')
      INTO v_location_code
      FROM Location_TAB
     WHERE REGEXP_LIKE(LocationCode, '^LOC[0-9]+$');

    INSERT INTO Location_TAB (LocationCode, Address, SetupTimeEstimate, EquipmentCapacity, OwnerRef)
    VALUES (
        v_location_code,
        Address_t('Via Promo Test', '1', 70010, 'Bari', 'BA'),
        60,
        50,
        v_customer_ref
    );

    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'Promotional',
        TRUNC(SYSDATE) + 1,
        2,
        100,
        'Email',
        (SELECT REF(l) FROM Location_TAB l WHERE l.LocationCode = v_location_code),
        v_office_ref
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('ERR TEST K: should have failed but did not');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('OK Expected error caught: ' || SQLERRM);
END;
/

-- ============================================================================
-- FINAL VERIFICATION SNAPSHOT
-- ============================================================================
DECLARE
    v_team_count NUMBER;
    v_booking_count NUMBER;
    v_booking_without_team NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_team_count FROM Team_TAB;
    SELECT COUNT(*) INTO v_booking_count FROM Booking_TAB;
    SELECT COUNT(*) INTO v_booking_without_team FROM Booking_TAB b WHERE b.AssignedTeam IS NULL;

    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== FINAL SNAPSHOT ===');
    DBMS_OUTPUT.PUT_LINE('Teams total:    ' || v_team_count);
    DBMS_OUTPUT.PUT_LINE('Bookings total: ' || v_booking_count);
    DBMS_OUTPUT.PUT_LINE('Bookings w/o Team: ' || v_booking_without_team);
END;
/
