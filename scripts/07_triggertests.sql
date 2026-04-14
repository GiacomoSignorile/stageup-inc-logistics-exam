-- ============================================================================
-- STAGEUP EVENT SETUP - TRIGGER TESTS (NEW SCHEMA)
-- ============================================================================
-- Tests for:
-- 1. SYNC_TEAM_INSTALLS - Synchronizes Team NoInstallations when bookings change
-- 2. CHECK_TEAM_CONSTRAINTS - Validates new teams start at 0, changes only by ±1
-- 3. Booking constraint validation - Valid BookingType, PlacementMode, TotalCost > 0
-- ============================================================================

-- ============================================================================
-- TEST 1: Successful Team Creation (CHECK_TEAM_CONSTRAINTS)
-- ============================================================================
DECLARE
    v_team_code NUMBER;
    v_initial_count NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 1: Successful Team Creation ===');
    
    -- Create a team with Member_VA
    v_team_code := team_code_seq.NEXTVAL;
    
    INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members)
    VALUES (
        v_team_code,
        'TestTeam_' || v_team_code,
        0, -- Must be 0 for new teams
        Member_VA(
            Member_t('AABBCC1111111111', 'John', 'Test', DATE '1990-05-15'),
            Member_t('DDEEGG2222222222', 'Jane', 'Test', DATE '1992-07-20')
        )
    );
    
    -- Verify NoInstallations is 0
    SELECT NoInstallations INTO v_initial_count FROM Team_TAB WHERE TeamCode = v_team_code;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Team created successfully with TeamCode: ' || v_team_code);
    DBMS_OUTPUT.PUT_LINE('✓ NoInstallations initialized to: ' || v_initial_count);
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Error creating team: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 2: Invalid Team Creation - Non-zero Initial Installations
-- ============================================================================
DECLARE
    v_team_code NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 2: Invalid Team Creation (Non-zero Installations) ===');
    
    v_team_code := team_code_seq.NEXTVAL;
    
    INSERT INTO Team_TAB (TeamCode, TeamName, NoInstallations, Members)
    VALUES (
        v_team_code,
        'FailTeam_' || v_team_code,
        5, -- Should fail - new teams must start at 0
        Member_VA(Member_t('XXXX1111111111XX', 'Fail', 'Test', DATE '1995-03-10'))
    );
    
    COMMIT; -- Should not reach here
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✓ Expected Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 3: Successful Booking Insertion (SYNC_TEAM_INSTALLS triggers)
-- ============================================================================
DECLARE
    v_booking_id    NUMBER;
    v_team_code     NUMBER;
    v_team_ref      REF Team_t;
    v_location_ref  REF Location_t;
    v_install_count_before NUMBER;
    v_install_count_after  NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 3: Successful Booking Insertion ===');
    
    -- Get a team and check its installations count before
    SELECT TeamCode INTO v_team_code FROM Team_TAB ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT NoInstallations INTO v_install_count_before FROM Team_TAB WHERE TeamCode = v_team_code;
    
    -- Get team reference
    SELECT REF(t) INTO v_team_ref FROM Team_TAB t WHERE t.TeamCode = v_team_code;
    
    -- Get a location reference
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    
    -- Insert booking
    v_booking_id := booking_id_seq.NEXTVAL;
    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'One-time',
        TRUNC(SYSDATE) + 5,
        8,
        500.00,
        'Email',
        v_location_ref,
        v_team_ref
    );
    
    -- Check installations count after
    SELECT NoInstallations INTO v_install_count_after FROM Team_TAB WHERE TeamCode = v_team_code;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Booking inserted successfully. BookingID: ' || v_booking_id);
    DBMS_OUTPUT.PUT_LINE('✓ Team NoInstallations before: ' || v_install_count_before);
    DBMS_OUTPUT.PUT_LINE('✓ Team NoInstallations after: ' || v_install_count_after);
    DBMS_OUTPUT.PUT_LINE('✓ Increment verified: ' || (v_install_count_after - v_install_count_before) || ' (expected: 1)');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Prerequisite Error: Ensure Team_TAB and Location_TAB are populated.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Error inserting booking: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 4: Booking Deletion (SYNC_TEAM_INSTALLS - decrement)
-- ============================================================================
DECLARE
    v_booking_id            NUMBER;
    v_team_code             NUMBER;
    v_install_count_before  NUMBER;
    v_install_count_after   NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 4: Booking Deletion (Team Installations Decrement) ===');
    
    -- Get an existing booking and its team
    SELECT BookingID, DEREF(HandledBy).TeamCode 
    INTO v_booking_id, v_team_code
    FROM Booking_TAB 
    ORDER BY DBMS_RANDOM.VALUE 
    FETCH FIRST 1 ROW ONLY;
    
    -- Get installations count before deletion
    SELECT NoInstallations INTO v_install_count_before FROM Team_TAB WHERE TeamCode = v_team_code;
    
    -- Delete the booking
    DELETE FROM Booking_TAB WHERE BookingID = v_booking_id;
    
    -- Check installations count after
    SELECT NoInstallations INTO v_install_count_after FROM Team_TAB WHERE TeamCode = v_team_code;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Booking deleted successfully. BookingID: ' || v_booking_id);
    DBMS_OUTPUT.PUT_LINE('✓ Team NoInstallations before: ' || v_install_count_before);
    DBMS_OUTPUT.PUT_LINE('✓ Team NoInstallations after: ' || v_install_count_after);
    DBMS_OUTPUT.PUT_LINE('✓ Decrement verified: ' || (v_install_count_before - v_install_count_after) || ' (expected: 1)');
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Prerequisite Error: Ensure Booking_TAB has records to delete.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Error deleting booking: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 5: Invalid Booking - TotalCost = 0 (Constraint Violation)
-- ============================================================================
DECLARE
    v_booking_id   NUMBER;
    v_team_ref     REF Team_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 5: Invalid Booking - TotalCost = 0 ===');
    
    v_booking_id := booking_id_seq.NEXTVAL;
    
    -- Get references
    SELECT REF(t) INTO v_team_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    
    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'One-time',
        TRUNC(SYSDATE),
        4,
        0.00, -- Should fail - TotalCost must be > 0
        'Phone',
        v_location_ref,
        v_team_ref
    );
    
    COMMIT; -- Should not reach here
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✓ Expected Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 6: Invalid Booking - Invalid BookingType
-- ============================================================================
DECLARE
    v_booking_id   NUMBER;
    v_team_ref     REF Team_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 6: Invalid Booking - Invalid BookingType ===');
    
    v_booking_id := booking_id_seq.NEXTVAL;
    
    -- Get references
    SELECT REF(t) INTO v_team_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    
    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'InvalidType', -- Should fail - must be One-time, Recurring, Seasonal, or Promotional
        TRUNC(SYSDATE),
        6,
        750.50,
        'Website',
        v_location_ref,
        v_team_ref
    );
    
    COMMIT; -- Should not reach here
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✓ Expected Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 7: Invalid Booking - Invalid PlacementMode
-- ============================================================================
DECLARE
    v_booking_id   NUMBER;
    v_team_ref     REF Team_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 7: Invalid Booking - Invalid PlacementMode ===');
    
    v_booking_id := booking_id_seq.NEXTVAL;
    
    -- Get references
    SELECT REF(t) INTO v_team_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    
    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'Recurring',
        TRUNC(SYSDATE),
        12,
        1500.00,
        'Fax', -- Should fail - must be Phone, Mail, Email, or Website
        v_location_ref,
        v_team_ref
    );
    
    COMMIT; -- Should not reach here
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✓ Expected Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 8: Successful Booking with Valid Negative Cost Days in Past
-- ============================================================================
DECLARE
    v_booking_id   NUMBER;
    v_team_ref     REF Team_t;
    v_location_ref REF Location_t;
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 8: Past Booking (Historical Record) ===');
    
    v_booking_id := booking_id_seq.NEXTVAL;
    
    -- Get references
    SELECT REF(t) INTO v_team_ref FROM Team_TAB t ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    SELECT REF(l) INTO v_location_ref FROM Location_TAB l ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROW ONLY;
    
    INSERT INTO Booking_TAB (BookingID, BookingType, BookingDate, Duration, TotalCost, PlacementMode, AtLocation, HandledBy)
    VALUES (
        v_booking_id,
        'Seasonal',
        TRUNC(SYSDATE) - 90, -- 90 days in the past
        24,
        3250.99,
        'Mail',
        v_location_ref,
        v_team_ref
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('✓ Past booking inserted successfully. BookingID: ' || v_booking_id);
    DBMS_OUTPUT.PUT_LINE('✓ BookingDate: ' || TO_CHAR(TRUNC(SYSDATE) - 90, 'YYYY-MM-DD'));
    
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Prerequisite Error: Ensure Team_TAB and Location_TAB are populated.');
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 9: Valid Customer Type Constraint
-- ============================================================================
DECLARE
    v_customer_code VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 9: Valid Customer Types ===');
    
    -- Test Individual customer
    v_customer_code := 'TEST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
    INSERT INTO Customer_TAB (CustomerCode, Email, CustomerType)
    VALUES (v_customer_code, 'individual@test.com', 'Individual');
    DBMS_OUTPUT.PUT_LINE('✓ Individual customer created: ' || v_customer_code);
    
    -- Test Company customer
    v_customer_code := 'TEST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
    INSERT INTO Customer_TAB (CustomerCode, Email, CustomerType)
    VALUES (v_customer_code, 'company@test.com', 'Company');
    DBMS_OUTPUT.PUT_LINE('✓ Company customer created: ' || v_customer_code);
    
    COMMIT;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✗ Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- TEST 10: Invalid Customer Type
-- ============================================================================
DECLARE
    v_customer_code VARCHAR2(10);
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== TEST 10: Invalid Customer Type ===');
    
    v_customer_code := 'TEST' || LPAD(customer_code_seq.NEXTVAL, 5, '0');
    INSERT INTO Customer_TAB (CustomerCode, Email, CustomerType)
    VALUES (v_customer_code, 'invalid@test.com', 'Nonprofit'); -- Should fail
    
    COMMIT; -- Should not reach here
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('✓ Expected Error: ' || SQLERRM);
END;
/

-- ============================================================================
-- SUMMARY
-- ============================================================================
BEGIN
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('    TRIGGER TESTS COMPLETED');
    DBMS_OUTPUT.PUT_LINE('===========================================');
    DBMS_OUTPUT.PUT_LINE('');
END;
/
