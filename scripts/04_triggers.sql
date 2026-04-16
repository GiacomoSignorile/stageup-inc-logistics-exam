-- ============================================================================
-- STAGEUP EVENT SETUP - TRIGGERS
-- ============================================================================
-- Business rules covered:
-- BR1: Team operation count must be updated when a booking is taken over.
-- BR2: A new team must start with 0 operations and updates must be incremental.
-- BR3: Booking data consistency checks (table checks + date validation trigger).
--
-- Note on schema adaptation:
-- Booking_TAB stores HandledBy as REF Office_t (not REF Team_t).
-- To keep BR1 enforceable, the trigger resolves one responsible team in that office,
-- choosing the least-loaded team (then lowest TeamCode for deterministic tie-break).
-- ============================================================================

-- ============================================================================
-- STORED PROCEDURES FOR OPERATION COUNTS (BR1)
-- ============================================================================

-- Cleanup obsolete trigger names so reruns do not keep duplicated logic.
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER SYNC_TEAM_OPS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER CHECK_BOOKING_CONSTRAINTS'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TrgCustomerEmailFormat'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TrgLocationRules'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER TrgCheckLocationCapacity'; EXCEPTION WHEN OTHERS THEN IF SQLCODE != -4080 THEN RAISE; END IF; END;
/

CREATE OR REPLACE PROCEDURE IncrementOperationsCount (incomingTeamCode IN NUMBER)
IS
BEGIN
    UPDATE Team_TAB
       SET N_Total_Installations = N_Total_Installations + 1
     WHERE TeamCode = incomingTeamCode;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20997, 'Team not found for increment: ' || incomingTeamCode);
    END IF;
END IncrementOperationsCount;
/

CREATE OR REPLACE PROCEDURE DecrementOperationsCount (incomingTeamCode IN NUMBER)
IS
BEGIN
    UPDATE Team_TAB
       SET N_Total_Installations = GREATEST(N_Total_Installations - 1, 0)
     WHERE TeamCode = incomingTeamCode;

    IF SQL%ROWCOUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20996, 'Team not found for decrement: ' || incomingTeamCode);
    END IF;
END DecrementOperationsCount;
/

-- Resolve the team that takes over a booking for a given office.
CREATE OR REPLACE PROCEDURE ResolveOfficeTeamCode (
    incomingOfficeRef IN REF Office_t,
    outTeamCode OUT NUMBER
)
IS
BEGIN
    SELECT TeamCode
      INTO outTeamCode
      FROM (
          SELECT t.TeamCode
            FROM Team_TAB t
           WHERE t.OfficeRef = incomingOfficeRef
           ORDER BY t.N_Total_Installations ASC, t.TeamCode ASC
      )
     WHERE ROWNUM = 1;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        outTeamCode := NULL;
END ResolveOfficeTeamCode;
/

-- Assign a concrete team to a booking while keeping Office as booking manager.
CREATE OR REPLACE TRIGGER ASSIGN_TEAM_TO_BOOKING
BEFORE INSERT OR UPDATE OF HandledBy ON Booking_TAB
FOR EACH ROW
DECLARE
    v_team_code NUMBER;
BEGIN
    ResolveOfficeTeamCode(:NEW.HandledBy, v_team_code);

    IF v_team_code IS NULL THEN
        RAISE_APPLICATION_ERROR(-20989, 'No team available for the selected office');
    END IF;

    SELECT REF(t)
      INTO :NEW.AssignedTeam
      FROM Team_TAB t
     WHERE t.TeamCode = v_team_code;
END ASSIGN_TEAM_TO_BOOKING;
/

-- ============================================================================
-- TRIGGER FOR SYNCHRONIZATION (BR1)
-- ============================================================================

CREATE OR REPLACE TRIGGER TrgSyncTeamOps
AFTER INSERT OR DELETE OR UPDATE OF HandledBy ON Booking_TAB
FOR EACH ROW
DECLARE
    v_new_team_code NUMBER;
    v_old_team_code NUMBER;
BEGIN
    -- INSERT: increment the assigned team operations.
    IF INSERTING THEN
        SELECT t.TeamCode
          INTO v_new_team_code
          FROM Team_TAB t
         WHERE REF(t) = :NEW.AssignedTeam;

        IF v_new_team_code IS NOT NULL THEN
            IncrementOperationsCount(v_new_team_code);
        END IF;
    END IF;

    -- DELETE: decrement operations for the team previously assigned to booking.
    IF DELETING THEN
        SELECT t.TeamCode
          INTO v_old_team_code
          FROM Team_TAB t
         WHERE REF(t) = :OLD.AssignedTeam;

        IF v_old_team_code IS NOT NULL THEN
            DecrementOperationsCount(v_old_team_code);
        END IF;
    END IF;

    -- UPDATE of HandledBy: decrement previous assigned team, increment the new one.
    IF UPDATING THEN
        SELECT t.TeamCode
          INTO v_old_team_code
          FROM Team_TAB t
         WHERE REF(t) = :OLD.AssignedTeam;

        SELECT t.TeamCode
          INTO v_new_team_code
          FROM Team_TAB t
         WHERE REF(t) = :NEW.AssignedTeam;

        IF v_old_team_code IS NOT NULL THEN
            DecrementOperationsCount(v_old_team_code);
        END IF;

        IF v_new_team_code IS NOT NULL THEN
            IncrementOperationsCount(v_new_team_code);
        END IF;
    END IF;
END TrgSyncTeamOps;
/

-- ============================================================================
-- VALIDATION TRIGGERS
-- ============================================================================

CREATE OR REPLACE TRIGGER CHECK_TEAM_CONSTRAINTS
BEFORE INSERT OR UPDATE ON Team_TAB
FOR EACH ROW
BEGIN
    -- New teams always start at 0 operations.
    IF INSERTING THEN
        IF :NEW.N_Total_Installations IS NOT NULL AND :NEW.N_Total_Installations > 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'A new team must start with 0 operations');
        END IF;
        :NEW.N_Total_Installations := 0;
    END IF;

    -- Updates must be at most +/- 1 to preserve consistent synchronization semantics.
    IF UPDATING THEN
        IF ABS(:NEW.N_Total_Installations - :OLD.N_Total_Installations) > 1 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Team operations can only be changed by one unit at a time');
        END IF;

        IF :NEW.N_Total_Installations < 0 THEN
            RAISE_APPLICATION_ERROR(-20999, 'Team operations cannot be negative');
        END IF;
    END IF;
END;
/

-- ============================================================================
-- ADDITIONAL ADAPTABLE TRIGGERS FOR THE PROJECT TRACE
-- ============================================================================

-- TrgTeamMemberDates
-- Members inside a team must have a birth date in the past.
CREATE OR REPLACE TRIGGER TrgTeamMemberDates
BEFORE INSERT OR UPDATE OF Members ON Team_TAB
FOR EACH ROW
DECLARE
    v_index PLS_INTEGER;
BEGIN
    IF :NEW.Members IS NOT NULL THEN
        v_index := :NEW.Members.FIRST;
        WHILE v_index IS NOT NULL LOOP
            IF :NEW.Members(v_index).BirthDate IS NULL THEN
                RAISE_APPLICATION_ERROR(-20990, 'Team member birth date cannot be NULL');
            END IF;

            IF :NEW.Members(v_index).BirthDate > TRUNC(SYSDATE) THEN
                RAISE_APPLICATION_ERROR(-20990, 'Team member birth date cannot be in the future');
            END IF;

            v_index := :NEW.Members.NEXT(v_index);
        END LOOP;
    END IF;
END;
/

-- TrgBookingDates
-- Booking date cannot be in the past.
CREATE OR REPLACE TRIGGER TrgBookingDates
BEFORE INSERT OR UPDATE OF BookingDate ON Booking_TAB
FOR EACH ROW
BEGIN
    -- During initial bootstrap population we allow historical data snapshots.
    IF SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER') = 'BOOTSTRAP_POPULATION' THEN
        RETURN;
    END IF;

    IF :NEW.BookingDate < TRUNC(SYSDATE) THEN
        RAISE_APPLICATION_ERROR(-20992, 'Booking date cannot be in the past');
    END IF;
END;
/

-- TrgCheckLocationCapacity
-- Checks if the selected event location has enough capacity for Promotional bookings.
CREATE OR REPLACE TRIGGER TrgCheckLocationCapacity
BEFORE INSERT OR UPDATE OF AtLocation, BookingType ON Booking_TAB
FOR EACH ROW
DECLARE
    v_loc_capacity NUMBER;
BEGIN
    SELECT l.EquipmentCapacity
      INTO v_loc_capacity
      FROM Location_TAB l
     WHERE REF(l) = :NEW.AtLocation;

    IF :NEW.BookingType = 'Promotional' AND v_loc_capacity < 100 THEN
        RAISE_APPLICATION_ERROR(-20985, 'Venue capacity is too low for a Promotional setup.');
    END IF;
END;
/

-- TrgTeamMustHaveMembers
-- Teams must be created with at least one member.
CREATE OR REPLACE TRIGGER TrgTeamMustHaveMembers
BEFORE INSERT OR UPDATE OF Members ON Team_TAB
FOR EACH ROW
BEGIN
    IF :NEW.Members IS NULL OR :NEW.Members.COUNT = 0 THEN
        RAISE_APPLICATION_ERROR(-20995, 'A team must contain at least one member');
    END IF;
END;
/
